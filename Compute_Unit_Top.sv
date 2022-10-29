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

	,input [`BUS_SIZE-1:0] filter_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] filter_nonzero_data_i
	,input filter_chunk_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] filter_chunk_wr_count_i
	,input filter_chunk_wr_sel_i
	,input filter_chunk_rd_sel_i

	,input run_valid_i
	,input sub_chunk_start_i

`ifdef CHANNEL_STACKING
	,input [$clog2(`PREFIX_SUM_SIZE)-1:0] sparsemap_shift_left_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_first_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_next_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_first_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_last_i
	,input [$clog2(`LAYER_FILTER_SIZE_MAX)-1:0] rd_fil_nonzero_dat_first_i
`endif

	,output sub_chunk_end_o

	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_i

//	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] out_buf_sel_i
	,output [`OUTPUT_BUF_SIZE-1:0] out_buf_dat_o
);

	logic [`OUTPUT_BUF_SIZE-1:0] acc_dat_i_w;
	logic acc_val_o_w;
	logic [`OUTPUT_BUF_SIZE-1:0] acc_dat_o_w;

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
		
		,.filter_sparsemap_i
		,.filter_nonzero_data_i
		,.filter_chunk_wr_valid_i
		,.filter_chunk_wr_count_i
		,.filter_chunk_wr_sel_i
		,.filter_chunk_rd_sel_i
		
		,.run_valid_i
		,.sub_chunk_start_i

`ifdef CHANNEL_STACKING
		,.pri_enc_last_o()
		,.sparsemap_shift_left_i
		,.rd_ifm_sparsemap_first_i
		,.rd_ifm_sparsemap_next_i
		,.rd_fil_sparsemap_first_i
		,.rd_fil_sparsemap_last_i
		,.rd_fil_nonzero_dat_first_i
`endif

		,.sub_chunk_end_o
		
		,.acc_dat_i(acc_dat_i_w)
		,.acc_val_o(acc_val_o_w)
		,.acc_dat_o(acc_dat_o_w)
	);

	Output_Buffer u_Output_Buffer (
		 .rst_i
		,.clk_i

		,.acc_sel_i(acc_buf_sel_i)
		,.acc_val_i(acc_val_o_w)
		,.acc_dat_i(acc_dat_o_w)
		,.acc_dat_o(acc_dat_i_w)

//		,.out_sel_i(out_buf_sel_i)
		,.out_dat_o(out_buf_dat_o)
	);
	
endmodule
