`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Son N. P. 
// 
// Create Date: 07/24/2022 06:13:42 PM
// Design Name: 
// Module Name: Data_Chunk_Top
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


module Data_Chunk_Top #(
	 parameter MEM_SIZE = 128	//Bytes
	,parameter BUS_SIZE = 16	//Bytes
	,parameter PREFIX_SUM_SIZE = 8	//bits
)(
	 input rst_i
	,input clk_i
	,input [BUS_SIZE-1:0] wr_sparsemap_i
	,input [BUS_SIZE-1:0][7:0] wr_nonzero_data_i 
	,input wr_valid_i
	,input refresh_mem_i
	,output wr_ready_o

	,output [7:0] rd_data_o
	,output rd_ready_o

	,input  [$clog2(PREFIX_SUM_SIZE)-1:0] pri_enc_match_addr_i
	,input pri_enc_end_i
	,input chunk_end_i

	,input [$clog2(MEM_SIZE/PREFIX_SUM_SIZE)-1:0] rd_sparsemap_addr_i
	,output logic [PREFIX_SUM_SIZE-1:0] rd_sparsemap_o
);

	logic [$clog2(PREFIX_SUM_SIZE):0] prefix_sum_out_w [PREFIX_SUM_SIZE-1:0];

	logic [$clog2(MEM_SIZE):0] rd_data_base_addr_r;	
	logic [$clog2(PREFIX_SUM_SIZE):0] rd_data_addr_temp_w;	
	logic [$clog2(MEM_SIZE):0] rd_data_addr_w;	

	Data_Chunk #(
		 .MEM_SIZE(MEM_SIZE)
		,.BUS_SIZE(BUS_SIZE)
		,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
	) u_Data_Chunk (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i
		,.wr_nonzero_data_i
		,.wr_valid_i
		,.refresh_mem_i
		,.wr_ready_o

		,.rd_addr_i(rd_data_addr_w)
		,.rd_data_o
		,.rd_ready_o

		,.rd_sparsemap_addr_i
		,.rd_sparsemap_o
	);

	Prefix_Sum_v4 #(
		.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
	) u_Prefix_Sum (
		.in_i(rd_sparsemap_o)
		,.out_o(prefix_sum_out_w)
	);


	always_ff @(posedge clk_i) begin
		if (rst_i || refresh_mem_i) begin
			rd_data_base_addr_r <= #1 {($clog2(MEM_SIZE) + 1){1'b0}};
		end
		else if (chunk_end_i) begin
			rd_data_base_addr_r <= #1 {($clog2(MEM_SIZE) + 1){1'b0}};
		end
		else if (pri_enc_end_i) begin
			rd_data_base_addr_r <= #1 rd_data_base_addr_r + prefix_sum_out_w[PREFIX_SUM_SIZE-1];
		end
	end

	assign rd_data_addr_temp_w = prefix_sum_out_w[pri_enc_match_addr_i];
	assign rd_data_addr_w = rd_data_base_addr_r + rd_data_addr_temp_w;

endmodule

