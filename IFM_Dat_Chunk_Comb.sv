`timescale 1ns / 1ps
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


module IFM_Dat_Chunk_Comb #(
	 parameter MEM_SIZE = 128	//Bytes
	,parameter BUS_SIZE = 16	//Bytes
	,parameter PREFIX_SUM_SIZE = 8	//bits
	,parameter COMPUTE_UNIT_NUM = 32
)(
	 input rst_i
	,input clk_i

	,input [BUS_SIZE-1:0] wr_sparsemap_i
	,input [BUS_SIZE-1:0][7:0] wr_nonzero_data_i 
	,input wr_valid_i
	,input [$clog2(MEM_SIZE/BUS_SIZE)-1:0] wr_count_i
	,input wr_sel_i
	,input rd_sel_i

	,input [COMPUTE_UNIT_NUM-1:0][$clog2(MEM_SIZE):0] rd_addr_i
	,output [COMPUTE_UNIT_NUM-1:0][7:0] rd_data_o

	,input [COMPUTE_UNIT_NUM-1:0][$clog2(MEM_SIZE/PREFIX_SUM_SIZE)-1:0] rd_sparsemap_addr_i
	,output logic [COMPUTE_UNIT_NUM-1:0][PREFIX_SUM_SIZE-1:0] rd_sparsemap_o	
);
	
	logic [1:0] wr_val_w;
	logic [$clog2(MEM_SIZE):0] rd_dat_addr_w;	
	logic [1:0][MEM_SIZE:1][7:0] rd_nonzero_data_w;
	logic [MEM_SIZE:1][7:0] rd_nonzero_data_comb_w;
	logic [1:0][MEM_SIZE-1:0] rd_sparsemap_w;
	logic [MEM_SIZE-1:0] rd_sparsemap_comb_w;

	logic [$clog2(PREFIX_SUM_SIZE):0] prefix_sum_out_w [PREFIX_SUM_SIZE-1:0];

	logic [$clog2(MEM_SIZE):0] rd_data_base_addr_r;	
	logic [$clog2(PREFIX_SUM_SIZE):0] rd_data_addr_temp_w;	

	Dat_Chunk_Comb #(
		 .MEM_SIZE(MEM_SIZE)
		,.BUS_SIZE(BUS_SIZE)
		,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
	) u_Dat_Chunk_Comb_0 (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i
		,.wr_nonzero_data_i
		,.wr_valid_i(wr_val_w[0])
		,.wr_count_i

		,.rd_nonzero_data_o(rd_nonzero_data_w[0])
		,.rd_sparsemap_o(rd_sparsemap_w[0])
	);

	Dat_Chunk_Comb #(
		 .MEM_SIZE(MEM_SIZE)
		,.BUS_SIZE(BUS_SIZE)
		,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
	) u_Dat_Chunk_Comb_1 (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i
		,.wr_nonzero_data_i
		,.wr_valid_i(wr_val_w[1])
		,.wr_count_i

		,.rd_nonzero_data_o(rd_nonzero_data_w[1])
		,.rd_sparsemap_o(rd_sparsemap_w[1])
	);

	assign wr_val_w[1] =   wr_sel_i  && wr_valid_i;
	assign wr_val_w[0] = (!wr_sel_i) && wr_valid_i;

	always_comb begin
		if (rd_sel_i) begin
			rd_nonzero_data_comb_w 	= rd_nonzero_data_w[1];
			rd_sparsemap_comb_w 	= rd_sparsemap_w[1];
		end
		else begin
			rd_nonzero_data_comb_w	= rd_nonzero_data_w[0];
			rd_sparsemap_comb_w 	= rd_sparsemap_w[0];
		end
	end

	// Read Sparsemap
	always_comb begin
		for (integer k=0; k< COMPUTE_UNIT_NUM; k=k+1) begin
			rd_sparsemap_o[k] = {PREFIX_SUM_SIZE{1'b0}};
			for (integer i=0; i<(MEM_SIZE/PREFIX_SUM_SIZE); i = i+1) begin
				if (rd_sparsemap_addr_i[k] == i)
					rd_sparsemap_o[k] = rd_sparsemap_comb_w[PREFIX_SUM_SIZE*i +: PREFIX_SUM_SIZE];
			end
		end
	end

	// Read Nonzero data
	genvar k;
	for (k=0; k< COMPUTE_UNIT_NUM; k=k+1) begin
		assign rd_data_o[k] = rd_nonzero_data_comb_w[rd_addr_i[k]];
	end

endmodule
