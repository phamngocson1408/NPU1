`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2022 04:09:32 PM
// Design Name: 
// Module Name: Compute_Cluster_Mem
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


module Compute_Cluster_Mem #(
)(
	 input rst_i
	,input clk_i

	,input ifm_chunk_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] ifm_chunk_wr_count_i
	,input ifm_chunk_wr_sel_i
	,input ifm_chunk_rd_sel_i
	,input [$clog2(`SRAM_IFM_NUM)-1:0] ifm_sram_rd_count_i

	,input filter_chunk_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] filter_chunk_wr_count_i
	,input filter_chunk_wr_sel_i
	,input filter_chunk_rd_sel_i
	,input [`COMPUTE_UNIT_NUM-1:0] filter_chunk_cu_wr_sel_i
	,input [$clog2(`SRAM_FILTER_NUM)-1:0] filter_sram_rd_count_i

	,input run_valid_i
	,input total_chunk_start_i

`ifdef CHANNEL_STACKING
	,input [$clog2(`PREFIX_SUM_SIZE)-1:0] sparsemap_shift_left_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_first_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_next_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_first_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_last_i
	,input [$clog2(`LAYER_FILTER_SIZE_MAX)-1:0] rd_fil_nonzero_dat_first_i
`endif
	,output total_chunk_end_o

	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_i

//	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] out_buf_sel_i
	,input [$clog2(`COMPUTE_UNIT_NUM)-1:0] com_unit_out_buf_sel_i
	,output [`OUTPUT_BUF_SIZE-1:0] out_buf_dat_o

	,input [`BUS_SIZE-1:0] 		ifm_sram_wr_sparsemap_i
	,input [`BUS_SIZE*8-1:0] 	ifm_sram_wr_nonzero_data_i
	,input 				ifm_sram_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] ifm_sram_wr_dat_count_i
	,input [$clog2(`SRAM_IFM_NUM)-1:0] 	ifm_sram_wr_chunk_count_i

	,input [`BUS_SIZE-1:0] 		filter_sram_wr_sparsemap_i
	,input [`BUS_SIZE*8-1:0] 	filter_sram_wr_nonzero_data_i
	,input 				filter_sram_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] filter_sram_wr_dat_count_i
	,input [$clog2(`SRAM_FILTER_NUM)-1:0] filter_sram_wr_chunk_count_i

);

logic [`BUS_SIZE-1:0] ifm_rd_sparsemap_o_w;
logic [`BUS_SIZE-1:0][7:0] ifm_rd_nonzero_data_o_w;
logic [`BUS_SIZE-1:0] filter_rd_sparsemap_o_w;
logic [`BUS_SIZE-1:0][7:0] filter_rd_nonzero_data_o_w;

Compute_Cluster u_Compute_Cluster (
	 .rst_i
	,.clk_i

	,.ifm_sparsemap_i(ifm_rd_sparsemap_o_w)
	,.ifm_nonzero_data_i(ifm_rd_nonzero_data_o_w)
	,.ifm_chunk_wr_valid_i
	,.ifm_chunk_wr_count_i
	,.ifm_chunk_wr_sel_i
	,.ifm_chunk_rd_sel_i

	,.filter_sparsemap_i(filter_rd_sparsemap_o_w)
	,.filter_nonzero_data_i(filter_rd_nonzero_data_o_w)
	,.filter_chunk_wr_valid_i
	,.filter_chunk_wr_count_i
	,.filter_chunk_wr_sel_i
	,.filter_chunk_rd_sel_i
	,.filter_chunk_cu_wr_sel_i

	,.run_valid_i
	,.total_chunk_start_i

`ifdef CHANNEL_STACKING
	,.sparsemap_shift_left_i
	,.rd_ifm_sparsemap_first_i
	,.rd_ifm_sparsemap_next_i
	,.rd_fil_sparsemap_first_i
	,.rd_fil_sparsemap_last_i
	,.rd_fil_nonzero_dat_first_i
`endif
	,.total_chunk_end_o

	,.acc_buf_sel_i
//	,.out_buf_sel_i
	,.com_unit_out_buf_sel_i
	,.out_buf_dat_o
);

Mem_IFM u_Mem_IFM (
	 .rst_i
	,.clk_i

	,.wr_sparsemap_i	(ifm_sram_wr_sparsemap_i)
	,.wr_nonzero_data_i	(ifm_sram_wr_nonzero_data_i)
	,.wr_valid_i		(ifm_sram_wr_valid_i)
	,.wr_dat_count_i	(ifm_sram_wr_dat_count_i)
	,.wr_chunk_count_i	(ifm_sram_wr_chunk_count_i)

	,.rd_sparsemap_o(ifm_rd_sparsemap_o_w)
	,.rd_nonzero_data_o(ifm_rd_nonzero_data_o_w)
	,.rd_dat_count_i(ifm_chunk_wr_count_i)
	,.rd_chunk_count_i(ifm_sram_rd_count_i)
);

Mem_Filter u_Mem_Filter (
	 .rst_i
	,.clk_i

	,.wr_sparsemap_i	(filter_sram_wr_sparsemap_i)
	,.wr_nonzero_data_i	(filter_sram_wr_nonzero_data_i)
	,.wr_valid_i		(filter_sram_wr_valid_i)
	,.wr_dat_count_i	(filter_sram_wr_dat_count_i)
	,.wr_chunk_count_i	(filter_sram_wr_chunk_count_i)

	,.rd_sparsemap_o(filter_rd_sparsemap_o_w)
	,.rd_nonzero_data_o(filter_rd_nonzero_data_o_w)
	,.rd_dat_count_i(filter_chunk_wr_count_i)
	,.rd_chunk_count_i(filter_sram_rd_count_i)
);

endmodule

