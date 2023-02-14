`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2022 12:29:42 AM
// Design Name: 
// Module Name: Stacking_Inner_Loop
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


module Stacking_Inner_Loop(
	 input rst_i
	,input clk_i

	,input inner_loop_start_i
	,input sub_chunk_end_i
	,input [$clog2(`LAYER_IFM_SIZE_Y)-1:0] ifm_loop_y_idx_i 
	,input [$clog2(`LAYER_IFM_SIZE_Y)-1:0] fil_loop_y_idx_start_i 
	,input [$clog2(`LAYER_IFM_SIZE_Y)-1:0] fil_loop_y_idx_last_i 
	,input [$clog2(`LAYER_IFM_SIZE_X*`DIVIDED_CHANNEL_NUM/`PREFIX_SUM_SIZE + 1)-1:0] fil_loop_y_step_i 
	,input [$clog2(`DIVIDED_CHANNEL_NUM)-1:0] sub_channel_size_i 
	
	
	,output logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_first_o
	,output logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_last_o
	,output logic [$clog2(`LAYER_FILTER_SIZE_MAX)-1:0] rd_fil_nonzero_dat_first_o
	,output logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_first_o
	,output logic [$clog2(`PREFIX_SUM_SIZE)-1:0] sparsemap_shift_left_o
	,output logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_next_o
	,output logic [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_o
	,output logic inner_loop_finish_o
	,output logic sub_chunk_start_o
    );

logic[$clog2(`LAYER_OUTPUT_SIZE_X)-1:0] fil_loop_y_idx;

logic[$clog2(`LAYER_OUTPUT_SIZE_X)-1:0] ifm_loop_x_idx;
logic[$clog2(`LAYER_OUTPUT_SIZE_X)-1:0] ifm_loop_x_dat_start;
wire ifm_loop_x_idx_last_w = (ifm_loop_x_idx == `LAYER_OUTPUT_SIZE_X - 1) && sub_chunk_end_i;

logic gated_clk_lat;
always_latch begin
	if (!clk_i) begin
		gated_clk_lat <= (rst_i || inner_loop_start_i || ifm_loop_x_idx_last_w || sub_chunk_end_i);
	end
end
wire gated_clk_w = clk_i && gated_clk_lat;

always @(posedge gated_clk_w) begin
	if (rst_i) begin
		ifm_loop_x_idx <= {$clog2(`LAYER_OUTPUT_SIZE_X){1'b0}};
	end
	else begin
		if (inner_loop_start_i)
			ifm_loop_x_idx <= {$clog2(`LAYER_OUTPUT_SIZE_X){1'b0}};
		else if (ifm_loop_x_idx_last_w)
			ifm_loop_x_idx <= {$clog2(`LAYER_OUTPUT_SIZE_X){1'b0}};
		else if (sub_chunk_end_i)
			ifm_loop_x_idx <= ifm_loop_x_idx + 1;
	end
end

always @(posedge gated_clk_w) begin
	if (rst_i) begin
		ifm_loop_x_dat_start <= {$clog2(`LAYER_OUTPUT_SIZE_X){1'b0}};
	end
	else begin
		if (ifm_loop_x_idx_last_w)
			ifm_loop_x_dat_start <= {$clog2(`LAYER_OUTPUT_SIZE_X){1'b0}};
		else if (sub_chunk_end_i)
			ifm_loop_x_dat_start <= ifm_loop_x_dat_start + sub_channel_size_i;
	end
end

always @(posedge gated_clk_w) begin
	if (rst_i) begin
		fil_loop_y_idx <= {$clog2(`LAYER_OUTPUT_SIZE_X){1'b0}};
	end
	else begin
		if (inner_loop_start_i)
			fil_loop_y_idx <= fil_loop_y_idx_start_i;
		else if ((fil_loop_y_idx == fil_loop_y_idx_last_i) && ifm_loop_x_idx_last_w)
			fil_loop_y_idx <= fil_loop_y_idx_start_i;
		else if (ifm_loop_x_idx_last_w)
			fil_loop_y_idx <= fil_loop_y_idx + 1;
	end
end

assign rd_fil_sparsemap_first_o = fil_loop_y_idx * `LAYER_FILTER_SIZE_X;
assign rd_fil_sparsemap_last_o =  rd_fil_sparsemap_first_o + fil_loop_y_step_i - 1;
assign rd_fil_nonzero_dat_first_o = fil_loop_y_idx;

assign rd_ifm_sparsemap_first_o = ifm_loop_x_dat_start / `PREFIX_SUM_SIZE;
assign sparsemap_shift_left_o = ifm_loop_x_dat_start % `PREFIX_SUM_SIZE;

assign rd_ifm_sparsemap_next_o = (ifm_loop_x_idx == `LAYER_OUTPUT_SIZE_X - 1) ? 0 : sub_channel_size_i - 1;
assign acc_buf_sel_o = (ifm_loop_y_idx_i - fil_loop_y_idx) * `LAYER_OUTPUT_SIZE_X + ifm_loop_x_idx;

always @(posedge clk_i) begin
	if (rst_i) begin
		inner_loop_finish_o <= 1'b0;
	end
	else begin
		if (inner_loop_finish_o)
			inner_loop_finish_o <= 1'b0;
		else if ((fil_loop_y_idx == fil_loop_y_idx_last_i) && ifm_loop_x_idx_last_w)
			inner_loop_finish_o <= 1'b1;
	end
end

always @(posedge clk_i) begin
	if (rst_i) begin
		sub_chunk_start_o <= 1'b0;
	end
	else begin
		if (sub_chunk_start_o)
			sub_chunk_start_o <= 1'b0;
		else if (sub_chunk_end_i)
			sub_chunk_start_o <= 1'b1;
	end
end

endmodule
