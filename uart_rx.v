`define SIM
module uart_rx (
	//System Signals
	input				sclk,
	input				s_rst_n,
	//UART Interface
	input				rs232_rx,
	//Others
	output reg [7:0] 	rx_data,
	output reg			po_flag
);

`ifndef SIM
// localparam BAUD_END = 5207;			//9600bps
localparam BAUD_END = 433;				//115200bps
`else
localparam BAUD_END = 28;
`endif 
localparam BAUD_M = BAUD_END/2 - 1;
localparam BIT_END = 8;


//Internal Signals
reg			rx_r1;
reg			rx_r2;
reg			rx_r3;
reg			rx_flag;
reg [12:0]	baud_cnt;
reg			bit_flag;
reg [3:0]	bit_cnt;
wire 		rx_neg;	

assign rx_neg = ~rx_r2 & rx_r3;

always @(posedge sclk) begin
	rx_r1 <= rs232_rx;
	rx_r2 <= rx_r1;
	rx_r3 <= rx_r2;
end	

always @(posedge sclk or negedge s_rst_n) begin
	if (s_rst_n == 1'b0) begin
		rx_flag <= 1'b0;
	end else if(rx_neg == 1'b1) begin
		rx_flag <= 1'b1;
	end else if(bit_cnt == 'd0 && baud_cnt == BAUD_END) begin
		rx_flag <= 1'b0;
	end	
end

always @(posedge sclk or negedge s_rst_n) begin
	if (s_rst_n == 1'b0) begin
		baud_cnt <= 'd0;
	end	else if(baud_cnt == BAUD_END) begin
		baud_cnt <= 'd0;
	end else if(rx_flag == 1'b1) begin
		baud_cnt <= baud_cnt + 1'b1;
	end else
		baud_cnt <= 'd0;
end

always @(posedge sclk or negedge s_rst_n) begin
	if (s_rst_n == 1'b0) begin
		bit_flag <= 1'b0;
	end else if(baud_cnt == BAUD_M) begin
		bit_flag <= 1'b1;
	end	else
		bit_flag <= 1'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
	if (s_rst_n == 1'b0) begin
		bit_cnt <= 'b0;
	end	else if(bit_flag == 1'b1 && bit_cnt == BIT_END) begin
		bit_cnt <= 'b0;
	end else if(bit_flag == 1'b1) begin
		bit_cnt <= bit_cnt + 1;
	end
end

always @(posedge sclk or negedge s_rst_n) begin
	if (s_rst_n == 1'b0) begin
		rx_data <= 'b0;
	end else if(bit_flag == 1'b1 && bit_cnt >= 'd1) begin
		rx_data <= {rx_r2, rx_data[7:1]};
	end
end	

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0) begin
		po_flag <= 1'b0;
	end	else if(bit_cnt == BIT_END && bit_flag == 1'b1) begin
		po_flag <= 1'b1;
	end	else 
		po_flag <= 1'b0;
end	

endmodule