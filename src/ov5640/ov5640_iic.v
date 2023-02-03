module ov5460_iic (
	input				      sclk,
	input				      s_rst_n,
	
	output reg			  iic_scl,
	inout				      iic_sda,
	input				      start,
	input [31:0]		  wdata,
	output reg [7:0]	riic_data,
	output reg			  busy
);

reg [31:0]		wsda_r;
reg [5:0]		  cfg_cnt;
reg				    iic_sda_r;
reg				    flag_ack;
reg [3:0]		  delay_cnt;
reg				    done;
wire			    dir;

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		wsda_r <= 'd0;
	else if(start == 1'b1)
		wsda_r <= wdata;
end	

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		iic_scl <= 1'b1;
	else if(start == 1'b1)
		iic_scl <= 1'b0;
	else if(cfg_cnt == 'd28 && dir == 1'b1 && delay_cnt <= 'd3)
		iic_scl <= 1'b1;
	else if(busy == 1'b1)
		iic_scl <= ~iic_scl;
	else 
		iic_scl <= 1'b1;
end	

always @(negedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		busy <= 'd0;
	else if(start == 1'b1)
		busy <= 1'b1;
	else if(done == 1'b1)
		busy <= 1'b0;
end	

always @(negedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		cfg_cnt <= 'd0;
	else if((cfg_cnt >= 'd47 && dir == 1'b1) || (cfg_cnt >= 'd37 && dir == 1'b0))
		cfg_cnt <= 'd0;
	else if(cfg_cnt == 'd28 && delay_cnt <= 'd4 && dir == 1'b1)
		cfg_cnt <= 'd28;
	else if(busy == 1'b1 && iic_scl == 1'b0)
		cfg_cnt <= cfg_cnt + 1'b1;
end	

always @(negedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		riic_data <= 'd0;
	else if(iic_scl == 1'b1 && cfg_cnt >= 'd38 && flag_ack == 1'b1)
		riic_data <= {riic_data[6:0], iic_sda};
end	

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		delay_cnt <= 'd0;
	else if(dir == 1'b1 && cfg_cnt == 'd28)
		delay_cnt <= delay_cnt + 1'b1;
	else 
		delay_cnt <= 'd0;
end	

always @(posedge sclk or negedge s_rst_n) begin
	if(s_rst_n == 1'b0)
		done <= 1'b0;
	else if(dir == 1'b1 && cfg_cnt == 'd46 && iic_scl == 1'b1)
		done <= 1'b1;
	else if(dir == 1'b0 && cfg_cnt == 'd36 && iic_scl == 1'b1)
		done <= 1'b1;
	else 
		done <= 1'b0;
end

always @(*) begin
	if(dir == 1'b1 && (cfg_cnt == 'd9 || cfg_cnt == 'd18 || cfg_cnt == 'd27 || (cfg_cnt >= 'd37 && cfg_cnt <= 'd45)))
		flag_ack <= 1'b1;
	else if(dir == 1'b0 && (cfg_cnt == 'd9 || cfg_cnt == 'd18 || cfg_cnt == 'd27 || cfg_cnt == 'd36))
		flag_ack <= 1'b1;
	else
		flag_ack <= 1'b0;
end	

always @(*) begin
	if(dir == 1'b1)
		case (cfg_cnt)
			0:	//start
				if(busy == 1'b1)
					iic_sda_r = 1'b0;
				else 
					iic_sda_r = 1'b1;
			//ID Address
			1: iic_sda_r = wsda_r[31];
			2: iic_sda_r = wsda_r[30]; 
			3: iic_sda_r = wsda_r[29]; 
			4: iic_sda_r = wsda_r[28]; 
			5: iic_sda_r = wsda_r[27]; 
			6: iic_sda_r = wsda_r[26]; 
			7: iic_sda_r = wsda_r[25]; 
			8: iic_sda_r = 1'b0;
			//Address High Byte
			10: iic_sda_r = wsda_r[23]; 
			11: iic_sda_r = wsda_r[22]; 
			12: iic_sda_r = wsda_r[21]; 
			13: iic_sda_r = wsda_r[20]; 
			14: iic_sda_r = wsda_r[19]; 
			15: iic_sda_r = wsda_r[18];
			16: iic_sda_r = wsda_r[17]; 
			17: iic_sda_r = wsda_r[16]; 
			//Address Low Byte
			19: iic_sda_r = wsda_r[15]; 
			20: iic_sda_r = wsda_r[14]; 
			21: iic_sda_r = wsda_r[13]; 
			22: iic_sda_r = wsda_r[12];
			23: iic_sda_r = wsda_r[11]; 
			24: iic_sda_r = wsda_r[10]; 
			25: iic_sda_r = wsda_r[9];
			26: iic_sda_r = wsda_r[8];
			//Stop & Start
			28: 
				if(delay_cnt == 'd1 || delay_cnt >= 'd4)
					iic_sda_r = 1'b0;
				else
					iic_sda_r <= 1'b1;
			//ID Address
			29: iic_sda_r = wsda_r[31]; 
			30: iic_sda_r = wsda_r[30]; 
			31: iic_sda_r = wsda_r[29]; 
			32: iic_sda_r = wsda_r[28];
			33: iic_sda_r = wsda_r[27]; 
			34: iic_sda_r = wsda_r[26]; 
			35: iic_sda_r = wsda_r[25];
			36: iic_sda_r = wsda_r[24];
			//STOP
			47: iic_sda_r = 1'b0;
			default: iic_sda_r = 1'b1;
		endcase
	else
		case (cfg_cnt)
			0:	//start
				if(busy == 1'b1)
					iic_sda_r = 1'b0;
				else 
					iic_sda_r = 1'b1;
			//ID Address
			1: iic_sda_r = wsda_r[31];
			2: iic_sda_r = wsda_r[30]; 
			3: iic_sda_r = wsda_r[29]; 
			4: iic_sda_r = wsda_r[28]; 
			5: iic_sda_r = wsda_r[27]; 
			6: iic_sda_r = wsda_r[26]; 
			7: iic_sda_r = wsda_r[25]; 
			8: iic_sda_r = 1'b0;
			//Address High Byte
			10: iic_sda_r = wsda_r[23]; 
			11: iic_sda_r = wsda_r[22]; 
			12: iic_sda_r = wsda_r[21]; 
			13: iic_sda_r = wsda_r[20]; 
			14: iic_sda_r = wsda_r[19]; 
			15: iic_sda_r = wsda_r[18];
			16: iic_sda_r = wsda_r[17]; 
			17: iic_sda_r = wsda_r[16]; 
			//Address Low Byte
			19: iic_sda_r = wsda_r[15]; 
			20: iic_sda_r = wsda_r[14]; 
			21: iic_sda_r = wsda_r[13]; 
			22: iic_sda_r = wsda_r[12];
			23: iic_sda_r = wsda_r[11]; 
			24: iic_sda_r = wsda_r[10]; 
			25: iic_sda_r = wsda_r[9];
			26: iic_sda_r = wsda_r[8];
			//Write data
			28: iic_sda_r = wsda_r[7]; 
			29: iic_sda_r = wsda_r[6]; 
			30: iic_sda_r = wsda_r[5]; 
			31: iic_sda_r = wsda_r[4];
			32: iic_sda_r = wsda_r[3]; 
			33: iic_sda_r = wsda_r[2]; 
			34: iic_sda_r = wsda_r[1];
			35: iic_sda_r = wsda_r[0];
			//Stop
			37: iic_sda_r = 1'b0;
			default: iic_sda_r = 1'b1;
		endcase
end	

assign iic_sda = (flag_ack == 1'b1) ? 1'bz : iic_sda_r;
assign dir = wdata[24];

endmodule
