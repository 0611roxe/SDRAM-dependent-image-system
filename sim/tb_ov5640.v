`timescale 1ns/1ns
module tb_ov5640

reg 		sclk;
reg 		s_rst_n;

reg			start;
reg [31:0]	wdata;

wire		ov5640_pwdn;  
wire		ov5640_resetb;
wire		power_done;

initial begin
	sclk = 1;
	s_rst_n <= 0;
	start <= 0;
	wdata <= 32'h78300a56;
	#100
	s_rst_n <= 1;
	#100
	start <= 1;
	#10
	start <= 0;
	#1000
	start <= 1;
	wdata <= 32'h79300a56;
	#10
	start <= 0;
end

always #5 sclk = ~sclk;

power_ctrl u_power_ctrl(
	.sclk				(sclk 		),
	.s_rst_n 			(s_rst_n  	),
	.ov5640_pwdn 		(ov5640_pwdn),
	.ov5640_resetb   	(ov5640_resetb),
	.power_done  		(power_done )
);

ov5460_iic u_ov5460_iic(
	.sclk			(sclk		),
	.s_rst_n		(s_rst_n	),
	.iic_scl		(iic_scl	),
	.iic_sda		(iic_sda	),
	.start			(start		),
	.wdata			(wdata		),
	.riic_data		(riic_data	),
	.busy			(busy		)
);	


endmodule
