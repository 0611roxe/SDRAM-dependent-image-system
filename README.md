### 已经实现：

1.   串口接收模块，单次接收8bit数据
2.   13条地址线，24位数据端口的SDRAM控制器，支持读写和自动刷新指令
3.   自动读写FIFO，深度512bit。写FIFO深度超过256bit时自动读入SDRAM，读FIFO深度小于256bit时自动写入VGA/LCD驱动
4.   支持800*480分辨率的VGA/LCD驱动模块
5.   已通过Vivado综合
![image](https://user-images.githubusercontent.com/100147572/211507745-3a985be6-e28a-4b94-86b3-081a2436006d.png)
![image](https://user-images.githubusercontent.com/100147572/211508027-63aff823-c914-4694-ae8c-39060eae4a4f.png)


### 尚存BUG：

1.   RGB颜色失真，LCD驱动使用RGB888格式，但串口单次仅接收8bit数据，不适用于RGB565/233格式，需要进行色彩转换
2.   显示概率出现白条，SDRAM控制器时序问题，数据写入和读出时可能存在丢失

### ToDo：

1.   板级功能测试
2.   修改RGB失真BUG
3.   OV5640摄像头实时图像采集显示
