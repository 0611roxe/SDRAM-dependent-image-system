`define SIM
module ov5640_top(
	input				    clk_sys50m,
	input				    s_rst_n,
	input				    clk_sys24m,
	`ifdef SIM
	input				    div_clk,
	`endif 
	output wire			ov5640_pwdn ,
	output wire			ov5640_resetb,
	output wire			ov5460_xclk,
	output wire 		ov5460_iic_scl,
	inout				    ov5460_iic_sda,

	input				    estart,
	input [31:0]		ewdata,
	output wire	[7:0]	riic_data
);

wire			power_done;
reg [8:0]		div_cnt;
`ifndef SIM
wire			div_clk;
`endif 
reg [2:0]		estart_arr;
wire			start;

`ifndef SIM
always @(posedge clk_sys50m or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		div_cnt <= 'd0;
	else 
		div_cnt <= div_cnt + 1'b1;
end	

always @(posedge div_clk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		estart_arr <= 'b0;
	else
		estart_arr <= {estart_arr[1:0], estart};
end
`endif 

`ifndef SIM
assign div_clk = div_cnt[8];
`endif 
assign start = estart_arr[1] & ~estart_arr[2];
assign ov5460_xclk = clk_sys24m;

power_ctrl u_power_ctrl(
	.sclk				(clk_sys50m		),
	.s_rst_n 			(s_rst_n  		),
	.ov5640_pwdn 		(ov5640_pwdn	),
	.ov5640_resetb   	(ov5640_resetb	),
	.power_done  		(power_done 	)
);

ov5460_cfg u_ov5460_cfg(
	.sclk				(div_clk		),
	.s_rst_n			(s_rst_n		),
	.iic_scl			(ov5640_iic_scl	),
	.iic_sda			(ov5640_iic_sda	),
	.estart				(estart			),
	.ewdata				(ewdata			),
	.riic_data			(riic_data		)
);

endmodule
