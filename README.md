### 项目环境：
硬件资源：正点原子启明星ZYNQ7010 + OV5640摄像头模组

软件资源：Vivado 2019.2 + ModelSim 10.5

### 已经实现：

1.   串口接收模块，单次接收8bit数据,115200bps
2.   13条地址线，24位数据端口的SDRAM控制器，支持读写和自动刷新指令
3.   自动读写FIFO，深度512bit。写FIFO深度超过256bit时自动读入SDRAM，读FIFO深度小于256bit时自动写入VGA/LCD驱动
4.   支持800*480分辨率的VGA/LCD驱动模块
5.   已通过Vivado综合

![image](https://user-images.githubusercontent.com/100147572/216013259-19d72351-1e46-4a20-ad95-f45a0511561f.png)
![image](https://user-images.githubusercontent.com/100147572/216013490-6c6febf8-bcb7-4f7d-acd1-83a531a92bd3.png)

### ToDo：

1.   板级功能测试
2.   OV5640摄像头实时图像采集显示
3.   C++ Model模拟器
