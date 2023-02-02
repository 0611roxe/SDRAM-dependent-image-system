`timescale 1ns/1ns
module tb_ov5640

reg 		sclk;
reg 		s_rst_n;

wire		ov5640_pwdn;  
wire		ov5640_resetb;
wire		power_done;   

initial begin
	sclk = 1;
	s_rst_n <= 0;
	#100
	s_rst_n <= 1;
end

always #5 sclk = ~sclk;

power_ctrl u_power_ctrl(
	.sclk				(sclk 		),
	.s_rst_n 			(s_rst_n  	),
	.ov5640_pwdn 		(ov5640_pwdn),
	.ov5640_resetb   	(ov5640_resetb),
	.power_done  		(power_done )
);

endmodule
