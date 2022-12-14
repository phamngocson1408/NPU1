`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2022 12:22:13 PM
// Design Name: 
// Module Name: IFM_Data_Chunk_Top
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


module IFM_Dat_Chunk_Comb_Padding #(
)(
	 input rst_i
	,input clk_i

	,input [`BUS_SIZE-1:0] wr_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] wr_nonzero_data_i 
	,input wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] wr_count_i
	,input wr_sel_i
	,input rd_sel_i

	,input [`COMPUTE_UNIT_NUM-1:0][$clog2(`CHUNK_SIZE):0] rd_addr_i
	,output logic [`COMPUTE_UNIT_NUM-1:0][7:0] rd_data_o

	,input [`COMPUTE_UNIT_NUM-1:0][$clog2(`RD_DAT_CYC_NUM)-1:0] rd_sparsemap_addr_i
	,output logic [`COMPUTE_UNIT_NUM-1:0][`PREFIX_SUM_SIZE-1:0] rd_sparsemap_o	
);
	
	logic [1:0] wr_val_w;
	logic [1:0][`CHUNK_SIZE:1][7:0] rd_nonzero_data_w;
	logic [1:0][`CHUNK_SIZE-1:0] rd_sparsemap_w;

	for (genvar n=0; n<2; n=n+1) begin
		Dat_Chunk_Comb u_Dat_Chunk_Comb (
			 .clk_i
			,.rst_i
			,.wr_sparsemap_i
			,.wr_nonzero_data_i
			,.wr_valid_i(wr_val_w[n])
			,.wr_count_i
	
			,.rd_nonzero_data_o(rd_nonzero_data_w[n])
			,.rd_sparsemap_o(rd_sparsemap_w[n])
		);
	end

	assign wr_val_w[1] =   wr_sel_i  && wr_valid_i;
	assign wr_val_w[0] = (!wr_sel_i) && wr_valid_i;

	// Read Sparsemap
	Dat_Chunk_Comb_Sparsemap u_Dat_Chunk_Comb_Sparsemap (
		 .rd_sel_i
		,.rd_sparsemap_i(rd_sparsemap_w)
		,.rd_sparsemap_addr_i
		,.rd_sparsemap_o	
	);

	// Read Nonzero data
	Dat_Chunk_Comb_Dat u_Dat_Chunk_Comb_Dat (
		 .rd_sel_i
		,.rd_nonzero_data_i(rd_nonzero_data_w)
		,.rd_addr_i
		,.rd_data_o
	);

endmodule
