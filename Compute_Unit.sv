`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/13/2022 02:13:19 PM
// Design Name: 
// Module Name: Compute_Unit
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


module Compute_Unit #(
//	 localparam int `WR_DAT_CYC_NUM = `CHUNK_SIZE/`BUS_SIZE
//	,localparam int `RD_DAT_CYC_NUM = `CHUNK_SIZE/`PREFIX_SUM_SIZE
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
	,output pri_enc_last_o
	,input [$clog2(`PREFIX_SUM_SIZE)-1:0] sparsemap_shift_left_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_first_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_next_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_first_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_last_i
	,input [$clog2(`LAYER_FILTER_SIZE_MAX)-1:0] rd_fil_nonzero_dat_first_i
`endif

	,output sub_chunk_end_o

	,input [`OUTPUT_BUF_SIZE-1:0] acc_dat_i
	,output acc_val_o
	,output [`OUTPUT_BUF_SIZE-1:0] acc_dat_o
);

`ifndef COMB_DAT_CHUNK
	logic [7:0] ifm_data_w;
`endif
	logic [7:0] filter_data_w;
	logic data_valid_w;

	Input_Selector_v2 u_Input_Selector (
		 .rst_i
		,.clk_i
		
`ifdef COMB_DAT_CHUNK
		,.rd_addr_o
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
		,.pri_enc_last_o
		,.sparsemap_shift_left_i
		,.rd_ifm_sparsemap_first_i
		,.rd_ifm_sparsemap_next_i
		,.rd_fil_sparsemap_first_i
		,.rd_fil_sparsemap_last_i
		,.rd_fil_nonzero_dat_first_i
`endif
		
`ifndef COMB_DAT_CHUNK
		,.ifm_data_o(ifm_data_w)
`endif
		,.filter_data_o(filter_data_w)
		,.data_valid_o(data_valid_w)
		,.sub_chunk_end_o
	);

	MAC u_MAC (
		 .rst_i
		,.clk_i
		
`ifdef COMB_DAT_CHUNK
		,.in1_i(rd_data_i)
`else
		,.in1_i(ifm_data_w)
`endif
		,.in2_i(filter_data_w)
		,.valid_i(data_valid_w)
		
		,.acc_dat_i	
		,.acc_val_o
		,.acc_dat_o
	);

endmodule
