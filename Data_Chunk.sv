`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2022 06:03:16 PM
// Design Name: 
// Module Name: Data_Chunk
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


module Data_Chunk #(
)(
	 input rst_i
	,input clk_i
	,input [`BUS_SIZE-1:0] wr_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] wr_nonzero_data_i 	//Bandwidth = 128 Bytes
	,input wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] wr_count_i

	,input [$clog2(`CHUNK_SIZE):0] rd_addr_i
	,output [7:0] rd_data_o

	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_sparsemap_addr_i
	,output logic [`PREFIX_SUM_SIZE-1:0] rd_sparsemap_o	
);
	
Data_Chunk_Data u_Data_Chunk_Data (
	 .rst_i
	,.clk_i
	,.wr_nonzero_data_i 
	,.wr_valid_i
	,.wr_count_i

	,.rd_addr_i
	,.rd_data_o
);

Data_Chunk_Sparsemap u_Data_Chunk_Sparsemap (
	 .rst_i
	,.clk_i
	,.wr_sparsemap_i
	,.wr_valid_i
	,.wr_count_i


	,.rd_sparsemap_addr_i
	,.rd_sparsemap_o	
);

endmodule
