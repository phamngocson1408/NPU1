`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2022 07:38:45 PM
// Design Name: 
// Module Name: Dat_Chunk_Comb_Dat
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


module Dat_Chunk_Comb_Dat(
	 input rd_sel_i
	,input [1:0][`MEM_SIZE:1][7:0] rd_nonzero_data_i
	,input [`COMPUTE_UNIT_NUM-1:0][$clog2(`MEM_SIZE):0] rd_addr_i
	,output logic [`COMPUTE_UNIT_NUM-1:0][7:0] rd_data_o
    );
	logic [1:0][`COMPUTE_UNIT_NUM-1:0][$clog2(`MEM_SIZE):0] rd_addr_w;
	logic [1:0][`COMPUTE_UNIT_NUM-1:0][7:0] rd_data_w;

	// Read Nonzero data
	always_comb begin
		for (integer j=0; j< `COMPUTE_UNIT_NUM; j=j+1) begin
			if (rd_sel_i) begin
				rd_addr_w[1][j] = rd_addr_i[j];
				rd_addr_w[0][j] = {{$clog2(`MEM_SIZE){1'b0}},1'b1};
			end
			else begin
				rd_addr_w[1][j] = {{$clog2(`MEM_SIZE){1'b0}},1'b1};
				rd_addr_w[0][j] = rd_addr_i[j];
			end
//			rd_addr_w[1][j] = rd_addr_i[j] &  {($clog2(`MEM_SIZE)+1){rd_sel_i}};
//			rd_addr_w[0][j] = rd_addr_i[j] &  {($clog2(`MEM_SIZE)+1){!rd_sel_i}};
		end
	end

//	always_comb begin
//		for (integer i=0; i<2; i=i+1) begin
//			for (integer j=0; j<`COMPUTE_UNIT_NUM; j=j+1) begin
//				for (integer k=1; k<`MEM_SIZE+1; k=k+1) begin
//					if (rd_addr_w[i][j] == k)
//						rd_data_w[i][j] = rd_nonzero_data_i[i][k];
//				end
//			end
//		end
//	end

//	always_comb begin
//		for (integer i=0; i<2; i=i+1) begin
//			for (integer j=0; j<`COMPUTE_UNIT_NUM; j=j+1) begin
////				rd_data_w[i][j] = rd_nonzero_data_i[i][rd_addr_w[i][j]];
//				rd_data_w[i][j] = rd_nonzero_data_i[i][rd_addr_i[j]];
//			end
//		end
//	end

	for (genvar k=0; k<2; k=k+1) begin
		Dat_Chunk_Comb_Dat_Sel u_Dat_Chunk_Comb_Dat_Sel(
			 .rd_nonzero_data_i(rd_nonzero_data_i[k])
			,.rd_addr_i(rd_addr_w[k])
			,.rd_data_o(rd_data_w[k])
		);
	end

	always_comb begin
		for (integer i=0; i<`COMPUTE_UNIT_NUM; i=i+1) begin
			if (rd_sel_i)
				rd_data_o[i] = rd_data_w[1][i];
			else
				rd_data_o[i] = rd_data_w[0][i];
		end
	end
endmodule
