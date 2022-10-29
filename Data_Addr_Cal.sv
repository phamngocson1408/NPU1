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


module Data_Addr_Cal #(
//	 localparam int `WR_DAT_CYC_NUM = `CHUNK_SIZE/`BUS_SIZE
//	,localparam int `RD_DAT_CYC_NUM = `CHUNK_SIZE/`PREFIX_SUM_SIZE
)(
	 input rst_i
	,input clk_i

	,input [$clog2(`PREFIX_SUM_SIZE)-1:0] pri_enc_match_addr_i
	,input pri_enc_end_i
	,input sub_chunk_start_i
	,input [`PREFIX_SUM_SIZE-1:0] sparsemap_i

	,output [$clog2(`CHUNK_SIZE):0] rd_dat_addr_o

`ifdef CHANNEL_STACKING
	,input [$clog2(`LAYER_FILTER_SIZE_MAX)-1:0] rd_fil_nonzero_dat_first_i
	,input sub_chunk_end_i
`endif
);
	
	logic [$clog2(`PREFIX_SUM_SIZE):0] prefix_sum_out_w [`PREFIX_SUM_SIZE-1:0];

	logic [$clog2(`CHUNK_SIZE):0] rd_data_base_addr_r, rd_data_base_addr_w;	
	logic [$clog2(`PREFIX_SUM_SIZE):0] rd_data_addr_temp_w;	

	Prefix_Sum_v4 u_Prefix_Sum (
		.in_i(sparsemap_i)
		,.out_o(prefix_sum_out_w)
	);

`ifdef CHANNEL_STACKING
	logic [`LAYER_FILTER_SIZE_MAX-1:0][$clog2(`CHUNK_SIZE):0] rd_dat_base_addr_next_r;
	logic [$clog2(`CHUNK_SIZE):0] rd_dat_base_addr_next_w;
	assign rd_dat_base_addr_next_w = (rd_fil_nonzero_dat_first_i == 0) ? {($clog2(`CHUNK_SIZE) + 1){1'b0}} : rd_dat_base_addr_next_r[rd_fil_nonzero_dat_first_i-1];

	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			for (int i=0; i<`LAYER_FILTER_SIZE_MAX; i=i+1) begin
				rd_dat_base_addr_next_r[i] <= {($clog2(`LAYER_FILTER_SIZE_MAX)){1'b0}};
			end
		end
		else if (sub_chunk_end_i) begin
			for (int i=0; i<`LAYER_FILTER_SIZE_MAX; i=i+1) begin
				if (rd_fil_nonzero_dat_first_i == i)
					rd_dat_base_addr_next_r[i] <= rd_data_base_addr_r + prefix_sum_out_w[`PREFIX_SUM_SIZE-1];
			end
		end
	end

	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			rd_data_base_addr_r <= {($clog2(`CHUNK_SIZE) + 1){1'b0}};
		end
		else if (sub_chunk_start_i) begin
			rd_data_base_addr_r <= rd_dat_base_addr_next_w;
		end
		else if (pri_enc_end_i) begin
			rd_data_base_addr_r <= rd_data_base_addr_r + prefix_sum_out_w[`PREFIX_SUM_SIZE-1];
		end
	end

	assign rd_data_base_addr_w = sub_chunk_start_i ? rd_dat_base_addr_next_w : rd_data_base_addr_r;

	assign rd_data_addr_temp_w = prefix_sum_out_w[pri_enc_match_addr_i];

	assign rd_dat_addr_o = rd_data_base_addr_w + rd_data_addr_temp_w;

`elsif CHANNEL_PADDING
	logic gated_clk_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_lat <= (rst_i || pri_enc_end_i || sub_chunk_start_i);
		end
	end
	wire gated_clk_w = clk_i && gated_clk_lat;
	always_ff @(posedge gated_clk_w) begin
		if (rst_i) begin
			rd_data_base_addr_r <= {($clog2(`CHUNK_SIZE) + 1){1'b0}};
		end
		else if (pri_enc_end_i) begin
			rd_data_base_addr_r <= rd_data_base_addr_w + prefix_sum_out_w[`PREFIX_SUM_SIZE-1];
		end
		else if (sub_chunk_start_i) begin
			rd_data_base_addr_r <= {($clog2(`CHUNK_SIZE) + 1){1'b0}};
		end
	end

	assign rd_data_base_addr_w = sub_chunk_start_i ? {($clog2(`CHUNK_SIZE) + 1){1'b0}} : rd_data_base_addr_r;

	assign rd_data_addr_temp_w = prefix_sum_out_w[pri_enc_match_addr_i];

	assign rd_dat_addr_o = rd_data_base_addr_w + rd_data_addr_temp_w;
`endif
endmodule

