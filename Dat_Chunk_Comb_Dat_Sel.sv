`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2022 12:24:22 AM
// Design Name: 
// Module Name: Dat_Chunk_Comb_Dat_Sel
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


module Dat_Chunk_Comb_Dat_Sel(
	 input [`MEM_SIZE:1][7:0] rd_nonzero_data_i
	,input [`COMPUTE_UNIT_NUM-1:0][$clog2(`MEM_SIZE):0] rd_addr_i
	,output logic [`COMPUTE_UNIT_NUM-1:0][7:0] rd_data_o
    );

	always_comb begin
		for (integer j=0; j<`COMPUTE_UNIT_NUM; j=j+1) begin
			rd_data_o[j] = rd_nonzero_data_i[rd_addr_i[j]];
		end
	end
endmodule
