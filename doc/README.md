## SDRAM Controller

### 串口设计

UART设计时序

![img](https://gitee.com/niu-yunding/niu_sb/raw/master/img/202301082028696.png)

| 信号名      | 方向     | 描述                                                         |
| ----------- | -------- | ------------------------------------------------------------ |
| rx          | input    | PC端的串口发送端（FPGA的串口接受端），串口空闲时处于高电平。发送数据时，rx拉低作为起始位，然后依次发送8bit的数据（低位优先），发完最后1bit之后rx保持高电平（和标准设计相比无校验位） |
| rx_r1/r2/r3 | internal | 由于跨时钟域要对rx进行打拍处理（打2拍，2级同步），rx_r3是rx的三级寄存器 |
| rx_flag     | internal | 串口处于接受状态的标志信号，拉高条件为rx从空闲状态发送起始位的**下降沿**，拉低条件是接受完一帧串口数据（8bit） |
| baud_cnt    | internal | 波特率计数器，FPGA使用的时钟为50MHz，所以串口发送1bit数据占用周期数为(1/9600)\*10^9 / 20 = 5208。其中，9600为串口工具的码率，10^9为s转换ns，20为设置的时间精度 |
| bit_flag    | internal | 检测rx上串口数据的标志信号，只有当baud_cn计数到2603时才会拉高（取中间值检测数据提高可靠性） |
| bit_cnt     | internal | 已经接受一帧串口数据的bit数，自增条件为bit_flag，计数到8之后自清零 |
| rx_data     | output   | 接受串口数据的寄存器，位宽为8（通过移位实现串转并的操作）    |
| po_flag     | output   | 传输完毕信号                                                 |

设计时序分析：`rx`低电平作为数据发送的起始，之后将`rx`打两拍进行跨时钟域的操作，并且将`rx_r2`打拍结果寄存下来。之后使用`~rx_r2&rx_r3`捕获时钟的下降沿作为`rx_flag`拉高的条件。`rx_flag`拉高之后`baud_cnt`开始自增，比特开始传输。`bit_flag`在`baud_cnt`计数器到最大值一半时拉高，获得稳定的控制信号。`bit_flag`拉高，`bit_cnt`计数器自增直到一帧数据传输结束。传输结束后，即`bit_cnt == 8`时，`po_flag`拉高，一次传输结束。

![QQ图片20230108202948](https://gitee.com/niu-yunding/niu_sb/raw/master/img/202301082030864.jpg)

| 信号名      | 方向     | 描述                                                         |
| ----------- | -------- | ------------------------------------------------------------ |
| tx_trig     | input    | 检测发送信号，仅当此信号拉高时tx_data传输的数据有效          |
| tx_data     | input    | 串口发送的数据                                               |
| tx_data_reg | internal | 缓存tx_data的寄存器,tx_trig拉高且tx_flag置低时进行缓存（     |
| tx_flag     | internal | 数据发送信号                                                 |
| baud_cnt    | internal | 波特率计数器，和接收模块相同                                 |
| bit_flag    | internal | 检测串口数据信号(波特率计满产生)                             |
| bit_cnt     | internal | 串口发送一帧的比特数，自增条件为bit_flag，计数到8之后自清零  |
| rx232_tx    | output   | 串口数据发送端，当tx_flag拉高且bit_cnt==0时作为起始位，低电平有效之后发送8bit数据 |

时序分析：`tx_trig`拉高时触发串口发送，此时的`tx_data`有效并缓存，下一拍`tx_flag`拉高。`baud_cnt`波特率计数器开始自增，在自增至5208时，代表1位数据准备完毕，`bit_flag`拉高，`bit_cnt`自增，直至`bit_cnt==8`代表当前帧传输完毕。此时`tx_flag`拉低，一次发送结束。`rx232_tx`仅当`tx_flag`拉高且`bit_cnt==0`时作为起始位低电平有效，之后根据`tx_data_r`缓存的值进行选择，发送8bit数据给接收模块。

### SDRAM理论

即同步动态随机存储器。同步指Memory工作需要同步时钟，内部的命令的发送和数据的传输都以它为基准；动态是指存储阵列需要不断地刷新来保证存储的数据不丢失，因为SDRAM存储通过电容工作，在自然放置在状态会放电，如果电放完了则存储的数据就丢失了，所以需要不断进行刷新；随机是指数据不是线性依次存储，而是自由指定地址进行数据读写。

SDRAM容量 = 数据位宽 \* 存储单元数量 （bank数 \* 行地址 \* 列地址） 

引脚说明（2M \* 4Bank \* 16）：

![image](https://user-images.githubusercontent.com/100147572/216016643-afd4e625-b876-4c55-91a4-e34e2a440650.png)

![image](https://user-images.githubusercontent.com/100147572/216016696-f8cd6e7c-42f0-4920-ad3f-62b890421450.png)

在进行操作之前，SDRAM必须进行初始化。初始化需要在电源和时钟都稳定之后进行，在100μs延迟中不可以执行任何命令（不包括INHIBIT和NOP），在200us内INHIBIT和NOP命令都有可能被执行。在至少一条INHIBIT或NOP被执行之后，在100μs内PRECHARGE命令将会被执行。所有的bank都必须被precharge，这会使所有的bank经过两次AUTO REFRESH后进入空闲状态，这时进入模式寄存器配置。寄存器模式需要加载任何可执行的命令否则它会充电到一个不可预知的状态。


### 初始化模块：

| CMD               | CS   | RAS  | CAS  | WE   |
| ----------------- | ---- | ---- | ---- | ---- |
| precharge         | 0    | 0    | 1    | 0    |
| autofresh         | 0    | 0    | 0    | 1    |
| NOP               | 0    | 1    | 1    | 1    |
| Mode register set | 0    | 0    | 0    | 0    |


| 地址线     | Value              | 说明                                            |
| ---------- | ------------------ | ----------------------------------------------- |
| A0-A11     | 12'b0000_0011_0010 |                                                 |
| A9         | 0                  | 支持突发读写                                    |
| A4、A5、A6 | 011                | 列地址选通脉冲，经过Value个时钟周期内存地址稳定 |
| A3         | 0                  | 突发类型：连续                                  |
| A0、A1、A2 | 100                | 设置突发长度：4                                 |

时序设计：200μs延迟后发送precharge命令，间隔tRP(20ns)发送autofresh命令，再间隔tRC(63ns)发送第二次autofresh命令，再间隔tRC(63ns)发送mode register命令。

### 仲裁机制和刷新模块

**4096 Refresh cycles / 64ms**：保证电容保存数据不丢失的时间间隔为64ms，12条地址线对应刷新周期为`2^12 = 4096`.

tRP:20ns 

tRC:63ns

仲裁机制：内存进行读、写、刷新进行控制（请求、使能、结束标志）

仲裁状态：sdram_top就相当于仲裁模块，对读写刷新操作进行控制

1.   IDEL
2.   ARBIT
3.   AREF
4.   WRITE
5.   READ

刷新时序：

![image](https://user-images.githubusercontent.com/100147572/216017262-1793f70a-251a-4a65-86d8-9b787da11506.png)

### 写模块

SDRAM状态机：

![image](https://user-images.githubusercontent.com/100147572/216017099-7115a698-354c-40a9-9a2b-56129437d0b6.png)

Write Command：

![image](https://user-images.githubusercontent.com/100147572/216018012-c8ba4395-533c-4ee8-a84e-d07167055fd1.png)

Write Without Precharge：

![image](https://user-images.githubusercontent.com/100147572/216018455-b8a59448-81bf-4ee9-8895-3876ba9b7e96.png)

Write With Precharge:

![image](https://user-images.githubusercontent.com/100147572/216018608-0429f0fe-479f-4c3b-a4f0-381d78501397.png)

SDRAM写时序图：

![image](https://user-images.githubusercontent.com/100147572/216017919-964efda5-82cd-4f1c-a64e-5abdafa48142.png)

SDRAM写内部时序：

| 信号         | 方向     | 描述                                                         |
| ------------ | -------- | ------------------------------------------------------------ |
| wr_trig      | Input    | 写触发信号                                                   |
| flag_wr      | Internal | 写信号，数据传输结束后拉低                                   |
| wr_req       | Output   | 写请求信号，REQ状态时传递给仲裁器请求写                      |
| wr_en        | Input    | 写使能信号，仲裁器仲裁写                                     |
| state        | Internal | 状态机，有IDEL、REQ、ACT、WR、PRE信号，状态转换：<br>1. IDEL收到写触发信号后转换为REQ状态发送写请求<br>2. REQ状态收到写使能信号后转换为ACT状态<br>3. ACT状态当flag_act_end拉高时转换为WR状态<br>4. WR状态如果数据全部写完则转换为PRE状态；如果写期间遇到了刷新信号，需要等到写完一个突发长度之后转换到PRE状态；如果写完了一行则转到PRE写下一行<br>5. PRE状态如果遇到刷新信号则转换到REQ状态重新发送请求等待写；如果flag_pre_end拉高则回到ACT状态；如果数据写完则回到IDEL等待 |
| flag_act_end | Internal | ACT阶段结束标志，维护act_cnt计数器到3时拉高                  |
| flag_pre_end | Internal | PRE阶段结束标志，维护break_cnt计数器到3时拉高                |
| flag_wr_end  | Output   | WR阶段结束标志，在PRE状态遇到刷新时或数据写完时拉高          |
| sd_row_end   | Internal | 一行写完标志，写完拉高                                       |
| ref_req      | Input    | 刷新信号                                                     |
| burst_cnt    | Internal | 突发数据计数器，计数到突发长度                               |
| wr_data_end  | Internal | 写数据完成标志，写完两行数据后拉高                           |

什么时候退出写状态？

1.   数据已经写完
2.   数据没写完但是遇到刷新请求
3.   数据写完当前行需要换行

写的时候刷新到来，是否需要先进入PRE状态再AREF？

是的，因为AREF来之前需要一个PRE后经过tRP时间才可以进行刷新。

**读模块和写模块状态机完全相同，不做解析**

### 命令解析模块

作用：

1.   读写命令控制
2.   提取待写入数据

时序设计：

![image](https://user-images.githubusercontent.com/100147572/216019674-eb1a37b2-98a5-4857-8736-df45dad9d301.png)

| 端口        | 方向     | 描述                                                         |
| ----------- | -------- | ------------------------------------------------------------ |
| uart_flag   | Input    | 来自串口的数据结束标志信号(uart模块的poflag)                 |
| uart_data   | Input    | 来自串口的数据(rx_data),以55起始，aa表示读命令               |
| rec_num     | Internal | 接收串口传入的字符数，读命令到来时不自增，配合cmd_reg接收命令 |
| cmd_reg     | Internal | 存储串口传入的命令（55/aa），rec_num为0时接收命令            |
| wr_trig     | Output   | 传给sdram控制器的触发信号                                    |
| rd_trig     | Output   | 传给sdram控制器的触发信号                                    |
| wfifo_wr_en | Output   | 写Fifo使能信号，写数据时与uart_flag保持对齐                  |

### 读写FIFO

作用：缓存待写入/已读出数据

为什么使用FIFO？

1.   写SDRAM串口发送4B数据时间太长，而SDRAM写入很快，需要FIFO缓存数据
2.   读SDRAM串口发送到上机位，速率大于串口，需要将读出的内容暂存

**FIFO读出的数据必须于写突发长度对齐**

添加读写FIFO：删除原来的触发信号，由`cmd_decode`产生。将串口发送端添加产生`rfifo_rd_en`和`rfifo_rd_data`信号，其他fifo信号在顶层与write和read之间传递。由串口发送数据之后在FIFO暂存之后发送给读写模块。

**Hint：**

RFIFO写数据时由于SDRAM有3个clk的潜伏期，所以需要在`sdram_read.v`对`rfifo_wr_en`打三拍，保证和数据的一致性。读数据时，要在串口拉起`rfifo_rd_en`仅一个周期，之后由组合逻辑产生`tx_trig`并打拍，保证`rs232_tx`时序严格按照串口数据发送时序。

## VGA/LCD

### VGA驱动

[NJU数电实验8-VGA](https://nju-projectn.github.io/dlco-lecture-note/exp/08.html)

VGA显示原理：

![../_images/vga02.png](https://nju-projectn.github.io/dlco-lecture-note/_images/vga02.png)

RGB端并不是所有时间都在传送像素信息，由于CRT的电子束从上一行的行尾到下一行的行头需要时间，从屏幕的右下角回到左上角开始下一帧也需要时间，这时RGB送的电压值为0（黑色），这些时间称为电子束的行消隐时间和场消隐时间，行消隐时间以像素为单位，帧消隐时间以行为单位。

VGA显示信号设计原理：

![image](https://user-images.githubusercontent.com/100147572/216019928-f3ab70e9-1f39-4e88-a742-846ad69e3a31.png)

| 端口      | 方向   | 描述                                                      |
| --------- | ------ | --------------------------------------------------------- |
| lcd_de    | Output | LCD向VGA兼容信号，采用行场同步模式(HV Mode)时必须为低电平 |
| vga_hsync | Output | 行同步信号                                                |
| vga_vsync | Output | 场同步信号                                                |
| vga_rgb   | Output | 颜色绘制数据                                              |
| data_req  | Output | 确定当前是否在显示区域内，判定是否需要图像数据            |
| img_data  | Input  | 图像数据                                                  |

对于采取HV Mode的LCD显示，只需要将`lcd_de`拉低即可使用VGA协议驱动，但是注意显示的参数(时间参数、分辨率、RGB位宽需求等)的不同。

### 对已有模块的修改

1.   地址线由12位改为13位
2.   修改信号控制满足800*480的图像输入
3.   修改时钟频率相关信号
     1.   SDRAM：100MHz
     2.   Uart串口：50MHz
     3.   VGA/LCD驱动：33.3MHz

4.   实现自动写操作
     1.   根据`rdusedw`进行工作，设置FIFO深度为512，当`rdusedw`大于256时拉高wr_trig。直接使用vivado生成IP core即可。
     2.   控制`sdram_write`一次写入256个数据
          1.   `burst_cnt`为4，控制写入时序	(√)
          2.   `burst_type`设置为页突发，一次恰好写入256个数据
     3.   修改`wr_data_end`的产生方式，当写满9条地址线或者写完整个Graph（`col_cnt == 256`时，写完48000000 pixel的最后一个data）
     4.   修改`col_cnt`和`row_addr`的清零方式，当写完整个Graph才清零。
     5.   使用vivado + modelsim联合编译，修改vivado->Tools->Simulator和Settings中仿真器和第三方仿真库的编译选项即可。（问题：修改文件后运行simulation.do不会实时修改，需要关掉Modelsim后重新跑）
     6.   效果：col地址线自增到512，row地址线自增1，直到row写满937且col为255时，一张800*600的Graph写完。这时所有计数器全部清零，下一张图依旧从row:0 col:0的地址开始写
5.   自动读操作
     1.   基本内容和自动写相同
     2.   新增`rfifo_rd_ready`信号传递给顶层模块，只有此信号拉高时才允许将数据送入VGA驱动，否则需要在FIFO中暂存读出数据。
6.   修改串口发送波特率为115200bps
7.   2字节的RGB565到3字节的RGB888的转换:	
     
     ```verilog
     assign rgb_888 = {{rgb_565[15:11], rgb_565[15:13]},
                      {rgb_565[10:5], rgb_565[10:9]},
                      {rgb_565[4:0], rgb_565[4:2]}};
     ```
8.   fix图像显示存在白条/噪点的问题：
     1.   现象：显示图像时**概率**在**不确定位置出现不确定大小的白色区域**。
     2.   原因：白条即显示为`24'h0`的部分，原因是SDRAM没有初始化完成，VGA驱动已经开始读数据，导致存在显示白条。这个BUG是难以复现完全相同显示的，运行时可能不会出现，也可能出现位置大小不一的白条。
     3.   解决方案：让SDRAM初始化的结束信号作为VGA驱动的复位信号，只有当SDRAM完全准备好后才允许VGA去获取数据。注意，这里未发现读写速度不平衡导致此现象，原因在我们使用自动读写FIFO保证了数据是批量写入和读出的，也就是说不存在单个像素点的读写速度差异。当然，如果大家在测试过程中发现了读写速度问题导致的显示BUG，请联系我。


