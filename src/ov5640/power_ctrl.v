module power_ctrl (
	input				sclk,	//50MHz 20ns
	input				s_rst_n,
	output wire			ov5640_pwdn,
	output wire			ov5640_resetb,
	output wire			power_done
);

localparam DELAY_6MS = 30_0000;
localparam DELAY_2MS = 10_0000;
localparam DELAY_21MS = 105_0000;

reg [18:0] cnt_6ms;
reg [16:0] cnt_2ms;
reg [20:0] cnt_21ms;

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cnt_6ms <= 'd0;
	else if(ov5640_pwdn == 1'b1)
		cnt_6ms <= cnt_6ms + 1'b1;
end

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cnt_2ms <= 'd0;
	else if(ov5640_resetb == 1'b0 && ov5640_pwdn == 1'b0)
		cnt_2ms <= cnt_2ms + 1'b1;
end

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cnt_21ms <= 'd0;
	else if(ov5640_resetb == 1'b1 && power_done == 1'b0)
		cnt_21ms <= cnt_21ms + 1'b1;
end

assign power_done = (cnt_21ms >= DELAY_21MS) ? 1'b1 : 1'b0;
assign ov5640_resetb = (cnt_2ms >= DELAY_2MS) ? 1'b1 : 1'b0;
assign ov5640_pwdn = (cnt_6ms >= DELAY_6MS) ? 1'b0 : 1'b1;

endmodule
