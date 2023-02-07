### 项目环境：
硬件资源：正点原子启明星ZYNQ7010 + OV5640摄像头模组

软件资源：Vivado 2019.2 + ModelSim 10.5

### 已经实现：

1.   串口接收模块，单次接收8bit数据,115200bps
2.   13条地址线，24位数据端口的SDRAM控制器，支持读写和自动刷新指令
3.   自动读写FIFO，深度512bit。写FIFO深度超过256bit时自动读入SDRAM，读FIFO深度小于256bit时自动写入VGA/LCD驱动
4.   支持800*480分辨率的VGA/LCD驱动模块
5.   支持OV5640摄像头模块实时显示

![image](https://user-images.githubusercontent.com/100147572/217203462-0a895eee-747b-4e13-8b9e-b4e034de0148.png)
![image](https://user-images.githubusercontent.com/100147572/217203566-b5681a00-800b-45c8-a6e7-1c4ab81bca92.png)
### ToDo：

1.   板级功能测试
2.   C++ Model模拟器
3.   修改AXI4总线接口
