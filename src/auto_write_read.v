module auto_write_read (
	input				s_rst_n,

	input				wfifo_wclk,
	input				wfifo_wr_en,
	input [15:0]		wfifo_wr_data,
	input				wfifo_rclk,
	input				wfifo_rd_en,
	output wire [15:0]	wfifo_rd_data,
	output reg			wr_trig,

	input				flag_wr_end,
	input				vga_vsync,
	input				ov5640_vsync,
	input				rfifo_wclk,
	input				rfifo_wr_en,
	input [15:0]		rfifo_wr_data,
	input				rfifo_rclk,
	input				rfifo_rd_en,
	output wire [15:0]	rfifo_rd_data,
	output reg			rd_trig
);
localparam	WFIFO_RD_CNT = 256;
localparam	RFIFO_WR_CNT = 243;

wire [8:0]			wfifo_rside_usedw;
wire [8:0]			wfifo_wside_usedw;

wire [8:0]			rfifo_rside_usedw;
wire [8:0]			rfifo_wside_usedw;

reg					rfifo_wr_valid;

reg					vga_vsync_r1;
reg					vga_vsync_r2;
reg					vga_vsync_r3;

always @(posedge rfifo_wclk) begin
	vga_vsync_r1 <= vga_vsync;
	vga_vsync_r2 <= vga_vsync_r1;
	vga_vsync_r3 <= vga_vsync_r2;
end	

always @(posedge wfifo_rclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		wr_trig <= 1'b0;
	else if(wfifo_rside_usedw >= WFIFO_RD_CNT)
		wr_trig <= 1'b1;
	else
		wr_trig <= 1'b0;
end	

always @(posedge rfifo_wclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		rd_trig <= 1'b0;
	else if(rfifo_wside_usedw <= RFIFO_WR_CNT && vga_vsync_r3 == 1'b0)
		rd_trig <= 1'b1;
	else
		rd_trig <= 1'b0;
end	

always @(posedge rfifo_wclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		rfifo_wr_valid <= 1'b0;
	else if(flag_wr_end == 1'b1)
		rfifo_wr_valid <= 1'b1;
end	

dfifo_512x16 u_wdfifo (
	.rst				(~s_rst_n | ov5640_vsync),		// input wire rst
	.wr_clk				(wfifo_wclk		),				// input wire wr_clk
	.rd_clk				(wfifo_rclk		),				// input wire rd_clk
	.din				(wfifo_wr_data	),				// input wire [15 : 0] din
	.wr_en				(wfifo_wr_en	),				// input wire wr_en
	.rd_en				(wfifo_rd_en	),				// input wire rd_en
	.dout				(wfifo_rd_data	),				// output wire [15 : 0] dout
	.full				(),				// output wire full
	.almost_full		(),				// output wire almost_full
	.empty				(),				// output wire empty
	.almost_empty		(),	// output wire almost_empty
	.rd_data_count		(wfifo_rside_usedw),  // output wire [8 : 0] rd_data_count
	.wr_data_count		(wfifo_wside_usedw),  // output wire [8 : 0] wr_data_count
	.wr_rst_busy		(),	  // output wire wr_rst_busy
	.rd_rst_busy		()	  // output wire rd_rst_busy
);

dfifo_512x16 u_rdfifo (
	.rst				(~s_rst_n | vga_vsync_r3),					  // input wire rst
	.wr_clk				(rfifo_wclk	),				// input wire wr_clk
	.rd_clk				(rfifo_rclk	),				// input wire rd_clk
	.din				(rfifo_wr_data	),					  // input wire [15 : 0] din
	.wr_en				(rfifo_wr_en	),				  // input wire wr_en
	.rd_en				(rfifo_rd_en	),				  // input wire rd_en
	.dout				(rfifo_rd_data	),					// output wire [15 : 0] dout
	.full				(),					// output wire full
	.almost_full		(),	  // output wire almost_full
	.empty				(),				  // output wire empty
	.almost_empty		(),	// output wire almost_empty
	.rd_data_count		(rfifo_rside_usedw),  // output wire [8 : 0] rd_data_count
	.wr_data_count		(rfifo_wside_usedw),  // output wire [8 : 0] wr_data_count
	.wr_rst_busy		(),	  // output wire wr_rst_busy
	.rd_rst_busy		()	  // output wire rd_rst_busy
);

endmodule
