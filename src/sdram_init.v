module sdram_init (
	input               sclk,
	input               s_rst_n,

	output reg [3:0]    cmd_reg,
	output wire [12:0]  sdram_addr,
	output wire         flag_init_end
);
localparam  DELAY_200us = 20000;
localparam  NOP = 4'b0111;
localparam  PRE = 4'b0010;
localparam  AREF = 4'b0001;
localparam  MSET = 4'b0000;


reg [14:0]      cnt_200us;
wire            flag_200us;
reg [4:0]       cnt_cmd;

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cnt_200us <= 'd0;
	else if(flag_200us == 1'b0)
		cnt_200us <= cnt_200us + 1'b1; 
end 

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cnt_cmd <= 'd0;
	else if(flag_200us == 1'b1 && flag_init_end == 1'b0)
		cnt_cmd <= cnt_cmd + 1;
end 

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cmd_reg <= NOP;
	else if(flag_200us == 1'b1)
		case (cnt_cmd)
			0:	cmd_reg <= PRE;
			2:	cmd_reg <= AREF;
			10:	cmd_reg <= AREF;
			18:	cmd_reg <= MSET;
			default:	cmd_reg <= NOP; 
		endcase 
end

assign flag_init_end = (cnt_cmd >= 'd19) ? 1'b1 : 1'b0;
assign sdram_addr = (cmd_reg == MSET) ? 13'b0_0000_0011_0010 : 13'b0_0100_0000_0000;
assign flag_200us = (cnt_200us >= DELAY_200us) ? 1'b1 : 1'b0;

endmodule
