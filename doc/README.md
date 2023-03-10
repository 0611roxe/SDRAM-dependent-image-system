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

## OV5640 Cam

**主要特性**：

1.   active array size：2592 x 1944 即500W像素
2.   support for output formats：RAW RGB、RGB565/555/444...
3.   采用标准串行SCCB接口，与IIC接口相同
4.   支持自动调焦
5.   输入时钟频率：6~27MHz

引脚描述（部分），详见附录文档官方手册：

| Signal Name | Pin Type | Description            |
| ----------- | -------- | ---------------------- |
| PWDN        | input    | 高电平有效，power down |
| RESETB      | input    | 复位信号，低电平有效   |
| SIOC        | input    | SCCB输入时钟           |
| SIOD        | I/O      | SCCB数据               |
| VSYNC       | I/O      | DVP VSYNC输出          |
| HREF        | I/O      | DVP HREF输出           |
| XVCLK       | input    | 系统时钟               |
| PCLK        | I/O      | DVP PCLK输出           |
| D0-D7       | I/O      | DVP数据输出的0-7端口   |

**Block Diagram(系统块图)**：

![image-20230202173744972](https://user-images.githubusercontent.com/100147572/216306587-0763852e-dfac-499d-bc3a-f4ac026a695d.png)

### 上电时序：

![image-20230202173917425](https://user-images.githubusercontent.com/100147572/216306933-fbc43139-f3c6-4132-be47-2636b65a72f2.png)

我们控制tx为标准需求的时间+1ms来保证时序确定完成，同样采取计数器方法来控制时间。

### SCCB分析

Watch document for details.

主机设备信号描述（对从机来说信号方向相反，其余字段描述相同）：

| Signal name | Signal Type | Description                                                  |
| ----------- | ----------- | ------------------------------------------------------------ |
| SCCB_E      | Output      | 串行片选信号，总线空闲时为1，主机断言传输或者暂停模式时为0，当没有连接时默认为高电平。 |
| SIO_C       | Output      | IIC时钟，总线空闲时拉高。单bit传输时间被定义为tCYC，通常为10us。 |
| SIO_D       | I/O         | I/O数据                                                      |
| PWDN        | Output      | Power down输出                                               |

SIO_C的最小时间tCYC为10us，即最大频率为100K。

**3线写事务：**

![image-20230202181620807](https://user-images.githubusercontent.com/100147572/216306963-3fa90a11-f177-435d-87f7-66d85e7f1b7f.png)

数据传输开始：

![image-20230202181644854](https://user-images.githubusercontent.com/100147572/216306996-9af817de-a620-44b4-b941-24f1a5b972f1.png)

数据传输结束：

![image-20230202181656615](https://user-images.githubusercontent.com/100147572/216307006-248f6c43-5f2d-4826-8554-303c87de36eb.png)

**Phrase描述：** 9bit/phrase

ID Address：匹配从机地址，D1-D7+读写标志信号，可以识别128个从机，OV5640的Slave ID Address为0x78，数据传输方向为MSB->LSB。

![image-20230202181946378](https://user-images.githubusercontent.com/100147572/216308456-972f7c65-f702-47a5-b606-76de8a831c6b.png)

Sub-address：匹配指定从机上寄存器的地址

![image-20230202182154698](https://user-images.githubusercontent.com/100147572/216308445-e08a631b-3680-4ef2-97ad-6ef68600d74a.png)

IIC的写时序和SCCB相同，BYTE WRITE模式下的单字节写（一次只写入一个数据）图如下：

![image-20230202183212406](https://user-images.githubusercontent.com/100147572/216308408-94d206ac-357c-40a8-9eeb-68ad1fd94934.png)

对于OV5640，由于寄存器地址也有16bit，我们可以将上图改造为：

![image-20230202183318546](https://user-images.githubusercontent.com/100147572/216308386-468e2ddb-f7b9-4d08-9ee4-fa2d201a5f38.png)

从而得到OV5640的写时序。但是对于读时序而言，IIC和SCCB存在不同，IIC的读时序如图：

![image-20230202183452802](https://user-images.githubusercontent.com/100147572/216308372-ba94a031-3be7-4c3b-a609-d06976a81f98.png)

它需要两个START阶段，并且在数据传输结束后拉高ACK来表示NO ACK，之后再给到结束位。在第二次START阶段中的CONTROL BTYE部分最后1bit要置为1表示数据传输开始。但是对于OV5640而言，它并不支持我们对于这个时序图进行改造为下面的形式：

![image-20230202183814450](https://user-images.githubusercontent.com/100147572/216308350-22bf1184-648c-4201-8930-eb28ac5f9b72.png)

而是需要在第二个START之前插入一个STOP位，如：

![image-20230202183853138](https://user-images.githubusercontent.com/100147572/216308329-0f10490d-5348-4952-bc6b-b7331328b930.png)

即2Phrase Write + 2 Phrase Read。

### OV5640 IIC时序

以读取OV5640的`0x300a`寄存器为例，这个寄存器是一个只读的默认寄存器，其中的值为`0x56`。图片尺寸较大，建议下载之后再缩放，其中蓝线部分表示ACK。此时序图设计和上面的2Phrase Write + 2 Phrase Read设计完全相同，只需要注意`div_clk`是`icc_sclk`时钟频率的二倍。

![image-20230202184256580](https://user-images.githubusercontent.com/100147572/216308321-dcf711b2-6ea0-43d1-b47d-5fd78af14cd6.png)

写时序部分只需要在读时序基础上，实现下图时序部分，将方向信号`dir`置0时表示写模式。

![image-20230202183318546](https://user-images.githubusercontent.com/100147572/216308386-468e2ddb-f7b9-4d08-9ee4-fa2d201a5f38.png)

信号描述：

| Signal Name | Signal Type | Description                                                  |
| ----------- | ----------- | ------------------------------------------------------------ |
| iic_scl     | output      | 产生iic同步时钟                                              |
| iic_sda     | inout       | iic传输串行数据                                              |
| start       | input       | 单次数据传输开始标志信号                                     |
| wdata       | input       | 输入数据。注意按照协议的地址线排布，ID Address部分为'h78代表写数据，'h79代表读数据；Sub Address为'h300a表示OV5640的一个只读的默认寄存器；Data部分为'h56是只读寄存器的默认值 |
| riic_data   | output      | 读出的数据部分                                               |
| busy        | output      | 当前总线传输正忙信号，数据开始传输拉高，传输结束拉低         |
| wsda_r      | internal    | 缓存单次传输过程中的wdata                                    |
| cfg_cnt     | internal    | 配置计数器，每个计数器值对应将一个被缓存的数据传输给sda寄存器 |
| iic_sda_r   | internal    | sda寄存器，缓存sda数据                                       |
| flag_ack    | internal    | ack确认帧，每传递完一个Phrase时拉高，此信号拉高时将sda寄存器的值传递给iic_sda进行输入/输出 |
| delay_cnt   | internal    | 延时计数器                                                   |
| done        | internal    | 传输完成信号                                                 |
| dir         | internal    | 传输方向，0代表写事务，1代表读事务                           |

**注意：** 只有当`slc`为低电平时`sda`才能发生跳变，`slc`为高电平时，`sda`不应发生数据变化。因为在IIC协议中，`sda`和`slc`同时处于高电平代表数据传输的开始条件，所以要在`slc == 0`的时候发送数据，即`start`到来代表传输开始的下一个时钟周期`scl`被拉低，`cfg_cnt`开始计数。

**板级验证注意：**

1.   调试OV5640摄像头时必须先供时钟（XCLK）
2.   IIC时钟不能超过100K
3.   XVCLK时钟频率选取24M的典型值（RTFM）
4.   综合属性设置 SOFT->NO，否则读到的数据线为FF

### 摄像头配置

通过摄像头配置使用设计好的IIC模块对寄存器组进行统一配置，配置每一个寄存器只需要给出一个`start`信号并给出`wdata`值（包括了读写操作、地址线、数据）。

时序设计：

![image-20230204170051215](https://user-images.githubusercontent.com/100147572/216761059-d411d923-1ee8-4464-a922-4f503006becc.png)

| Signal Name | Siganal Type | Description                                                  |
| ----------- | ------------ | ------------------------------------------------------------ |
| iic_scl     | output       | IIC模块输出时钟                                              |
| iic_sda     | inout        | IIC模块数据                                                  |
| estart      | input        | 调试开始信号                                                 |
| ewdata      | input        | 调试数据                                                     |
| riic_data   | output       | IIC模块读数据                                                |
| start       | internal     | 单个寄存器配置开始信号，从第二个寄存器开始使用busy的下降沿产生 |
| cfg_idx     | internal     | 寄存器配置编号                                               |
| busy_n      | internal     | IIC模块busy信号下降沿捕捉，用来产生下一个寄存器配置的start信号 |
| iic_wdata   | internal     | 写入IIC模块的寄存器配置信息                                  |
| iic_start   | internal     | IIC模块配置开始信号                                          |
| cfg_done    | internal     | 所有寄存器全部配置完成信号                                   |
| cnt_200us   | internal     | 寄存器配置完ANUM个之后延时200us之后发送结束信号              |

时序设计较为简单，在IIC模块基础上封装了一层用来对所有寄存器进行统一批次配置。

### 寄存器配置

这部分寄存器的详细内容见OV5640手册，内容太多了寄存器太多了配置信息太多了...这里就是简单做一个简单的导读，OK这部分我摆烂了。

好叭摆的不是很彻底，来分析一下这里的code对应的手册部分，首先我们看一下手册给出的对窗口信息的方块图：

![image-20230207120450784](https://user-images.githubusercontent.com/100147572/217209073-eeb53bdc-5ab0-46f7-85fa-bd8093bd7b3d.png)

| 寄存器 | Value | 描述                                                         |
| ------ | ----- | ------------------------------------------------------------ |
| 0x3800 | 00    | HS high bits                                                 |
| 0x3801 | 00    | HS low bits                                                  |
| 0x3802 | 00    | VS high bits                                                 |
| 0x3803 | fa    | VS low bits                                                  |
| 0x3804 | 0a    | HW high bits                                                 |
| 0x3805 | 3f    | HW low bits                                                  |
| 0x3806 | 06    | VH high bits                                                 |
| 0x3807 | a9    | VH low bits                                                  |
| 0x3808 | 04    | 行显示分辨率：1024                                           |
| 0x3809 | 00    | 行显示分辨率：1024                                           |
| 0x380a | 02    | 场显示分辨率：720                                            |
| 0x380b | d0    | 场显示分辨率：720                                            |
| 0x380c | 07    | 行显示总时间(OZVAL+SYNC+PORCH)：1892                         |
| 0x380d | 64    | 行显示总时间(OZVAL+SYNC+PORCH)：1892                         |
| 0x380e | 02    | 场显示总时间(OZVAL+SYNC+PORCH)：740                          |
| 0x380f | e4    | 场显示总时间(OZVAL+SYNC+PORCH)：740                          |
| 0x4300 | 23    | RGB565使用61格式（视频配置）<br>RGB888使用23，2：RGB888，3：像素点按R、G、B顺序排列 |

DVP时序和设计的VGA驱动类似，如下：

![image-20230207123210095](https://user-images.githubusercontent.com/100147572/217209105-2e6f686a-2d67-4869-856d-a4d4b6e19098.png)

### OV5640和VGA的速率匹配

1.   舍弃前10帧数据，给驱动寄存器的准备时间

2.   调整VGA显示频率为OV5640和SDRAM读写速率匹配，避免断帧

     1.   有了FIFO为什么还要匹配速率？不是已经保证了读写平衡吗？

          但是如果传输速率差超过了256，即FIFO半满的判定，会产生丢失帧数的情况，所以要让这个速率尽可能的平衡才能让FIFO发挥功能。毕竟FIFO深度不是无限的不可能缓存所有数据，如果速率差过大还是会产生丢失的

     2.   匹配速率：1344 * 806 * 84

     3.   分辨率修改为1024 * 768之后，由于垂直方向只有740pixels，所以修改`data_req`丢弃掉多余的垂直帧

### 其他修改

1.   修改SDRAM容量，单行读写1440
2.   实现SDRAM乒乓操作，让OV5640写数据和VGA读数据在不同bank操作
3.   修改时序违例：`ov5640_pclk`在自动读写模块时序违例，跨时钟域打三拍并且修改自动读写模块接口，使其适配摄像头的数据传输

### 暂时完结

其中还有一些零碎的问题和bug的修改在文档中没有介绍，请大家自行阅读代码进行发掘。当前项目还存在一些问题，我会尝试在之后的空闲中完善，作为学习资料来说这个项目还是足够了的，如果大家发现什么问题可以及时联系我，QQ：1304006240.
