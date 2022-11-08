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
	 input clk_i
	,input loop_z_idx_start_i

	,input sub_chunk_end_i
	,input [31:0] fil_loop_y_step_i 
	,input [31:0] sub_channel_size_i 
	,input [2:0] ifm_chunk_rdy_i 
	
	
	,output logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_first_o
	,output logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_last_o
	,output logic [$clog2(`LAYER_FILTER_SIZE_MAX)-1:0] rd_fil_nonzero_dat_first_o
	,output logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_first_o
	,output logic [$clog2(`PREFIX_SUM_SIZE)-1:0] sparsemap_shift_left_o
	,output logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_next_o
	,output logic [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_o
	,output logic inner_loop_finish_o
	,output logic sub_chunk_start_o
	,output logic ifm_chunk_rd_sel_o
    );


event sub_chunk_end_event;
initial begin
forever begin
	@(posedge clk_i);
	if (sub_chunk_end_i) begin
		-> sub_chunk_end_event;
	end
end
end

int ifm_loop_y_idx;
int fil_loop_y_idx_start;
int fil_loop_y_idx_last;

int fil_loop_y_idx;
int fil_loop_y_dat_size;

int ifm_loop_x_idx;
int ifm_loop_x_dat_start;

initial begin
forever begin
	sparsemap_shift_left_o = 0;
	acc_buf_sel_o = 0;
	sub_chunk_start_o = 0;
	ifm_chunk_rd_sel_o = 0;
	inner_loop_finish_o = 0;
	@ (posedge loop_z_idx_start_i);

	for (ifm_loop_y_idx = 0; ifm_loop_y_idx < `LAYER_IFM_SIZE_Y; ifm_loop_y_idx += 1) begin
		while (!ifm_chunk_rdy_i[ifm_chunk_rd_sel_o]) begin
			@(posedge clk_i) #1;
		end

		if (ifm_loop_y_idx < `LAYER_FILTER_SIZE_Y) begin
			fil_loop_y_idx_start = 0;
			fil_loop_y_idx_last = ifm_loop_y_idx;
		end
		else if ((`LAYER_FILTER_SIZE_Y <= ifm_loop_y_idx) && (ifm_loop_y_idx <= `LAYER_IFM_SIZE_Y - `LAYER_FILTER_SIZE_Y)) begin
			fil_loop_y_idx_start = 0;
			fil_loop_y_idx_last = `LAYER_FILTER_SIZE_Y-1;
		end
		else begin
			fil_loop_y_idx_start = `LAYER_FILTER_SIZE_Y - 1 - ((`LAYER_IFM_SIZE_Y - 1) - ifm_loop_y_idx);
			fil_loop_y_idx_last = `LAYER_FILTER_SIZE_Y - 1;
		end

		for (fil_loop_y_idx = fil_loop_y_idx_start; fil_loop_y_idx <= fil_loop_y_idx_last; fil_loop_y_idx += 1) begin
			rd_fil_sparsemap_first_o = fil_loop_y_idx * `LAYER_FILTER_SIZE_X;
			rd_fil_sparsemap_last_o =  rd_fil_sparsemap_first_o + fil_loop_y_step_i - 1;
			rd_fil_nonzero_dat_first_o = fil_loop_y_idx;
		
			ifm_loop_x_dat_start = 0;
		
			for (ifm_loop_x_idx = 0; ifm_loop_x_idx < `LAYER_OUTPUT_SIZE_X; ifm_loop_x_idx += 1) begin
				rd_ifm_sparsemap_first_o = ifm_loop_x_dat_start / `PREFIX_SUM_SIZE;
				sparsemap_shift_left_o = ifm_loop_x_dat_start % `PREFIX_SUM_SIZE;
		
				if (ifm_loop_x_idx == `LAYER_OUTPUT_SIZE_X - 1)
					rd_ifm_sparsemap_next_o = 0;
				else
					rd_ifm_sparsemap_next_o = sub_channel_size_i - 1;
		
				acc_buf_sel_o = (ifm_loop_y_idx - fil_loop_y_idx) * `LAYER_OUTPUT_SIZE_X + ifm_loop_x_idx;
		
				sub_chunk_start_o = 1;
				fork
				begin
					@ (posedge clk_i) #1;
					sub_chunk_start_o = 0;
				end
				join_none
		
				@sub_chunk_end_event;
				ifm_loop_x_dat_start += sub_channel_size_i; 
			end
		end

		inner_loop_finish_o = 1;
		fork
		begin
			@(posedge clk_i) #1;
			inner_loop_finish_o = 0;
		end
		join_none
		ifm_chunk_rd_sel_o = ~ifm_chunk_rd_sel_o;
	end
end
end

endmodule
