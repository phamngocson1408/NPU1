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
`ifdef CHUNK_PADDING
	localparam int WR_DAT_CYC_NUM =   (`CHANNEL_NUM > `MEM_SIZE) ?  `MEM_SIZE/`BUS_SIZE
					: ((`CHANNEL_NUM % `BUS_SIZE)!=0) ? `CHANNEL_NUM/`BUS_SIZE + 1
					: `CHANNEL_NUM/`BUS_SIZE
	,localparam int RD_SPARSEMAP_NUM =   (`CHANNEL_NUM > `MEM_SIZE) ?  `MEM_SIZE/`PREFIX_SUM_SIZE
					: ((`CHANNEL_NUM % `PREFIX_SUM_SIZE)!=0) ? `CHANNEL_NUM/`PREFIX_SUM_SIZE + 1
					: `CHANNEL_NUM/`PREFIX_SUM_SIZE
`else
	localparam int WR_DAT_CYC_NUM = `MEM_SIZE/`BUS_SIZE
	,localparam int RD_SPARSEMAP_NUM = `MEM_SIZE/`PREFIX_SUM_SIZE
`endif
)(
	 input rst_i
	,input clk_i

`ifdef COMB_DAT_CHUNK
	,output [$clog2(`MEM_SIZE):0] rd_addr_o
	,output [$clog2(RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_addr_o
	,input [`PREFIX_SUM_SIZE-1:0] rd_sparsemap_i	
`else
	,input [`BUS_SIZE-1:0] ifm_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] ifm_nonzero_data_i
	,input ifm_wr_valid_i
	,input [$clog2(WR_DAT_CYC_NUM)-1:0] ifm_wr_count_i
	,input ifm_wr_sel_i
	,input ifm_rd_sel_i
`endif

	,input [`BUS_SIZE-1:0] filter_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] filter_nonzero_data_i
	,input filter_wr_valid_i
	,input [$clog2(WR_DAT_CYC_NUM)-1:0] filter_wr_count_i
	,input filter_wr_sel_i
	,input filter_rd_sel_i

	,input run_valid_i
	,input chunk_start_i
	,input [$clog2(RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_num_i

`ifndef COMB_DAT_CHUNK
	,output logic [7:0] ifm_data_o
`endif
	,output [7:0] filter_data_o
	,output data_valid_o
	,output chunk_end_o
);

	logic [$clog2(`PREFIX_SUM_SIZE)-1:0] pri_enc_match_addr_w;
	logic pri_enc_last_w;
	logic [`PREFIX_SUM_SIZE-1:0] filter_sparsemap_w;
	logic [`PREFIX_SUM_SIZE-1:0] ifm_sparsemap_w;

	logic [$clog2(RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_addr_r, rd_sparsemap_addr_w;

	logic run_valid_r, run_valid_w;
	logic pri_enc_valid_w;

`ifdef COMB_DAT_CHUNK
	IFM_Input_Sel u_IFM_Input_sel (
		 .rst_i
		,.clk_i
		
		,.pri_enc_match_addr_i(pri_enc_match_addr_w)
		,.pri_enc_end_i(pri_enc_last_w)
		,.chunk_start_i(chunk_start_i)
		
		,.rd_sparsemap_i	
		,.rd_addr_o
	);
`else
	Data_Chunk_Top u_Data_Chunk_Top_IFM (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i(ifm_sparsemap_i)
		,.wr_nonzero_data_i(ifm_nonzero_data_i)
		,.wr_valid_i(ifm_wr_valid_i)
		,.wr_count_i(ifm_wr_count_i)
		,.wr_sel_i(ifm_wr_sel_i)

		,.rd_sel_i(ifm_rd_sel_i)
		,.rd_data_o(ifm_data_o)

		,.pri_enc_match_addr_i(pri_enc_match_addr_w)
		,.pri_enc_end_i(pri_enc_last_w)
		,.chunk_start_i(chunk_start_i)

		,.rd_sparsemap_addr_i(rd_sparsemap_addr_w)
		,.rd_sparsemap_o(ifm_sparsemap_w)
	);
`endif

	Data_Chunk_Top u_Data_Chunk_Top_filter (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i(filter_sparsemap_i)
		,.wr_nonzero_data_i(filter_nonzero_data_i)
		,.wr_valid_i(filter_wr_valid_i)
		,.wr_count_i(filter_wr_count_i)
		,.wr_sel_i(filter_wr_sel_i)

		,.rd_sel_i(filter_rd_sel_i)
		,.rd_data_o(filter_data_o)

		,.pri_enc_match_addr_i(pri_enc_match_addr_w)
		,.pri_enc_end_i(pri_enc_last_w)
		,.chunk_start_i(chunk_start_i)

		,.rd_sparsemap_addr_i(rd_sparsemap_addr_w)
		,.rd_sparsemap_o(filter_sparsemap_w)
	);

	assign pri_enc_valid_w = run_valid_i && run_valid_w;

	Priority_Encoder_Top u_Priority_Encoder_Top (
		 .rst_i
		,.clk_i
		,.valid_i(pri_enc_valid_w)
		,.chunk_start_i
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
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			rd_sparsemap_addr_r <= #1 {($clog2(RD_SPARSEMAP_NUM)){1'b0}};
		end
		else if (pri_enc_last_w) begin
			rd_sparsemap_addr_r <= #1 rd_sparsemap_addr_w + 1'b1;
		end
		else if (chunk_start_i) begin
			rd_sparsemap_addr_r <= #1 {($clog2(RD_SPARSEMAP_NUM)){1'b0}};
		end
	end

	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			run_valid_r <= #1 1'b1;
		end
		else if (chunk_end_o) begin
			run_valid_r <= #1 1'b0;
		end
		else if (chunk_start_i) begin
			run_valid_r <= #1 1'b1;
		end
	end

	assign run_valid_w = chunk_start_i || run_valid_r;

	assign rd_sparsemap_addr_w = chunk_start_i ? {($clog2(RD_SPARSEMAP_NUM)){1'b0}} : rd_sparsemap_addr_r;

	assign chunk_end_o = 	((rd_sparsemap_addr_w == rd_sparsemap_num_i) && pri_enc_last_w) 
				|| (!run_valid_w);
	
`ifdef COMB_DAT_CHUNK
	assign rd_sparsemap_addr_o = rd_sparsemap_addr_w;
`endif

endmodule
