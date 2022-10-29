`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2022 12:22:13 PM
// Design Name: 
// Module Name: IFM_Data_Chunk_Top
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


module IFM_Input_Sel #(
)(
	 input rst_i
	,input clk_i

	,input [$clog2(`PREFIX_SUM_SIZE)-1:0] pri_enc_match_addr_i
	,input pri_enc_end_i
	,input sub_chunk_start_i

	,input [`PREFIX_SUM_SIZE-1:0] rd_sparsemap_i	
	,output [$clog2(`CHUNK_SIZE):0] rd_addr_o

`ifdef CHANNEL_STACKING
	,input [$clog2(`PREFIX_SUM_SIZE)-1:0] sparsemap_shift_left_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_next_i
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_sparsemap_addr_i
`endif
);
	
	logic [$clog2(`PREFIX_SUM_SIZE):0] prefix_sum_out_w [`PREFIX_SUM_SIZE-1:0];

	logic [$clog2(`CHUNK_SIZE):0] rd_dat_base_addr_r;	
	logic [$clog2(`PREFIX_SUM_SIZE):0] rd_dat_addr_temp_w;	

	Prefix_Sum_v4 u_Prefix_Sum (
		.in_i(rd_sparsemap_i)
		,.out_o(prefix_sum_out_w)
	);

`ifdef CHANNEL_STACKING
	logic [$clog2(`CHUNK_SIZE):0] rd_dat_base_addr_next_r;	
	logic gated_clk_0_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_0_lat <= (rst_i || (rd_ifm_sparsemap_next_i == rd_sparsemap_addr_i) || (!rd_ifm_sparsemap_next_i));
		end
	end
	wire gated_clk_0_w = clk_i && gated_clk_0_lat;
	always_ff @(posedge gated_clk_0_w) begin
		if (rst_i) begin
			rd_dat_base_addr_next_r <= {($clog2(`CHUNK_SIZE) + 1){1'b0}};
		end
		else if (rd_ifm_sparsemap_next_i == 0) begin
			rd_dat_base_addr_next_r <= {($clog2(`CHUNK_SIZE) + 1){1'b0}};
		end
		else if (rd_ifm_sparsemap_next_i == rd_sparsemap_addr_i) begin
			rd_dat_base_addr_next_r <= rd_dat_base_addr_r;
		end
	end

	logic gated_clk_1_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_1_lat <= (rst_i || sub_chunk_start_i || pri_enc_end_i);
		end
	end
	wire gated_clk_1_w = clk_i && gated_clk_1_lat;
	always_ff @(posedge gated_clk_1_w) begin
		if (rst_i) begin
			rd_dat_base_addr_r <= {($clog2(`CHUNK_SIZE) + 1){1'b0}};
		end
		else if (sub_chunk_start_i) begin
			rd_dat_base_addr_r <= rd_dat_base_addr_next_r;
		end
		else if (pri_enc_end_i) begin
			rd_dat_base_addr_r <= rd_dat_base_addr_r + prefix_sum_out_w[`PREFIX_SUM_SIZE-1];
		end
	end

	assign rd_dat_addr_temp_w = prefix_sum_out_w[pri_enc_match_addr_i];
	assign rd_addr_o = (sub_chunk_start_i ? rd_dat_base_addr_next_r : rd_dat_base_addr_r) + rd_dat_addr_temp_w;
`elsif CHANNEL_PADDING
	logic gated_clk_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_lat <= (rst_i || sub_chunk_start_i || pri_enc_end_i);
		end
	end
	wire gated_clk_w = clk_i && gated_clk_lat;
	always_ff @(posedge gated_clk_w) begin
		if (rst_i) begin
			rd_dat_base_addr_r <= {($clog2(`CHUNK_SIZE) + 1){1'b0}};
		end
		else if (sub_chunk_start_i) begin
			rd_dat_base_addr_r <= {($clog2(`CHUNK_SIZE) + 1){1'b0}};
		end
		else if (pri_enc_end_i) begin
			rd_dat_base_addr_r <= rd_dat_base_addr_r + prefix_sum_out_w[`PREFIX_SUM_SIZE-1];
		end
	end

	assign rd_dat_addr_temp_w = prefix_sum_out_w[pri_enc_match_addr_i];
	assign rd_addr_o = rd_dat_base_addr_r + rd_dat_addr_temp_w;
`endif


endmodule
