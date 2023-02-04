`define TFT_LCD
module top(
	input					sclk,
	input					s_rst_n,
	input					rs232_rx,
	`ifdef TFT_LCD	
	output wire				lcd_de,
	`endif	
	output wire				vga_hsync,
	output wire				vga_vsync,
	output wire [23:0]		vga_rgb,

	output wire				ov5640_pwdn ,
	output wire				ov5640_resetb,
	output wire				ov5460_xclk,
	output wire 			ov5460_iic_scl,
	inout					ov5460_iic_sda
);

wire			clk_sys33_3m;
wire			clk_sys100m;
wire			clk_sys50m;
wire			clk_sys24m;
wire [7:0]		uart_data;
wire			uart_flag;
wire			vga_en;
wire [23:0]		img_data;
wire 			rfifo_rd_ready;
wire [23:0]		vga_rgb_t;

wire			sdram_clk;
wire			sdram_cke;
wire			sdram_cs_n;
wire			sdram_cas_n;
wire			sdram_ras_n;
wire			sdram_we_n;
wire [1:0]		sdram_bank;
wire [12:0]		sdram_addr;
wire [1:0]		sdram_dqm;
wire [23:0]		sdram_dq;
wire			sdram_init_done;

wire 			estart;
wire [31:0]		ewdata;
wire [7:0]		riic_data;

assign vga_rgb = 	{{vga_rgb_t[15:11], vga_rgb_t[15:13]},
					{vga_rgb_t[10:5], vga_rgb_t[10:9]},
					{vga_rgb_t[4:0], vga_rgb_t[4:2]}};

uart_rx u_uart_rx(
	.sclk					(clk_sys50m	),
	.s_rst_n				(s_rst_n	),
	.rs232_rx				(rs232_rx	),
	.rx_data				(uart_data	),
	.po_flag				(uart_flag	)
);

vga_drive u_vga_drive(
	.sclk					(clk_sys33_3m),
	.s_rst_n				(sdram_init_done),
	`ifdef TFT_LCD
	.lcd_de					(lcd_de		),
	`endif
	.vga_hsync				(vga_hsync	),
	.vga_vsync				(vga_vsync	),
	.vga_rgb				(vga_rgb_t 	),
	.vga_en					(vga_en		),
	.img_data				(img_data	)
);

clk_wiz_0 u_clk_wiz(
	.clk_out1				(clk_sys33_3m),		// output clk_out1
	.clk_out2				(clk_sys100m),		// output clk_out2
	.clk_out3				(clk_sys50m	),		// output clk_out3
	.clk_out4				(clk_sys24m	),
	.reset					(~s_rst_n	), 		// input reset
	.locked					(),					// output locked
	.clk_in1				(sclk		)
);

sdram_top u_sdram_top(
	.sclk				(clk_sys100m	),
	.s_rst_n			(s_rst_n		),
	.sdram_clk			(sdram_clk		),
	.sdram_cke			(sdram_cke		),
	.sdram_cs_n			(sdram_cs_n		),
	.sdram_cas_n		(sdram_cas_n	),
	.sdram_ras_n		(sdram_ras_n	),
	.sdram_we_n			(sdram_we_n		),
	.sdram_bank			(sdram_bank		),
	.sdram_addr			(sdram_addr		),
	.sdram_dqm			(sdram_dqm		),
	.sdram_dq			(sdram_dq		),
	.sdram_init_done	(sdram_init_done),
	.wfifo_wclk			(clk_sys50m		),
	.wfifo_wr_en		(uart_flag		),
	.wfifo_wr_data		({16'h0, uart_data}),
	.rfifo_rclk			(clk_sys33_3m	),
	.rfifo_rd_en		(vga_en			),
	.rfifo_rd_data		(img_data		),
	.rfifo_rd_ready		(rfifo_rd_ready	)
);

ov5640_top u_ov5640_top(
	.clk_sys50m			(clk_sys50m		),
	.s_rst_n			(s_rst_n		),
	.clk_sys24m			(clk_sys24m		),
	.ov5640_pwdn 		(ov5640_pwdn 	),
	.ov5640_resetb		(ov5640_resetb	),
	.ov5460_xclk		(ov5460_xclk	),
	.ov5460_iic_scl		(ov5460_iic_scl	),
	.ov5460_iic_sda		(ov5460_iic_sda	),
	.estart				(estart			),
	.ewdata				(ewdata			),
	.riic_data			(riic_data		)
);

endmodule
