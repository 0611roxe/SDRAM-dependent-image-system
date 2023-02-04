module ov5460_cfg(
	input				    sclk,
	input				    s_rst_n,
	output				  iic_scl,
	inout				    iic_sda,
	input				    estart,
	input [31:0]		ewdata,
	output wire [7:0]	riic_data
);

localparam	ANUM = 5;
localparam	DELAY_200US = 1_0000;

wire [31:0]		cfg_array[ANUM-1:0];
reg [8:0]		cfg_idx;
reg				start;
wire			cfg_done;
reg	[15:0]		cnt_200us;
wire			busy;
wire			busy_n;	
reg [2:0]		busy_arr;
wire			iic_start;
wire [31:0]		iic_wdata;

assign cfg_array[0] = {8'h78, 16'h300a, 8'h56};
assign cfg_array[1] = {8'h79, 16'h300a, 8'h56};
assign cfg_array[2] = {8'h78, 16'h3010, 8'h55};
assign cfg_array[3] = {8'h78, 16'h3011, 8'h48};
assign cfg_array[4] = {8'h78, 16'h3012, 8'h10};

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		start <= 1'b0;
	else if(cfg_idx == 'd0 && start == 1'b0)
		start <= 1'b1;
	else if(busy_n == 1'b1 && cfg_idx < ANUM)
		start <= 1'b1;
	else
		start <= 1'b0;
end	

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cfg_idx <= 'd0;
	else if(cfg_idx >= ANUM)
		cfg_idx <= ANUM;
	else if(start == 1'b1)
		cfg_idx <= cfg_idx + 1'b1;
end	

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cnt_200us <= 'd0;
	else if(cfg_idx >= ANUM && cfg_done == 1'b0)
		cnt_200us <= cnt_200us + 1'b1;
end	

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		busy_arr <= 'd0;
	else
		busy_arr <= {busy_arr[1:0], busy};
end	

assign busy_n = busy_arr[2] & ~busy_arr[1];
assign iic_start = (cfg_done == 1'b1) ? estart : start;
assign iic_wdata = (cfg_done == 1'b1) ? ewdata : cfg_array[cfg_idx];
assign cfg_done = (cnt_200us >= DELAY_200US) ? 1'b1 : 1'b0;

ov5460_iic u_ov5460_iic(
	.sclk				(sclk		),
	.s_rst_n			(s_rst_n	),
	.iic_scl			(iic_scl	),
	.iic_sda			(iic_sda	),
	.start				(iic_start	),
	.wdata				(iic_wdata	),
	.riic_data		(riic_data	),
	.busy				  (busy		)
);

endmodule
