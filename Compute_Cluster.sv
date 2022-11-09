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
	,input [1:0] ifm_chunk_rdy_i

	,input [`BUS_SIZE-1:0] fil_sparsemap_i
	,input [`BUS_SIZE*8-1:0] fil_nonzero_data_i
	,input fil_chunk_wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] fil_chunk_wr_count_i
	,input fil_chunk_wr_sel_i
	,input fil_chunk_rd_sel_i
	,input [`COMPUTE_UNIT_NUM-1:0] fil_chunk_cu_wr_sel_i

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
);

	logic [`COMPUTE_UNIT_NUM-1:0] fil_wr_valid_w;
	logic [`COMPUTE_UNIT_NUM-1:0][`OUTPUT_BUF_SIZE-1:0] out_buf_dat_w;

`ifdef COMB_DAT_CHUNK
	logic [`COMPUTE_UNIT_NUM-1:0][$clog2(`CHUNK_SIZE):0] rd_addr_w;
	logic [`COMPUTE_UNIT_NUM-1:0][7:0] rd_data_w;
	logic [`COMPUTE_UNIT_NUM-1:0][$clog2(`RD_DAT_CYC_NUM)-1:0] rd_sparsemap_addr_w;
	logic [`COMPUTE_UNIT_NUM-1:0][`PREFIX_SUM_SIZE-1:0] rd_sparsemap_w;
`endif

`ifdef CHANNEL_STACKING
	logic [`COMPUTE_UNIT_NUM-1:0] pri_enc_last_w;
	logic [`COMPUTE_UNIT_NUM-1:0][$clog2(`PREFIX_SUM_SIZE)-1:0] sparsemap_shift_left_w;
	logic [`COMPUTE_UNIT_NUM-1:0] inner_loop_finish_w;
`elsif CHANNEL_PADDING
	logic [`COMPUTE_UNIT_NUM-1:0] chunk_end_w;
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
			,.fil_sparsemap_i
			,.fil_nonzero_data_i
			,.fil_chunk_wr_valid_i(fil_wr_valid_w[i])
			,.fil_chunk_wr_count_i
			,.fil_chunk_wr_sel_i
			,.fil_chunk_rd_sel_i

			,.run_valid_i

`ifdef CHANNEL_STACKING
			,.inner_loop_start_i	
			,.ifm_loop_y_idx_i
			,.fil_loop_y_idx_start_i
			,.fil_loop_y_idx_last_i
			,.fil_loop_y_step_i	
			,.sub_channel_size_i	
			,.inner_loop_finish_o	(inner_loop_finish_w[i])
			,.sparsemap_shift_left_o(sparsemap_shift_left_w[i])
`elsif CHANNEL_PADDING
			,.sub_chunk_start_i(total_chunk_start_i)
			,.rd_fil_sparsemap_last_i
			,.acc_buf_sel_i
			,.sub_chunk_end_o(chunk_end_w[i])
`endif

			,.out_buf_dat_o(out_buf_dat_w[i])
		);
	end

	for (i=0; i<`COMPUTE_UNIT_NUM; i=i+1) begin
		assign fil_wr_valid_w[i] = fil_chunk_cu_wr_sel_i[i] ? fil_chunk_wr_valid_i : 0;
	end

`ifdef CHANNEL_STACKING
	logic [`COMPUTE_UNIT_NUM-1:0] inner_loop_finish_r;
	always_ff @(posedge clk_i) begin
		if (rst_i)
			inner_loop_finish_r <= {`COMPUTE_UNIT_NUM{1'b0}};
		else if (total_inner_loop_finish_o)
			inner_loop_finish_r <= {`COMPUTE_UNIT_NUM{1'b0}};
		else begin
			for (int i = 0; i < `COMPUTE_UNIT_NUM; i += 1) begin
				if ((!inner_loop_finish_r[i]) && inner_loop_finish_w[i])
					inner_loop_finish_r[i] <= 1'b1;
			end
		end

	end
	assign total_inner_loop_finish_o = &inner_loop_finish_r;
`elsif CHANNEL_PADDING
	assign total_chunk_end_o = &chunk_end_w;
`endif
	assign out_buf_dat_o = out_buf_dat_w[com_unit_out_buf_sel_i];

`ifdef COMB_DAT_CHUNK
  `ifdef CHANNEL_STACKING
  	IFM_Dat_Chunk_Comb_Stacking u_IFM_Dat_Chunk_Comb_Stacking (
  		 .rst_i
  		,.clk_i
  
  		,.wr_sparsemap_i(ifm_sparsemap_i)
  		,.wr_nonzero_data_i(ifm_nonzero_data_i)
  		,.wr_valid_i(ifm_chunk_wr_valid_i)
  		,.wr_count_i(ifm_chunk_wr_count_i)
  		,.wr_sel_i(ifm_chunk_wr_sel_i)
  		,.rd_sel_i(ifm_chunk_rd_sel_i)
  
  		,.sparsemap_shift_left_i(sparsemap_shift_left_w)
  
  		,.rd_addr_i(rd_addr_w)
  		,.rd_data_o(rd_data_w)
  
  		,.rd_sparsemap_addr_i(rd_sparsemap_addr_w)
  		,.rd_sparsemap_o(rd_sparsemap_w)	
  	);
  `elsif CHANNEL_PADDING
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
  `endif
`endif

endmodule
