module ov5460_cfg(
	input				sclk,
	input				s_rst_n,
	output				iic_scl,
	inout				iic_sda,
	input				estart,
	input [31:0]		ewdata,
	output wire [7:0]	riic_data
);

localparam	ANUM = 304;
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

assign cfg_array[000] = {8'h78, 16'h3103, 8'h11};
assign cfg_array[001] = {8'h78, 16'h3008, 8'h82};
assign cfg_array[002] = {8'h78, 16'h3008, 8'h42};
assign cfg_array[003] = {8'h78, 16'h3103, 8'h03};
assign cfg_array[004] = {8'h78, 16'h3017, 8'hff};
assign cfg_array[005] = {8'h78, 16'h3018, 8'hff};
assign cfg_array[006] = {8'h78, 16'h3034, 8'h1A};
assign cfg_array[007] = {8'h78, 16'h3037, 8'h13};       // PLL root divider, bit[4], PLL pre-divider, bit[3:0]
assign cfg_array[008] = {8'h78, 16'h3108, 8'h01};       // PCLK root divider, bit[5:4], SCLK2x root divider, bit[3:2] // SCLK root divider, bit[1:0] 
assign cfg_array[009] = {8'h78, 16'h3630, 8'h36};
                                             
assign cfg_array[010] = {8'h78, 16'h3631, 8'h0e};
assign cfg_array[011] = {8'h78, 16'h3632, 8'he2};
assign cfg_array[012] = {8'h78, 16'h3633, 8'h12};
assign cfg_array[013] = {8'h78, 16'h3621, 8'he0};
assign cfg_array[014] = {8'h78, 16'h3704, 8'ha0};
assign cfg_array[015] = {8'h78, 16'h3703, 8'h5a};
assign cfg_array[016] = {8'h78, 16'h3715, 8'h78};
assign cfg_array[017] = {8'h78, 16'h3717, 8'h01};
assign cfg_array[018] = {8'h78, 16'h370b, 8'h60};
assign cfg_array[019] = {8'h78, 16'h3705, 8'h1a};
                                           
assign cfg_array[020] = {8'h78, 16'h3905, 8'h02};
assign cfg_array[021] = {8'h78, 16'h3906, 8'h10};
assign cfg_array[022] = {8'h78, 16'h3901, 8'h0a};
assign cfg_array[023] = {8'h78, 16'h3731, 8'h12};
assign cfg_array[024] = {8'h78, 16'h3600, 8'h08};
assign cfg_array[025] = {8'h78, 16'h3601, 8'h33};
assign cfg_array[026] = {8'h78, 16'h302d, 8'h60};
assign cfg_array[027] = {8'h78, 16'h3620, 8'h52};
assign cfg_array[028] = {8'h78, 16'h371b, 8'h20};
assign cfg_array[029] = {8'h78, 16'h471c, 8'h50};
            
assign cfg_array[030] = {8'h78, 16'h3a13, 8'h43};
assign cfg_array[031] = {8'h78, 16'h3a18, 8'h00};
assign cfg_array[032] = {8'h78, 16'h3a19, 8'hf8};
assign cfg_array[033] = {8'h78, 16'h3635, 8'h13};
assign cfg_array[034] = {8'h78, 16'h3636, 8'h03};
assign cfg_array[035] = {8'h78, 16'h3634, 8'h40};
assign cfg_array[036] = {8'h78, 16'h3622, 8'h01};
assign cfg_array[037] = {8'h78, 16'h3c01, 8'h34};
assign cfg_array[038] = {8'h78, 16'h3c04, 8'h28};
assign cfg_array[039] = {8'h78, 16'h3c05, 8'h98};     
            
assign cfg_array[040] = {8'h78, 16'h3c06, 8'h00};
assign cfg_array[041] = {8'h78, 16'h3c07, 8'h08};
assign cfg_array[042] = {8'h78, 16'h3c08, 8'h00};
assign cfg_array[043] = {8'h78, 16'h3c09, 8'h1c};
assign cfg_array[044] = {8'h78, 16'h3c0a, 8'h9c};
assign cfg_array[045] = {8'h78, 16'h3c0b, 8'h40};
assign cfg_array[046] = {8'h78, 16'h3810, 8'h00};
assign cfg_array[047] = {8'h78, 16'h3811, 8'h10};
assign cfg_array[048] = {8'h78, 16'h3812, 8'h00};
assign cfg_array[049] = {8'h78, 16'h3708, 8'h64};
            
assign cfg_array[050] = {8'h78, 16'h4001, 8'h02};
assign cfg_array[051] = {8'h78, 16'h4005, 8'h1a};
assign cfg_array[052] = {8'h78, 16'h3000, 8'h00};
assign cfg_array[053] = {8'h78, 16'h3004, 8'hff};
assign cfg_array[054] = {8'h78, 16'h300e, 8'h58};
assign cfg_array[055] = {8'h78, 16'h302e, 8'h00};
assign cfg_array[056] = {8'h78, 16'h4300, 8'h23};		//RGB 565:61 RGB888:23
assign cfg_array[057] = {8'h78, 16'h501f, 8'h01};
assign cfg_array[058] = {8'h78, 16'h440e, 8'h00};
assign cfg_array[059] = {8'h78, 16'h5000, 8'ha7};    
             
assign cfg_array[060] = {8'h78, 16'h3a0f, 8'h30};
assign cfg_array[061] = {8'h78, 16'h3a10, 8'h28};
assign cfg_array[062] = {8'h78, 16'h3a1b, 8'h30};
assign cfg_array[063] = {8'h78, 16'h3a1e, 8'h26};
assign cfg_array[064] = {8'h78, 16'h3a11, 8'h60};
assign cfg_array[065] = {8'h78, 16'h3a1f, 8'h14};
assign cfg_array[066] = {8'h78, 16'h5800, 8'h23};
assign cfg_array[067] = {8'h78, 16'h5801, 8'h14};
assign cfg_array[068] = {8'h78, 16'h5802, 8'h0f};
assign cfg_array[069] = {8'h78, 16'h5803, 8'h0f};  
            
assign cfg_array[070] = {8'h78, 16'h5804, 8'h12};
assign cfg_array[071] = {8'h78, 16'h5805, 8'h26};
assign cfg_array[072] = {8'h78, 16'h5806, 8'h0c};
assign cfg_array[073] = {8'h78, 16'h5807, 8'h08};
assign cfg_array[074] = {8'h78, 16'h5808, 8'h05};
assign cfg_array[075] = {8'h78, 16'h5809, 8'h05};
assign cfg_array[076] = {8'h78, 16'h580a, 8'h08};
assign cfg_array[077] = {8'h78, 16'h580b, 8'h0d};
assign cfg_array[078] = {8'h78, 16'h580c, 8'h08};
assign cfg_array[079] = {8'h78, 16'h580d, 8'h03};    
          
assign cfg_array[080] = {8'h78, 16'h580e, 8'h00};
assign cfg_array[081] = {8'h78, 16'h580f, 8'h00};
assign cfg_array[082] = {8'h78, 16'h5810, 8'h03};
assign cfg_array[083] = {8'h78, 16'h5811, 8'h09};
assign cfg_array[084] = {8'h78, 16'h5812, 8'h07};
assign cfg_array[085] = {8'h78, 16'h5813, 8'h03};
assign cfg_array[086] = {8'h78, 16'h5814, 8'h00};
assign cfg_array[087] = {8'h78, 16'h5815, 8'h01};
assign cfg_array[088] = {8'h78, 16'h5816, 8'h03};
assign cfg_array[089] = {8'h78, 16'h5817, 8'h08};  
           
assign cfg_array[090] = {8'h78, 16'h5818, 8'h0d};
assign cfg_array[091] = {8'h78, 16'h5819, 8'h08};
assign cfg_array[092] = {8'h78, 16'h581a, 8'h05};
assign cfg_array[093] = {8'h78, 16'h581b, 8'h06};
assign cfg_array[094] = {8'h78, 16'h581c, 8'h08};
assign cfg_array[095] = {8'h78, 16'h581d, 8'h0e};
assign cfg_array[096] = {8'h78, 16'h581e, 8'h29};
assign cfg_array[097] = {8'h78, 16'h581f, 8'h17};
assign cfg_array[098] = {8'h78, 16'h5820, 8'h11};
assign cfg_array[099] = {8'h78, 16'h5821, 8'h11};     
              
assign cfg_array[100] = {8'h78, 16'h5822, 8'h15};
assign cfg_array[101] = {8'h78, 16'h5823, 8'h28};
assign cfg_array[102] = {8'h78, 16'h5824, 8'h46};
assign cfg_array[103] = {8'h78, 16'h5825, 8'h26};
assign cfg_array[104] = {8'h78, 16'h5826, 8'h08};
assign cfg_array[105] = {8'h78, 16'h5827, 8'h26};
assign cfg_array[106] = {8'h78, 16'h5828, 8'h64};
assign cfg_array[107] = {8'h78, 16'h5829, 8'h26};
assign cfg_array[108] = {8'h78, 16'h582a, 8'h24};
assign cfg_array[109] = {8'h78, 16'h582b, 8'h22};       
            
assign cfg_array[110] = {8'h78, 16'h582c, 8'h24};
assign cfg_array[111] = {8'h78, 16'h582d, 8'h24};
assign cfg_array[112] = {8'h78, 16'h582e, 8'h06};
assign cfg_array[113] = {8'h78, 16'h582f, 8'h22};
assign cfg_array[114] = {8'h78, 16'h5830, 8'h40};
assign cfg_array[115] = {8'h78, 16'h5831, 8'h42};
assign cfg_array[116] = {8'h78, 16'h5832, 8'h24};
assign cfg_array[117] = {8'h78, 16'h5833, 8'h26};
assign cfg_array[118] = {8'h78, 16'h5834, 8'h24};
assign cfg_array[119] = {8'h78, 16'h5835, 8'h22};        
            
assign cfg_array[120] = {8'h78, 16'h5836, 8'h22};
assign cfg_array[121] = {8'h78, 16'h5837, 8'h26};
assign cfg_array[122] = {8'h78, 16'h5838, 8'h44};
assign cfg_array[123] = {8'h78, 16'h5839, 8'h24};
assign cfg_array[124] = {8'h78, 16'h583a, 8'h26};
assign cfg_array[125] = {8'h78, 16'h583b, 8'h28};
assign cfg_array[126] = {8'h78, 16'h583c, 8'h42};
assign cfg_array[127] = {8'h78, 16'h583d, 8'hce};
assign cfg_array[128] = {8'h78, 16'h5180, 8'hff};
assign cfg_array[129] = {8'h78, 16'h5181, 8'hf2};   
            
assign cfg_array[130] = {8'h78, 16'h5182, 8'h00};
assign cfg_array[131] = {8'h78, 16'h5183, 8'h14};
assign cfg_array[132] = {8'h78, 16'h5184, 8'h25};
assign cfg_array[133] = {8'h78, 16'h5185, 8'h24};
assign cfg_array[134] = {8'h78, 16'h5186, 8'h09};
assign cfg_array[135] = {8'h78, 16'h5187, 8'h09};
assign cfg_array[136] = {8'h78, 16'h5188, 8'h09};
assign cfg_array[137] = {8'h78, 16'h5189, 8'h75};
assign cfg_array[138] = {8'h78, 16'h518a, 8'h54};
assign cfg_array[139] = {8'h78, 16'h518b, 8'he0};   
            
assign cfg_array[140] = {8'h78, 16'h518c, 8'hb2};
assign cfg_array[141] = {8'h78, 16'h518d, 8'h42};
assign cfg_array[142] = {8'h78, 16'h518e, 8'h3d};
assign cfg_array[143] = {8'h78, 16'h518f, 8'h56};
assign cfg_array[144] = {8'h78, 16'h5190, 8'h46};
assign cfg_array[145] = {8'h78, 16'h5191, 8'hf8};
assign cfg_array[146] = {8'h78, 16'h5192, 8'h04};
assign cfg_array[147] = {8'h78, 16'h5193, 8'h70};
assign cfg_array[148] = {8'h78, 16'h5194, 8'hf0};
assign cfg_array[149] = {8'h78, 16'h5195, 8'hf0};   
             
assign cfg_array[150] = {8'h78, 16'h5196, 8'h03};
assign cfg_array[151] = {8'h78, 16'h5197, 8'h01};
assign cfg_array[152] = {8'h78, 16'h5198, 8'h04};
assign cfg_array[153] = {8'h78, 16'h5199, 8'h12};
assign cfg_array[154] = {8'h78, 16'h519a, 8'h04};
assign cfg_array[155] = {8'h78, 16'h519b, 8'h00};
assign cfg_array[156] = {8'h78, 16'h519c, 8'h06};
assign cfg_array[157] = {8'h78, 16'h519d, 8'h82};
assign cfg_array[158] = {8'h78, 16'h519e, 8'h38};
assign cfg_array[159] = {8'h78, 16'h5480, 8'h01};   
             
assign cfg_array[160] = {8'h78, 16'h5481, 8'h08};
assign cfg_array[161] = {8'h78, 16'h5482, 8'h14};
assign cfg_array[162] = {8'h78, 16'h5483, 8'h28};
assign cfg_array[163] = {8'h78, 16'h5484, 8'h51};
assign cfg_array[164] = {8'h78, 16'h5485, 8'h65};
assign cfg_array[165] = {8'h78, 16'h5486, 8'h71};
assign cfg_array[166] = {8'h78, 16'h5487, 8'h7d};
assign cfg_array[167] = {8'h78, 16'h5488, 8'h87};
assign cfg_array[168] = {8'h78, 16'h5489, 8'h91};
assign cfg_array[169] = {8'h78, 16'h548a, 8'h9a};   
            
assign cfg_array[170] = {8'h78, 16'h548b, 8'haa};
assign cfg_array[171] = {8'h78, 16'h548c, 8'hb8};
assign cfg_array[172] = {8'h78, 16'h548d, 8'hcd};
assign cfg_array[173] = {8'h78, 16'h548e, 8'hdd};
assign cfg_array[174] = {8'h78, 16'h548f, 8'hea};
assign cfg_array[175] = {8'h78, 16'h5490, 8'h1d};
assign cfg_array[176] = {8'h78, 16'h5381, 8'h1e};
assign cfg_array[177] = {8'h78, 16'h5382, 8'h5b};
assign cfg_array[178] = {8'h78, 16'h5383, 8'h08};
assign cfg_array[179] = {8'h78, 16'h5384, 8'h0a};  
              
assign cfg_array[180] = {8'h78, 16'h5385, 8'h7e};
assign cfg_array[181] = {8'h78, 16'h5386, 8'h88};
assign cfg_array[182] = {8'h78, 16'h5387, 8'h7c};
assign cfg_array[183] = {8'h78, 16'h5388, 8'h6c};
assign cfg_array[184] = {8'h78, 16'h5389, 8'h10};
assign cfg_array[185] = {8'h78, 16'h538a, 8'h01};
assign cfg_array[186] = {8'h78, 16'h538b, 8'h98};
assign cfg_array[187] = {8'h78, 16'h5580, 8'h06};
assign cfg_array[188] = {8'h78, 16'h5583, 8'h40};
assign cfg_array[189] = {8'h78, 16'h5584, 8'h10};  
             
assign cfg_array[190] = {8'h78, 16'h5589, 8'h10};
assign cfg_array[191] = {8'h78, 16'h558a, 8'h00};
assign cfg_array[192] = {8'h78, 16'h558b, 8'hf8};
assign cfg_array[193] = {8'h78, 16'h501d, 8'h40};
assign cfg_array[194] = {8'h78, 16'h5300, 8'h08};
assign cfg_array[195] = {8'h78, 16'h5301, 8'h30};
assign cfg_array[196] = {8'h78, 16'h5302, 8'h10};
assign cfg_array[197] = {8'h78, 16'h5303, 8'h00};
assign cfg_array[198] = {8'h78, 16'h5304, 8'h08};
assign cfg_array[199] = {8'h78, 16'h5305, 8'h30};  
             
assign cfg_array[200] = {8'h78, 16'h5306, 8'h08};
assign cfg_array[201] = {8'h78, 16'h5307, 8'h16};
assign cfg_array[202] = {8'h78, 16'h5309, 8'h08};
assign cfg_array[203] = {8'h78, 16'h530a, 8'h30};
assign cfg_array[204] = {8'h78, 16'h530b, 8'h04};
assign cfg_array[205] = {8'h78, 16'h530c, 8'h06};
assign cfg_array[206] = {8'h78, 16'h5025, 8'h00};
assign cfg_array[207] = {8'h78, 16'h3008, 8'h02};
assign cfg_array[208] = {8'h78, 16'h3035, 8'h11};
assign cfg_array[209] = {8'h78, 16'h3036, 8'h46}; 
            
assign cfg_array[210] = {8'h78, 16'h3c07, 8'h08};
assign cfg_array[211] = {8'h78, 16'h3820, 8'h41};
assign cfg_array[212] = {8'h78, 16'h3821, 8'h07};
assign cfg_array[213] = {8'h78, 16'h3814, 8'h31};
assign cfg_array[214] = {8'h78, 16'h3815, 8'h31};
assign cfg_array[215] = {8'h78, 16'h3800, 8'h00};
assign cfg_array[216] = {8'h78, 16'h3801, 8'h00};
assign cfg_array[217] = {8'h78, 16'h3802, 8'h00};
assign cfg_array[218] = {8'h78, 16'h3803, 8'h04};
assign cfg_array[219] = {8'h78, 16'h3804, 8'h0a};  
           
assign cfg_array[220] = {8'h78, 16'h3805, 8'h3f};
assign cfg_array[221] = {8'h78, 16'h3806, 8'h07};
assign cfg_array[222] = {8'h78, 16'h3807, 8'h9b};
assign cfg_array[223] = {8'h78, 16'h3808, 8'h03};
assign cfg_array[224] = {8'h78, 16'h3809, 8'h20};
assign cfg_array[225] = {8'h78, 16'h380a, 8'h02};
assign cfg_array[226] = {8'h78, 16'h380b, 8'h58};
assign cfg_array[227] = {8'h78, 16'h380c, 8'h07};
assign cfg_array[228] = {8'h78, 16'h380d, 8'h68};
assign cfg_array[229] = {8'h78, 16'h380e, 8'h03}; 
            
assign cfg_array[230] = {8'h78, 16'h380f, 8'hd8};
assign cfg_array[231] = {8'h78, 16'h3813, 8'h06};
assign cfg_array[232] = {8'h78, 16'h3618, 8'h00};
assign cfg_array[233] = {8'h78, 16'h3612, 8'h29};
assign cfg_array[234] = {8'h78, 16'h3709, 8'h52};
assign cfg_array[235] = {8'h78, 16'h370c, 8'h03};
assign cfg_array[236] = {8'h78, 16'h3a02, 8'h17};
assign cfg_array[237] = {8'h78, 16'h3a03, 8'h10};
assign cfg_array[238] = {8'h78, 16'h3a14, 8'h17};
assign cfg_array[239] = {8'h78, 16'h3a15, 8'h10}; 
           
assign cfg_array[240] = {8'h78, 16'h4004, 8'h02};
assign cfg_array[241] = {8'h78, 16'h3002, 8'h1c};
assign cfg_array[242] = {8'h78, 16'h3006, 8'hc3};
assign cfg_array[243] = {8'h78, 16'h4713, 8'h03};
assign cfg_array[244] = {8'h78, 16'h4407, 8'h04};
assign cfg_array[245] = {8'h78, 16'h460b, 8'h35};
assign cfg_array[246] = {8'h78, 16'h460c, 8'h22};
assign cfg_array[247] = {8'h78, 16'h4837, 8'h22};
assign cfg_array[248] = {8'h78, 16'h3824, 8'h02};
assign cfg_array[249] = {8'h78, 16'h5001, 8'ha3}; 
            
assign cfg_array[250] = {8'h78, 16'h3503, 8'h00};
assign cfg_array[251] = {8'h78, 16'h3035, 8'h21};       // PLL     input clock =24Mhz, PCLK =84Mhz
assign cfg_array[252] = {8'h78, 16'h3036, 8'h69};
assign cfg_array[253] = {8'h78, 16'h3c07, 8'h07};
assign cfg_array[254] = {8'h78, 16'h3820, 8'h47};
assign cfg_array[255] = {8'h78, 16'h3821, 8'h07};
assign cfg_array[256] = {8'h78, 16'h3814, 8'h31};
assign cfg_array[257] = {8'h78, 16'h3815, 8'h31};
assign cfg_array[258] = {8'h78, 16'h3800, 8'h00};       // HS
assign cfg_array[259] = {8'h78, 16'h3801, 8'h00};       // HS
             
assign cfg_array[260] = {8'h78, 16'h3802, 8'h00};       // VS
assign cfg_array[261] = {8'h78, 16'h3803, 8'hfa};       // VS
assign cfg_array[262] = {8'h78, 16'h3804, 8'h0a};       // HW (HE)
assign cfg_array[263] = {8'h78, 16'h3805, 8'h3f};       // HW (HE)
assign cfg_array[264] = {8'h78, 16'h3806, 8'h06};       // VH (VE)
assign cfg_array[265] = {8'h78, 16'h3807, 8'ha9};       // VH (VE)
assign cfg_array[266] = {8'h78, 16'h3808, 8'h04};       // DVPHO     (1024)
assign cfg_array[267] = {8'h78, 16'h3809, 8'h00};       // DVPHO     (1024)
assign cfg_array[268] = {8'h78, 16'h380a, 8'h02};       // DVPVO     (720)
assign cfg_array[269] = {8'h78, 16'h380b, 8'hd0};       // DVPVO     (720)
            
assign cfg_array[270] = {8'h78, 16'h380c, 8'h07};       // HTS       (1892)  1892*740*65 = 95334200  /  90994176
assign cfg_array[271] = {8'h78, 16'h380d, 8'h64};       // HTS
assign cfg_array[272] = {8'h78, 16'h380e, 8'h02};       // VTS       (740)
assign cfg_array[273] = {8'h78, 16'h380f, 8'he4};       // VTS
assign cfg_array[274] = {8'h78, 16'h3813, 8'h04};       // timing V offset
assign cfg_array[275] = {8'h78, 16'h3618, 8'h00};
assign cfg_array[276] = {8'h78, 16'h3612, 8'h29};
assign cfg_array[277] = {8'h78, 16'h3709, 8'h52};
assign cfg_array[278] = {8'h78, 16'h370c, 8'h03};
assign cfg_array[279] = {8'h78, 16'h3a02, 8'h02}; 
              
assign cfg_array[280] = {8'h78, 16'h3a03, 8'he0};
assign cfg_array[281] = {8'h78, 16'h3a08, 8'h00};
assign cfg_array[282] = {8'h78, 16'h3a09, 8'h6f};
assign cfg_array[283] = {8'h78, 16'h3a0a, 8'h00};
assign cfg_array[284] = {8'h78, 16'h3a0b, 8'h5c};
assign cfg_array[285] = {8'h78, 16'h3a0e, 8'h06};
assign cfg_array[286] = {8'h78, 16'h3a0d, 8'h08};
assign cfg_array[287] = {8'h78, 16'h3a14, 8'h02};
assign cfg_array[288] = {8'h78, 16'h3a15, 8'he0};
assign cfg_array[289] = {8'h78, 16'h4004, 8'h02}; 
             
assign cfg_array[290] = {8'h78, 16'h3002, 8'h1c};
assign cfg_array[291] = {8'h78, 16'h3006, 8'hc3};
assign cfg_array[292] = {8'h78, 16'h4713, 8'h03};
assign cfg_array[293] = {8'h78, 16'h4407, 8'h04};
assign cfg_array[294] = {8'h78, 16'h460b, 8'h37};
assign cfg_array[295] = {8'h78, 16'h460c, 8'h20};
assign cfg_array[296] = {8'h78, 16'h4837, 8'h16};
assign cfg_array[297] = {8'h78, 16'h3824, 8'h04};       // PCLK manual divider
assign cfg_array[298] = {8'h78, 16'h5001, 8'h83};
assign cfg_array[299] = {8'h78, 16'h3503, 8'h00}; 
           
assign cfg_array[300] = {8'h78, 16'h3016, 8'h02};
assign cfg_array[301] = {8'h78, 16'h3b07, 8'h0a};
assign cfg_array[302] = {8'h78, 16'h3b00, 8'h83};
assign cfg_array[303] = {8'h78, 16'h3b00, 8'h00};

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
	.riic_data			(riic_data	),
	.busy				(busy		)
);

endmodule
