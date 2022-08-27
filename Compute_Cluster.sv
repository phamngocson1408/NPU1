`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2022 04:09:32 PM
// Design Name: 
// Module Name: Compute_Cluster
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


module Compute_Cluster #(
	 parameter MEM_SIZE = 128	//Bytes
	,parameter BUS_SIZE = 8	//Bytes
	,parameter PREFIX_SUM_SIZE = 8	//bits
	,parameter OUTPUT_BUF_SIZE = 32 // bits
	,parameter OUTPUT_BUF_NUM = 32
	,parameter COMPUTE_UNIT_NUM = 32
)(
	 input rst_i
	,input clk_i

	,input [BUS_SIZE-1:0] ifm_sparsemap_i
	,input [BUS_SIZE*8-1:0] ifm_nonzero_data_i
	,input ifm_wr_valid_i
	,input [$clog2(MEM_SIZE/BUS_SIZE)-1:0] ifm_wr_count_i
	,input ifm_wr_sel_i
	,input ifm_rd_sel_i

	,input [BUS_SIZE-1:0] filter_sparsemap_i
	,input [BUS_SIZE*8-1:0] filter_nonzero_data_i
	,input filter_wr_valid_i
	,input [$clog2(MEM_SIZE/BUS_SIZE)-1:0] filter_wr_count_i
	,input filter_wr_sel_i
	,input filter_rd_sel_i
	,input [$clog2(OUTPUT_BUF_NUM)-1:0] filter_wr_order_sel_i

	,input init_i
	,input chunk_start_i

	,output chunk_end_o

	,input [$clog2(OUTPUT_BUF_NUM)-1:0] acc_buf_sel_i

	,input [$clog2(OUTPUT_BUF_NUM)-1:0] out_buf_sel_i
	,input [$clog2(COMPUTE_UNIT_NUM)-1:0] com_unit_out_buf_sel_i
	,output [OUTPUT_BUF_SIZE-1:0] out_buf_dat_o
);

	logic [COMPUTE_UNIT_NUM-1:0] ifm_wr_ready_w;
	logic [COMPUTE_UNIT_NUM-1:0] filter_wr_valid_w;
	logic [COMPUTE_UNIT_NUM-1:0] filter_wr_ready_w;
	logic [COMPUTE_UNIT_NUM-1:0] chunk_end_w;
	logic [COMPUTE_UNIT_NUM-1:0][OUTPUT_BUF_SIZE-1:0] out_buf_dat_w;

	genvar i;
	for (i=0; i<COMPUTE_UNIT_NUM; i=i+1) begin: gen_com_unit
		Compute_Unit_Top #(
			 .MEM_SIZE(MEM_SIZE)
			,.BUS_SIZE(BUS_SIZE)
			,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
			,.OUTPUT_BUF_SIZE(OUTPUT_BUF_SIZE)
			,.OUTPUT_BUF_NUM(OUTPUT_BUF_NUM)
		) u_Compute_Unit_Top (
			 .rst_i
			,.clk_i

			,.ifm_sparsemap_i
			,.ifm_nonzero_data_i
			,.ifm_wr_valid_i
			,.ifm_wr_count_i
			,.ifm_wr_sel_i
			,.ifm_rd_sel_i

			,.filter_sparsemap_i
			,.filter_nonzero_data_i
			,.filter_wr_valid_i(filter_wr_valid_w[i])
			,.filter_wr_count_i
			,.filter_wr_sel_i
			,.filter_rd_sel_i

			,.init_i
			,.chunk_start_i

			,.chunk_end_o(chunk_end_w[i])

			,.acc_buf_sel_i

			,.out_buf_sel_i
			,.out_buf_dat_o(out_buf_dat_w[i])
		);
	end

	for (i=0; i<COMPUTE_UNIT_NUM; i=i+1) begin
		assign filter_wr_valid_w[i] = (filter_wr_order_sel_i == i) ? filter_wr_valid_i : 0;
	end

	assign chunk_end_o = &chunk_end_w;
	assign out_buf_dat_o = out_buf_dat_w[com_unit_out_buf_sel_i];

endmodule
