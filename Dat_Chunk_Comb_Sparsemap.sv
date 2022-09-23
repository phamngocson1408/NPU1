`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2022 07:24:03 PM
// Design Name: 
// Module Name: Dat_Chunk_Comb_Sparsemap
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


module Dat_Chunk_Comb_Sparsemap #(
	localparam int PARAM_RD_SPARSEMAP_NUM = `MEM_SIZE/`PREFIX_SUM_SIZE
)(
	 input rd_sel_i
	,input [1:0][`MEM_SIZE-1:0] rd_sparsemap_i
	,input [`COMPUTE_UNIT_NUM-1:0][$clog2(PARAM_RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_addr_i
	,output logic [`COMPUTE_UNIT_NUM-1:0][`PREFIX_SUM_SIZE-1:0] rd_sparsemap_o	
    );

	logic [1:0][`COMPUTE_UNIT_NUM-1:0][$clog2(PARAM_RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_addr_w;
	logic [1:0][`COMPUTE_UNIT_NUM-1:0][`PREFIX_SUM_SIZE-1:0] rd_sparsemap_o_w;

	// Read Sparsemap
	always_comb begin
		for (integer j=0; j< `COMPUTE_UNIT_NUM; j=j+1) begin
			if (rd_sel_i) begin
				rd_sparsemap_addr_w[1][j] = rd_sparsemap_addr_i[j];
				rd_sparsemap_addr_w[0][j] = {$clog2(PARAM_RD_SPARSEMAP_NUM){1'b0}};
			end
			else begin
				rd_sparsemap_addr_w[1][j] = {$clog2(PARAM_RD_SPARSEMAP_NUM){1'b0}};
				rd_sparsemap_addr_w[0][j] = rd_sparsemap_addr_i[j];
			end
		end
	end

	always_comb begin
		for (integer i=0; i<2; i=i+1) begin
			for (integer j=0; j< `COMPUTE_UNIT_NUM; j=j+1) begin
				rd_sparsemap_o_w[i][j] = {`PREFIX_SUM_SIZE{1'b0}};
				for (integer k=0; k<PARAM_RD_SPARSEMAP_NUM; k = k+1) begin
					if (rd_sparsemap_addr_w[i][j] == k)
						rd_sparsemap_o_w[i][j] = rd_sparsemap_i[i][`PREFIX_SUM_SIZE*k +: `PREFIX_SUM_SIZE];
				end
			end
		end
	end

	always_comb begin
		for (integer i=0; i<`COMPUTE_UNIT_NUM; i=i+1) begin
			if (rd_sel_i)
				rd_sparsemap_o[i] = rd_sparsemap_o_w[1][i];
			else
				rd_sparsemap_o[i] = rd_sparsemap_o_w[0][i];
		end
	end
endmodule
