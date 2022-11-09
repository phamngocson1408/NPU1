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
	,input [1:0] ifm_chunk_rdy_i

	,input fil_chunk_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] fil_chunk_wr_count_i
	,input fil_chunk_wr_sel_i
	,input fil_chunk_rd_sel_i
	,input [`COMPUTE_UNIT_NUM-1:0] fil_chunk_cu_wr_sel_i
	,input [$clog2(`SRAM_FILTER_NUM)-1:0] fil_sram_rd_count_i

	,input run_valid_i

`ifdef CHANNEL_STACKING
	,input inner_loop_start_i
	,input [31:0] ifm_loop_y_idx_i 
	,input [31:0] fil_loop_y_idx_start_i 
	,input [31:0] fil_loop_y_idx_last_i 
	,input [31:0] fil_loop_y_step_i 
	,input [31:0] sub_channel_size_i 
	,output logic total_inner_loop_finish_o
`elsif CHANNEL_PADDING
	,input total_chunk_start_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_last_i
	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_i
	,output total_chunk_end_o
`endif
	,input [$clog2(`COMPUTE_UNIT_NUM)-1:0] com_unit_out_buf_sel_i
	,output [`OUTPUT_BUF_SIZE-1:0] out_buf_dat_o

	,input [`BUS_SIZE-1:0] 		ifm_sram_wr_sparsemap_i
	,input [`BUS_SIZE*8-1:0] 	ifm_sram_wr_nonzero_data_i
	,input 				ifm_sram_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] ifm_sram_wr_dat_count_i
	,input [$clog2(`SRAM_IFM_NUM)-1:0] 	ifm_sram_wr_chunk_count_i

	,input [`BUS_SIZE-1:0] 		fil_sram_wr_sparsemap_i
	,input [`BUS_SIZE*8-1:0] 	fil_sram_wr_nonzero_data_i
	,input 				fil_sram_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] fil_sram_wr_dat_count_i
	,input [$clog2(`SRAM_FILTER_NUM)-1:0] fil_sram_wr_chunk_count_i
);

logic [`BUS_SIZE-1:0] ifm_rd_sparsemap_o_w;
logic [`BUS_SIZE-1:0][7:0] ifm_rd_nonzero_data_o_w;
logic [`BUS_SIZE-1:0] fil_rd_sparsemap_o_w;
logic [`BUS_SIZE-1:0][7:0] fil_rd_nonzero_data_o_w;

Compute_Cluster u_Compute_Cluster (
	 .rst_i
	,.clk_i

	,.ifm_sparsemap_i(ifm_rd_sparsemap_o_w)
	,.ifm_nonzero_data_i(ifm_rd_nonzero_data_o_w)
	,.ifm_chunk_wr_valid_i
	,.ifm_chunk_wr_count_i
	,.ifm_chunk_wr_sel_i
	,.ifm_chunk_rd_sel_i
	,.ifm_chunk_rdy_i

	,.fil_sparsemap_i(fil_rd_sparsemap_o_w)
	,.fil_nonzero_data_i(fil_rd_nonzero_data_o_w)
	,.fil_chunk_wr_valid_i
	,.fil_chunk_wr_count_i
	,.fil_chunk_wr_sel_i
	,.fil_chunk_rd_sel_i
	,.fil_chunk_cu_wr_sel_i

	,.run_valid_i

`ifdef CHANNEL_STACKING
	,.inner_loop_start_i	
	,.ifm_loop_y_idx_i	
	,.fil_loop_y_idx_start_i
	,.fil_loop_y_idx_last_i
	,.fil_loop_y_step_i	
	,.sub_channel_size_i	
	,.total_inner_loop_finish_o
`elsif CHANNEL_PADDING
	,.total_chunk_start_i
	,.rd_fil_sparsemap_last_i
	,.acc_buf_sel_i
	,.total_chunk_end_o
`endif
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

	,.wr_sparsemap_i	(fil_sram_wr_sparsemap_i)
	,.wr_nonzero_data_i	(fil_sram_wr_nonzero_data_i)
	,.wr_valid_i		(fil_sram_wr_valid_i)
	,.wr_dat_count_i	(fil_sram_wr_dat_count_i)
	,.wr_chunk_count_i	(fil_sram_wr_chunk_count_i)

	,.rd_sparsemap_o(fil_rd_sparsemap_o_w)
	,.rd_nonzero_data_o(fil_rd_nonzero_data_o_w)
	,.rd_dat_count_i(fil_chunk_wr_count_i)
	,.rd_chunk_count_i(fil_sram_rd_count_i)
);

endmodule

