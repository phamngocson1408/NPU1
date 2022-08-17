`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Son N. P.
// 
// Create Date: 07/25/2022 11:55:18 AM
// Design Name: 
// Module Name: Input_Selector
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


module Input_Selector_v2 #(
	 parameter MEM_SIZE = 128	//Bytes
	,parameter BUS_SIZE = 8	//Bytes
	,parameter PREFIX_SUM_SIZE = 8	//bits
)(
	 input rst_i
	,input clk_i
	,input [BUS_SIZE-1:0] ifm_sparsemap_i
	,input [BUS_SIZE*8-1:0] ifm_nonzero_data_i
	,input ifm_wr_valid_i
	,output ifm_wr_ready_o
	,input [BUS_SIZE-1:0] filter_sparsemap_i
	,input [BUS_SIZE*8-1:0] filter_nonzero_data_i
	,input filter_wr_valid_i
	,output filter_wr_ready_o

	,output logic [7:0] ifm_data_o
	,output [7:0] filter_data_o
	,output data_valid_o
	,output chunk_end_o

//	,output [31:0] add_o
);

	logic ifm_rd_ready_w;
	logic filter_rd_ready_w;

	logic [$clog2(PREFIX_SUM_SIZE)-1:0] pri_enc_match_addr_w;
	logic pri_enc_end_w;
	logic [PREFIX_SUM_SIZE-1:0] filter_sparsemap_w;
	logic [PREFIX_SUM_SIZE-1:0] ifm_sparsemap_com_w;

	localparam RD_SPARSEMAP_NUM = MEM_SIZE/PREFIX_SUM_SIZE;

	logic [$clog2(RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_addr_r;


	IFM_Data_Chunk_Top #(
		 .MEM_SIZE(MEM_SIZE)
		,.BUS_SIZE(BUS_SIZE)
		,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
	) u_IFM_Data_Chunk_Top (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i(ifm_sparsemap_i)
		,.wr_nonzero_data_i(ifm_nonzero_data_i)
		,.wr_valid_i(ifm_wr_valid_i)
//		,.refresh_mem_i(refresh_ifm_w[0])
		,.wr_ready_o(ifm_wr_ready_o)

		,.rd_data_o(ifm_data_o)
		,.rd_ready_o(ifm_rd_ready_w)

		,.pri_enc_match_addr_i(pri_enc_match_addr_w)
		,.pri_enc_end_i(pri_enc_end_w)
		,.chunk_end_i(chunk_end_o)

		,.rd_sparsemap_addr_i(rd_sparsemap_addr_r)
		,.rd_sparsemap_o(ifm_sparsemap_com_w)
	);

	Data_Chunk_Top #(
		 .MEM_SIZE(MEM_SIZE)
		,.BUS_SIZE(BUS_SIZE)
		,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
	) u_Data_Chunk_Top_filter (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i(filter_sparsemap_i)
		,.wr_nonzero_data_i(filter_nonzero_data_i)
		,.wr_valid_i(filter_wr_valid_i)
		,.refresh_mem_i(1'b0)
		,.wr_ready_o(filter_wr_ready_o)

		,.rd_data_o(filter_data_o)
		,.rd_ready_o(filter_rd_ready_w)

		,.pri_enc_match_addr_i(pri_enc_match_addr_w)
		,.pri_enc_end_i(pri_enc_end_w)
		,.chunk_end_i(chunk_end_o)

		,.rd_sparsemap_addr_i(rd_sparsemap_addr_r)
		,.rd_sparsemap_o(filter_sparsemap_w)
	);

	Priority_Encoder_Top #(
		.SIZE(PREFIX_SUM_SIZE)
	) u_Priority_Encoder_Top_pro (
		 .rst_i
		,.clk_i
		,.valid_i(ifm_rd_ready_w && filter_rd_ready_w)
		,.in1_i(ifm_sparsemap_com_w)
		,.in2_i(filter_sparsemap_w)
		
		,.valid_o(data_valid_o)
		,.match_addr_o(pri_enc_match_addr_w)
		,.pri_enc_end_o(pri_enc_end_w)
	);

	// Calculate sparsemap addr
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			rd_sparsemap_addr_r <= #1 {($clog2(RD_SPARSEMAP_NUM)){1'b0}};
		end
		else if (chunk_end_o) begin
			rd_sparsemap_addr_r <= #1 {($clog2(RD_SPARSEMAP_NUM)){1'b0}};
		end
		else if (pri_enc_end_w) begin
			rd_sparsemap_addr_r <= #1 rd_sparsemap_addr_r + 1'b1;
		end
	end

	assign chunk_end_o = (rd_sparsemap_addr_r == (RD_SPARSEMAP_NUM-1)) && pri_enc_end_w;

//	logic [15:0] Mul_r;
//	always_ff @(posedge clk_i) begin
//		if (rst_i) begin
//			Mul_r <= #1 16'h0000;	
//		end
//		else if (data_valid_o) begin
//			Mul_r <= #1 ifm_data_o * filter_data_o;
//		end
//	end
//
//	logic [31:0] Add_r;
//	always_ff @(posedge clk_i) begin
//		if (rst_i) begin
//			Add_r <= #1 32'h0000;	
//		end
//		else if (chunk_end_o) begin
//			Add_r <= #1 32'h0000;	
//		end
//		else if (data_valid_o) begin
//			Add_r <= #1 Add_r + Mul_r;
//		end
//	end
//
//	assign add_o = Add_r;	

endmodule
