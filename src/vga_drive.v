`define TFT_LCD
module vga_drive (
	input					sclk,
	input					s_rst_n,
	`ifdef TFT_LCD
	output wire				lcd_de,
	`endif
	output wire				vga_hsync,
	output wire				vga_vsync,
	output wire [23:0]			vga_rgb,

	output reg				vga_en,
	input [23:0]				img_data
);

localparam H_TOTAL_TIME = 1056;
localparam H_OZVAL_TIME = 800;
localparam H_SYNC_TIME = 128;
localparam H_BACK_PORCH = 88;
localparam H_FRONT_PORCH = 40;

localparam V_TOTAL_TIME = 525;
localparam V_OZVAL_TIME = 480;
localparam V_SYNC_TIME = 2;
localparam V_BACK_PORCH = 33;
localparam V_FRONT_PORCH = 10;

reg [10:0]			cnt_h;
reg [9:0]			cnt_v;
wire				data_req;

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cnt_h <= 'd0;
	else if(cnt_h >= H_TOTAL_TIME)
		cnt_h <= 'd0;
	else 
		cnt_h <= cnt_h + 1'b1;
end	

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cnt_v <= 'd0;
	else if(cnt_v >= V_TOTAL_TIME && cnt_h >= H_TOTAL_TIME)
		cnt_v <= 'd0;
	else if(cnt_h >= H_TOTAL_TIME)
		cnt_v <= cnt_v + 1'b1;
end	

// always @(posedge sclk or negedge s_rst_n) begin
// 	if(s_rst_n == 1'b0)
// 		vga_rgb <= 24'hFFFFFF;
// 	else if(cnt_v >= (V_SYNC_TIME + V_BACK_PORCH) && cnt_v < (V_SYNC_TIME + V_BACK_PORCH + V_OZVAL_TIME)) begin
// 		if(cnt_h >= (H_SYNC_TIME + H_BACK_PORCH - 1) && cnt_h < (H_SYNC_TIME + H_BACK_PORCH + 200 - 1))
// 			vga_rgb <= 24'hff0000;
// 		else if(cnt_h >= (H_SYNC_TIME + H_BACK_PORCH + 200 - 1) && cnt_h < (H_SYNC_TIME + H_BACK_PORCH + 400 - 1))
// 			vga_rgb <= 24'h00ff00;
// 		else if(cnt_h >= (H_SYNC_TIME + H_BACK_PORCH + 400 - 1) && cnt_h < (H_SYNC_TIME + H_BACK_PORCH + 600 - 1))
// 			vga_rgb <= 24'h0000ff;
// 		else if(cnt_h >= (H_SYNC_TIME + H_BACK_PORCH + 600 - 1) && cnt_h < (H_SYNC_TIME + H_BACK_PORCH + H_OZVAL_TIME - 1))
// 			vga_rgb <= 24'hffff00;
// 		else 
// 			vga_rgb <= 24'h000000;
// 	end	else
// 		vga_rgb <= 24'hFFFFFF;
// end	

always @(posedge sclk) begin
	vga_en <= data_req;
end

assign data_req = 	((cnt_h >= ((H_SYNC_TIME + H_BACK_PORCH - 1) - 1)) && 
			(cnt_h >= ((H_SYNC_TIME + H_BACK_PORCH - 1) - 1 + H_OZVAL_TIME)) &&
			cnt_v >= (V_SYNC_TIME + V_BACK_PORCH) && 
			cnt_v < (V_SYNC_TIME + V_BACK_PORCH + V_OZVAL_TIME)) ? 1'b1 : 1'b0;
assign vga_rgb = (vga_en == 1'b1) ? img_data : 24'h0;
assign vga_hsync = (cnt_h < H_SYNC_TIME) ? 1'b1 : 1'b0;
assign vga_vsync = (cnt_v < V_SYNC_TIME) ? 1'b1 : 1'b0;

`ifdef TFT_LCD
assign lcd_de = 1'b0;
`endif

endmodule
