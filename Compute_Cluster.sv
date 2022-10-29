`include "Global_Include.vh"
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
)(
	 input rst_i
	,input clk_i

	,input [`BUS_SIZE-1:0] ifm_sparsemap_i
	,input [`BUS_SIZE*8-1:0] ifm_nonzero_data_i
	,input ifm_chunk_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] ifm_chunk_wr_count_i
	,input ifm_chunk_wr_sel_i
	,input ifm_chunk_rd_sel_i

	,input [`BUS_SIZE-1:0] filter_sparsemap_i
	,input [`BUS_SIZE*8-1:0] filter_nonzero_data_i
	,input filter_chunk_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] filter_chunk_wr_count_i
	,input filter_chunk_wr_sel_i
	,input filter_chunk_rd_sel_i
	,input [`COMPUTE_UNIT_NUM-1:0] filter_chunk_cu_wr_sel_i

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
);

	logic [`COMPUTE_UNIT_NUM-1:0] filter_wr_valid_w;
	logic [`COMPUTE_UNIT_NUM-1:0] chunk_end_w;
	logic [`COMPUTE_UNIT_NUM-1:0][`OUTPUT_BUF_SIZE-1:0] out_buf_dat_w;

`ifdef COMB_DAT_CHUNK
	logic [`COMPUTE_UNIT_NUM-1:0][$clog2(`CHUNK_SIZE):0] rd_addr_w;
	logic [`COMPUTE_UNIT_NUM-1:0][7:0] rd_data_w;
	logic [`COMPUTE_UNIT_NUM-1:0][$clog2(`RD_DAT_CYC_NUM)-1:0] rd_sparsemap_addr_w;
	logic [`COMPUTE_UNIT_NUM-1:0][`PREFIX_SUM_SIZE-1:0] rd_sparsemap_w;
`endif

`ifdef CHANNEL_STACKING
       logic [`COMPUTE_UNIT_NUM-1:0] pri_enc_last_w;
`endif

	genvar i;
	for (i=0; i<`COMPUTE_UNIT_NUM; i=i+1) begin: gen_com_unit
		Compute_Unit_Top u_Compute_Unit_Top (
			 .rst_i
			,.clk_i

`ifdef COMB_DAT_CHUNK
			,.rd_addr_o(rd_addr_w[i])
			,.rd_data_i(rd_data_w[i])
			,.rd_sparsemap_addr_o(rd_sparsemap_addr_w[i])
			,.rd_sparsemap_i(rd_sparsemap_w[i])
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
			,.filter_chunk_wr_valid_i(filter_wr_valid_w[i])
			,.filter_chunk_wr_count_i
			,.filter_chunk_wr_sel_i
			,.filter_chunk_rd_sel_i

			,.run_valid_i
			,.sub_chunk_start_i(total_chunk_start_i)

`ifdef CHANNEL_STACKING
			,.sparsemap_shift_left_i
			,.rd_ifm_sparsemap_first_i
			,.rd_ifm_sparsemap_next_i
			,.rd_fil_sparsemap_first_i
			,.rd_fil_sparsemap_last_i
			,.rd_fil_nonzero_dat_first_i
`endif
			,.sub_chunk_end_o(chunk_end_w[i])

			,.acc_buf_sel_i

//			,.out_buf_sel_i
			,.out_buf_dat_o(out_buf_dat_w[i])
		);
	end

	for (i=0; i<`COMPUTE_UNIT_NUM; i=i+1) begin
		assign filter_wr_valid_w[i] = filter_chunk_cu_wr_sel_i[i] ? filter_chunk_wr_valid_i : 0;
	end

	assign total_chunk_end_o = &chunk_end_w;
	assign out_buf_dat_o = out_buf_dat_w[com_unit_out_buf_sel_i];

`ifdef COMB_DAT_CHUNK
//  `ifdef CHANNEL_STACKING
//  	IFM_Dat_Chunk_Comb_Stacking u_IFM_Dat_Chunk_Comb_Stacking (
//  		 .rst_i
//  		,.clk_i
//  
//  		,.wr_sparsemap_i(ifm_sparsemap_i)
//  		,.wr_nonzero_data_i(ifm_nonzero_data_i)
//  		,.wr_valid_i(ifm_chunk_wr_valid_i)
//  		,.wr_count_i(ifm_chunk_wr_count_i)
//  		,.wr_sel_i(ifm_chunk_wr_sel_i)
//  		,.rd_sel_i(ifm_chunk_rd_sel_i)
//  
//  		,.sub_chunk_start_i(total_chunk_start_i)
//  		,.sparsemap_shift_left_i
//  		,.pri_enc_last_i(pri_enc_last_w)
//  
//  		,.rd_addr_i(rd_addr_w)
//  		,.rd_data_o(rd_data_w)
//  
//  		,.rd_sparsemap_addr_i(rd_sparsemap_addr_w)
//  		,.rd_sparsemap_o(rd_sparsemap_w)	
//  	);
//  `elsif CHANNEL_PADDING
  	IFM_Dat_Chunk_Comb_Padding u_IFM_Dat_Chunk_Comb_Padding (
  		 .rst_i
  		,.clk_i
  
  		,.wr_sparsemap_i(ifm_sparsemap_i)
  		,.wr_nonzero_data_i(ifm_nonzero_data_i)
  		,.wr_valid_i(ifm_chunk_wr_valid_i)
  		,.wr_count_i(ifm_chunk_wr_count_i)
  		,.wr_sel_i(ifm_chunk_wr_sel_i)
  		,.rd_sel_i(ifm_chunk_rd_sel_i)
  
  		,.rd_addr_i(rd_addr_w)
  		,.rd_data_o(rd_data_w)
  
  		,.rd_sparsemap_addr_i(rd_sparsemap_addr_w)
  		,.rd_sparsemap_o(rd_sparsemap_w)	
  	);
//  `endif
`endif

endmodule
