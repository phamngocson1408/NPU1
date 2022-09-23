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


module Compute_Cluster_Mem#(
	 localparam int CHUNK_SIZE = `MEM_SIZE
 	,localparam int FILTER_NUM = CHUNK_SIZE / `CHANNEL_NUM
	,localparam int OUTPUT_NUM = (FILTER_NUM <= `OUTPUT_BUF_NUM) ? FILTER_NUM : `OUTPUT_BUF_NUM
 	,localparam int IFM_NUM = FILTER_NUM + OUTPUT_NUM
	,localparam int PARAM_WR_DAT_CYC_NUM = `MEM_SIZE/`BUS_SIZE
	,localparam int PARAM_RD_SPARSEMAP_NUM = `MEM_SIZE/`PREFIX_SUM_SIZE
)(
	 input rst_i
	,input clk_i

	,input [`BUS_SIZE-1:0] ifm_sparsemap_i
	,input [`BUS_SIZE*8-1:0] ifm_nonzero_data_i
	,input ifm_wr_valid_i
	,input [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] ifm_wr_count_i
	,input ifm_wr_sel_i
	,input ifm_rd_sel_i
	,input [$clog2(IFM_NUM)-1:0] ifm_wr_chunk_count_i

	,input [`BUS_SIZE-1:0] filter_sparsemap_i
	,input [`BUS_SIZE*8-1:0] filter_nonzero_data_i
	,input filter_wr_valid_i
	,input [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] filter_wr_count_i
	,input filter_wr_sel_i
	,input filter_rd_sel_i
	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] filter_wr_order_sel_i

	,input run_valid_i
	,input total_chunk_start_i
	,input [$clog2(PARAM_RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_last_i
`ifdef SHORT_CHANNEL	
 `ifndef CHUNK_PADDING
 	,input [$clog2(`PREFIX_SUM_SIZE)-1:0] shift_left_i
 	,input [$clog2(PARAM_RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_step_i
 `endif
`else	// not define SHORT_CHANNEL
 `ifdef IFM_REUSE
 	,input [$clog2(`PREFIX_SUM_SIZE)-1:0] shift_left_i
 	,input [$clog2(PARAM_RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_step_i
 `endif
`endif
	,output total_chunk_end_o

	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_i

	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] out_buf_sel_i
	,input [$clog2(`COMPUTE_UNIT_NUM)-1:0] com_unit_out_buf_sel_i
	,output [`OUTPUT_BUF_SIZE-1:0] out_buf_dat_o

	,input [`BUS_SIZE-1:0] 		mem_ifm_wr_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] 	mem_ifm_wr_nonzero_data_i
	,input 				mem_ifm_wr_valid_i
	,input [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] mem_ifm_wr_dat_count_i
	,input [$clog2(IFM_NUM)-1:0] 	mem_ifm_wr_chunk_count_i

	,input [`BUS_SIZE-1:0] 		mem_filter_wr_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] 	mem_filter_wr_nonzero_data_i
	,input 				mem_filter_wr_valid_i
	,input [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] mem_filter_wr_dat_count_i
	,input [$clog2(FILTER_NUM)-1:0] mem_filter_wr_chunk_count_i

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
	,.ifm_wr_valid_i
	,.ifm_wr_count_i
	,.ifm_wr_sel_i
	,.ifm_rd_sel_i

	,.filter_sparsemap_i(filter_rd_sparsemap_o_w)
	,.filter_nonzero_data_i(filter_rd_nonzero_data_o_w)
	,.filter_wr_valid_i
	,.filter_wr_count_i
	,.filter_wr_sel_i
	,.filter_rd_sel_i
	,.filter_wr_order_sel_i

	,.run_valid_i
	,.total_chunk_start_i
	,.rd_sparsemap_last_i

`ifdef SHORT_CHANNEL
 `ifndef CHUNK_PADDING
	,.shift_left_i
	,.rd_sparsemap_step_i
 `endif
`else
 `ifdef IFM_REUSE
	,.shift_left_i
	,.rd_sparsemap_step_i
 `endif
`endif
	,.total_chunk_end_o

	,.acc_buf_sel_i
	,.out_buf_sel_i
	,.com_unit_out_buf_sel_i
	,.out_buf_dat_o
);

Mem_IFM u_Mem_IFM (
	 .rst_i
	,.clk_i

	,.wr_sparsemap_i	(mem_ifm_wr_sparsemap_i)
	,.wr_nonzero_data_i	(mem_ifm_wr_nonzero_data_i)
	,.wr_valid_i		(mem_ifm_wr_valid_i)
	,.wr_dat_count_i	(mem_ifm_wr_dat_count_i)
	,.wr_chunk_count_i	(mem_ifm_wr_chunk_count_i)

	,.rd_sparsemap_o(ifm_rd_sparsemap_o_w)
	,.rd_nonzero_data_o(ifm_rd_nonzero_data_o_w)
	,.rd_dat_count_i(ifm_wr_count_i)
	,.rd_chunk_count_i(ifm_wr_chunk_count_i)
);

Mem_Filter u_Mem_Filter (
	 .rst_i
	,.clk_i

	,.wr_sparsemap_i	(mem_filter_wr_sparsemap_i)
	,.wr_nonzero_data_i	(mem_filter_wr_nonzero_data_i)
	,.wr_valid_i		(mem_filter_wr_valid_i)
	,.wr_dat_count_i	(mem_filter_wr_dat_count_i)
	,.wr_chunk_count_i	(mem_filter_wr_chunk_count_i)

	,.rd_sparsemap_o(filter_rd_sparsemap_o_w)
	,.rd_nonzero_data_o(filter_rd_nonzero_data_o_w)
	,.rd_dat_count_i(filter_wr_count_i)
	,.rd_chunk_count_i(filter_wr_order_sel_i[$clog2(FILTER_NUM)-1:0])
);

endmodule
