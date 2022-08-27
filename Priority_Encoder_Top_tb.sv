`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2022 03:09:34 PM
// Design Name: 
// Module Name: Priority_Encoder_Top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Priority_Encoder_Top_tb;
	
parameter SIZE = 8;
parameter cyc = 10;

//CLock generate
reg CLK;
initial begin
	CLK=0;
	#(cyc/2);
	while (1) begin
		CLK = ~CLK;
		#(cyc/2);
	end
end

//Reset generate
reg RESET;
initial begin
	RESET = 1;
	#(cyc*50);
	RESET = 0;
end

//Instance
logic valid_r;
logic [SIZE-1:0] in1_r, in2_r;
logic valid_o;
logic [$clog2(SIZE)-1:0] match_addr_o;
logic pri_enc_last_o;

Priority_Encoder_Top #(
	.SIZE(SIZE)
) u_Priority_Encoder_Top (
	 .rst_i(RESET)
	,.clk_i(CLK)
	,.valid_i(valid_r)
	,.in1_i(in1_r)
	,.in2_i(in2_r)

	,.valid_o
	,.match_addr_o
	,.pri_enc_last_o
);

//Stimulate
initial begin
	valid_r = 0;
	in1_r = $urandom_range(2**SIZE,2**(SIZE-1));
	in2_r = $urandom_range(2**SIZE,2**(SIZE-1));

	@(posedge(!RESET && CLK))
	valid_r = 1;

	#(cyc*1000);
	$finish;
end

always @(posedge CLK) begin
	if (pri_enc_last_o) begin
		in1_r = $urandom_range(2**SIZE,2**(SIZE-1));
		in2_r = $urandom_range(2**SIZE,2**(SIZE-1));
	end
end

endmodule
