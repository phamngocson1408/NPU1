`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2022 05:39:01 PM
// Design Name: 
// Module Name: Priority_Encoder
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


module Priority_Encoder_v2 #(
	parameter SIZE = 128
)(
	 input [SIZE-1:0] in_i
	,output logic [$clog2(SIZE):0] out_o
);
	integer i,j;

	always_comb begin
		out_o = SIZE;

		for (i=0; i<SIZE; i=i+1) begin
			j = SIZE-1-i;
			if ((in_i << j) == (1'b1 << SIZE-1)) out_o = i;
		end
	end

endmodule
