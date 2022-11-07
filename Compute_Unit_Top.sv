`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2022 01:04:54 PM
// Design Name: 
// Module Name: Compute_Unit_Top
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


module Compute_Unit_Top #(
)(
	 input rst_i
	,input clk_i
	,input [1:0] ifm_chunk_rdy_i

`ifdef COMB_DAT_CHUNK
	,output [$clog2(`CHUNK_SIZE):0] rd_addr_o
	,input [7:0] rd_data_i
	,output [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_sparsemap_addr_o
	,input [`PREFIX_SUM_SIZE-1:0] rd_sparsemap_i	
`else
        ,input [`BUS_SIZE-1:0] ifm_sparsemap_i
        ,input [`BUS_SIZE-1:0][7:0] ifm_nonzero_data_i
        ,input ifm_chunk_wr_valid_i
        ,input [$clog2(`WR_DAT_CYC_NUM)-1:0] ifm_chunk_wr_count_i
        ,input ifm_chunk_wr_sel_i
        ,input ifm_chunk_rd_sel_i	
`endif

	,input [`BUS_SIZE-1:0] fil_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] fil_nonzero_data_i
	,input fil_chunk_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] fil_chunk_wr_count_i
	,input fil_chunk_wr_sel_i
	,input fil_chunk_rd_sel_i

	,input run_valid_i

`ifdef CHANNEL_STACKING
	,input inner_loop_start_i
	,input [31:0] ifm_loop_y_idx_i
	,input [31:0] fil_loop_y_idx_start_i 
	,input [31:0] fil_loop_y_idx_last_i 
	,input [31:0] fil_loop_y_step_i 
	,input [31:0] sub_channel_size_i 
	,output logic inner_loop_finish_o
	,output logic [$clog2(`PREFIX_SUM_SIZE)-1:0] sparsemap_shift_left_o
	,output ifm_chunk_rd_sel_o
`elsif CHANNEL_PADDING
	,input sub_chunk_start_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_last_i
	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_i
`endif
	,output sub_chunk_end_o

	,output [`OUTPUT_BUF_SIZE-1:0] out_buf_dat_o
);

	logic [`OUTPUT_BUF_SIZE-1:0] acc_dat_i_w;
	logic acc_val_o_w;
	logic [`OUTPUT_BUF_SIZE-1:0] acc_dat_o_w;

`ifdef CHANNEL_STACKING
	logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_first_w;
	logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_last_w;
	logic [$clog2(`LAYER_FILTER_SIZE_MAX)-1:0] rd_fil_nonzero_dat_first_w;
	logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_first_w;
	logic [$clog2(`PREFIX_SUM_SIZE)-1:0] sparsemap_shift_left_w;
	logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_next_w;
	logic [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_w;
	logic sub_chunk_start_w;
`endif

	Compute_Unit u_Compute_Unit (
		 .rst_i
		,.clk_i
		
`ifdef COMB_DAT_CHUNK
		,.rd_addr_o
		,.rd_data_i
		,.rd_sparsemap_addr_o
		,.rd_sparsemap_i
`else
		,.ifm_sparsemap_i
		,.ifm_nonzero_data_i
		,.ifm_chunk_wr_valid_i
		,.ifm_chunk_wr_count_i
		,.ifm_chunk_wr_sel_i
		,.ifm_chunk_rd_sel_i
`endif
		
		,.fil_sparsemap_i
		,.fil_nonzero_data_i
		,.fil_chunk_wr_valid_i
		,.fil_chunk_wr_count_i
		,.fil_chunk_wr_sel_i
		,.fil_chunk_rd_sel_i
		
		,.run_valid_i

`ifdef CHANNEL_STACKING
		,.sub_chunk_start_i (sub_chunk_start_w)
		,.pri_enc_last_o()
		,.sparsemap_shift_left_i	(sparsemap_shift_left_o)
		,.rd_ifm_sparsemap_first_i	(rd_ifm_sparsemap_first_w)
		,.rd_ifm_sparsemap_next_i	(rd_ifm_sparsemap_next_w)
		,.rd_fil_sparsemap_first_i	(rd_fil_sparsemap_first_w)
		,.rd_fil_nonzero_dat_first_i	(rd_fil_nonzero_dat_first_w)
		,.rd_fil_sparsemap_last_i	(rd_fil_sparsemap_last_w)
`elsif CHANNEL_PADDING
		,.sub_chunk_start_i
		,.rd_fil_sparsemap_last_i
`endif
		,.sub_chunk_end_o
		
		,.acc_dat_i(acc_dat_i_w)
		,.acc_val_o(acc_val_o_w)
		,.acc_dat_o(acc_dat_o_w)
	);

	Output_Buffer u_Output_Buffer (
		 .rst_i
		,.clk_i

`ifdef CHANNEL_STACKING
		,.acc_sel_i(acc_buf_sel_w)
`elsif CHANNEL_PADDING
		,.acc_sel_i(acc_buf_sel_i)
`endif
		,.acc_val_i(acc_val_o_w)
		,.acc_dat_i(acc_dat_o_w)
		,.acc_dat_o(acc_dat_i_w)

		,.out_dat_o(out_buf_dat_o)
	);

`ifdef CHANNEL_STACKING
Stacking_Inner_Loop u_Stacking_Inner_Loop(
		 .clk_i

		,.inner_loop_start_i	
		,.sub_chunk_end_i	(sub_chunk_end_o)
		,.ifm_loop_y_idx_i
		,.fil_loop_y_idx_start_i
		,.fil_loop_y_idx_last_i	
		,.fil_loop_y_step_i	
		,.sub_channel_size_i	
		,.ifm_chunk_rdy_i
		
		
		,.rd_fil_sparsemap_first_o	(rd_fil_sparsemap_first_w)
		,.rd_fil_sparsemap_last_o	(rd_fil_sparsemap_last_w)
		,.rd_fil_nonzero_dat_first_o	(rd_fil_nonzero_dat_first_w)
		,.rd_ifm_sparsemap_first_o	(rd_ifm_sparsemap_first_w)
		,.sparsemap_shift_left_o	
		,.rd_ifm_sparsemap_next_o	(rd_ifm_sparsemap_next_w)
		,.acc_buf_sel_o			(acc_buf_sel_w)
		,.inner_loop_finish_o
		,.sub_chunk_start_o		(sub_chunk_start_w)
		,.ifm_chunk_rd_sel_o
	);
`endif
	
endmodule
