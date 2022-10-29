`include "Global_Include.vh"
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
//	 localparam int `WR_DAT_CYC_NUM = `CHUNK_SIZE/`BUS_SIZE
//	,localparam int `RD_DAT_CYC_NUM = `CHUNK_SIZE/`PREFIX_SUM_SIZE
)(
	 input rst_i
	,input clk_i

`ifdef COMB_DAT_CHUNK
	,output [$clog2(`CHUNK_SIZE):0] rd_addr_o
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

`ifndef COMB_DAT_CHUNK
	,output logic [7:0] ifm_data_o
`endif
	,output [7:0] filter_data_o
	,output data_valid_o
	,output sub_chunk_end_o
);

	logic [$clog2(`PREFIX_SUM_SIZE)-1:0] pri_enc_match_addr_w;
	logic pri_enc_last_w;
	logic [`PREFIX_SUM_SIZE-1:0] filter_sparsemap_w;
	logic [`PREFIX_SUM_SIZE-1:0] ifm_sparsemap_w;

	logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_addr_r, rd_ifm_sparsemap_addr_w;
	logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_addr_r, rd_fil_sparsemap_addr_w;

	logic run_valid_r, run_valid_w;
	logic pri_enc_valid_w;

`ifdef COMB_DAT_CHUNK
	IFM_Input_Sel u_IFM_Input_sel (
		 .rst_i
		,.clk_i
		
		,.pri_enc_match_addr_i(pri_enc_match_addr_w)
		,.pri_enc_end_i(pri_enc_last_w)
		,.sub_chunk_start_i
		
		,.rd_sparsemap_i	
		,.rd_addr_o

 `ifdef CHANNEL_STACKING
		,.sparsemap_shift_left_i
		,.rd_ifm_sparsemap_next_i
		,.rd_sparsemap_addr_i(rd_ifm_sparsemap_addr_w)
 `endif
	);
`else
	Data_Chunk_Top u_Data_Chunk_Top_IFM (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i(ifm_sparsemap_i)
		,.wr_nonzero_data_i(ifm_nonzero_data_i)
		,.wr_valid_i(ifm_chunk_wr_valid_i)
		,.wr_count_i(ifm_chunk_wr_count_i)
		,.wr_sel_i(ifm_chunk_wr_sel_i)

		,.rd_sel_i(ifm_chunk_rd_sel_i)
		,.rd_data_o(ifm_data_o)

		,.pri_enc_match_addr_i(pri_enc_match_addr_w)
		,.pri_enc_end_i(pri_enc_last_w)
		,.sub_chunk_start_i

		,.rd_sparsemap_addr_i(rd_ifm_sparsemap_addr_w)
		,.rd_sparsemap_o(ifm_sparsemap_w)
	);
`endif

	Data_Chunk_Top_Filter u_Data_Chunk_Top_filter (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i(filter_sparsemap_i)
		,.wr_nonzero_data_i(filter_nonzero_data_i)
		,.wr_valid_i(filter_chunk_wr_valid_i)
		,.wr_count_i(filter_chunk_wr_count_i)
		,.wr_sel_i(filter_chunk_wr_sel_i)

		,.rd_sel_i(filter_chunk_rd_sel_i)
		,.rd_data_o(filter_data_o)

		,.pri_enc_match_addr_i(pri_enc_match_addr_w)
		,.pri_enc_end_i(pri_enc_last_w)
		,.sub_chunk_start_i

		,.rd_sparsemap_addr_i(rd_fil_sparsemap_addr_w)
		,.rd_sparsemap_o(filter_sparsemap_w)

`ifdef CHANNEL_STACKING
		,.rd_fil_nonzero_dat_first_i
		,.sub_chunk_end_i(sub_chunk_end_o)
`endif
	);

	assign pri_enc_valid_w = run_valid_i && run_valid_w;

	Priority_Encoder_Top u_Priority_Encoder_Top (
		 .rst_i
		,.clk_i
		,.valid_i(pri_enc_valid_w)
		,.sub_chunk_start_i
`ifdef COMB_DAT_CHUNK
		,.in1_i(rd_sparsemap_i)
`else
		,.in1_i(ifm_sparsemap_w)
`endif
		,.in2_i(filter_sparsemap_w)
		
		,.valid_o(data_valid_o)
		,.match_addr_o(pri_enc_match_addr_w)
		,.pri_enc_last_o(pri_enc_last_w)
	);

	// Calculate sparsemap addr
`ifdef CHANNEL_STACKING
	logic gated_clk_0_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_0_lat <= rst_i || pri_enc_last_w || sub_chunk_start_i;
		end
	end
	wire gated_clk_0_w = clk_i && gated_clk_0_lat;
	always_ff @(posedge gated_clk_0_w) begin
		if (rst_i) begin
			rd_ifm_sparsemap_addr_r <= rd_ifm_sparsemap_first_i;
			rd_fil_sparsemap_addr_r <= rd_fil_sparsemap_first_i;
		end
		else if (pri_enc_last_w) begin
			rd_ifm_sparsemap_addr_r <= rd_ifm_sparsemap_addr_w + 1'b1;
			rd_fil_sparsemap_addr_r <= rd_fil_sparsemap_addr_w + 1'b1;
		end
		else if (sub_chunk_start_i) begin
			rd_ifm_sparsemap_addr_r <= rd_ifm_sparsemap_first_i;
			rd_fil_sparsemap_addr_r <= rd_fil_sparsemap_first_i;
		end
	end
`elsif CHANNEL_PADDING
	logic gated_clk_0_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_0_lat <= rst_i || pri_enc_last_w || sub_chunk_start_i;
		end
	end
	wire gated_clk_0_w = clk_i && gated_clk_0_lat;
	always_ff @(posedge gated_clk_0_w) begin
		if (rst_i) begin
			rd_ifm_sparsemap_addr_r <= {($clog2(`RD_DAT_CYC_NUM)){1'b0}};
		end
		else if (pri_enc_last_w) begin
			rd_ifm_sparsemap_addr_r <= rd_ifm_sparsemap_addr_w + 1'b1;
		end
		else if (sub_chunk_start_i) begin
			rd_ifm_sparsemap_addr_r <= {($clog2(`RD_DAT_CYC_NUM)){1'b0}};
		end
	end
`endif
	
	logic gated_clk_1_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_1_lat <= rst_i || sub_chunk_end_o || sub_chunk_start_i;
		end
	end
	wire gated_clk_1_w = clk_i && gated_clk_1_lat;
	always_ff @(posedge gated_clk_1_w) begin
		if (rst_i) begin
			run_valid_r <= 1'b1;
		end
		else if (sub_chunk_end_o) begin
			run_valid_r <= 1'b0;
		end
		else if (sub_chunk_start_i) begin
			run_valid_r <= 1'b1;
		end
	end

	assign run_valid_w = sub_chunk_start_i || run_valid_r;

`ifdef CHANNEL_STACKING
	assign rd_ifm_sparsemap_addr_w = sub_chunk_start_i ? rd_ifm_sparsemap_first_i : rd_ifm_sparsemap_addr_r;
	assign rd_fil_sparsemap_addr_w = sub_chunk_start_i ? rd_fil_sparsemap_first_i : rd_fil_sparsemap_addr_r;
`elsif CHANNEL_PADDING
	assign rd_ifm_sparsemap_addr_w = sub_chunk_start_i ? {($clog2(`RD_DAT_CYC_NUM)){1'b0}} : rd_ifm_sparsemap_addr_r;
	assign rd_fil_sparsemap_addr_w = rd_ifm_sparsemap_addr_w;
`endif

	assign sub_chunk_end_o = ((rd_fil_sparsemap_addr_w == rd_fil_sparsemap_last_i) && pri_enc_last_w) 
				|| (!run_valid_w);
	
`ifdef COMB_DAT_CHUNK
	assign rd_sparsemap_addr_o = rd_ifm_sparsemap_addr_w;
`endif

`ifdef CHANNEL_STACKING
	assign pri_enc_last_o = pri_enc_last_w;
`endif

endmodule
