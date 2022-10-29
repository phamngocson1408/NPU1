`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2022 06:34:12 PM
// Design Name: 
// Module Name: Mem_Gen
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


module Mem_Gen #(
//	localparam int `WR_DAT_CYC_NUM = `CHUNK_SIZE/`BUS_SIZE
)(
	 input rst_i
	,input clk_i

	,input mem_gen_start_i
	,output logic mem_gen_finish_o

	,output logic [`BUS_SIZE-1:0] 			mem_ifm_wr_sparsemap_o
	,output logic [`BUS_SIZE*8-1:0] 		mem_ifm_wr_nonzero_data_o
	,output logic 					mem_ifm_wr_valid_o
	,output logic [$clog2(`WR_DAT_CYC_NUM)-1:0] mem_ifm_wr_dat_count_o
	,output logic [$clog2(`SRAM_IFM_NUM)-1:0] 	mem_ifm_wr_chunk_count_o

	,output logic [`BUS_SIZE-1:0] 			mem_filter_wr_sparsemap_o
	,output logic [`BUS_SIZE*8-1:0] 		mem_filter_wr_nonzero_data_o
	,output logic 					mem_filter_wr_valid_o
	,output logic [$clog2(`WR_DAT_CYC_NUM)-1:0] mem_filter_wr_dat_count_o
	,output logic [$clog2(`SRAM_FILTER_NUM)-1:0] 	mem_filter_wr_chunk_count_o
);

// Gennerate IFM
logic [`CHUNK_SIZE-1:0][`DAT_SIZE-1:0] mem_ifm_non_zero_data_r = {`CHUNK_SIZE{`DAT_SIZE{1'b0}}};
logic [`CHUNK_SIZE-1:0] mem_ifm_sparse_map_r;

task automatic gen_ifm_buf(int chunk_dat_size_int);
	int j=0;
	int data;
	int valid_dat;

	for (int i=0; i<`CHUNK_SIZE; i=i+1) begin
 		if (i < chunk_dat_size_int) begin
 			data = $urandom_range(256,1);
 			valid_dat = $urandom_range(100,0);
 		end
 		else begin
 			data = 0;
 			valid_dat = 100;
 		end

		if (valid_dat <= `FILTER_DENSE_RATE) begin
			mem_ifm_non_zero_data_r[j] = data;
			mem_ifm_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			mem_ifm_sparse_map_r[i] = 0;
		end
	end
endtask

//Generate Filer
logic [`CHUNK_SIZE-1:0][`DAT_SIZE-1:0] mem_filter_non_zero_data_r = {`CHUNK_SIZE{`DAT_SIZE{1'b0}}};
logic [`CHUNK_SIZE-1:0] mem_filter_sparse_map_r;

task automatic gen_filter_buf(int chunk_dat_size_int);
	int j=0;
	int data;
	int valid_dat;

	for (int i=0; i<`CHUNK_SIZE; i=i+1) begin
 		if (i < chunk_dat_size_int) begin
 			data = $urandom_range(256,1);
 			valid_dat = $urandom_range(100,0);
 		end
 		else begin
 			data = 0;
 			valid_dat = 100;
 		end

		if (valid_dat <= `FILTER_DENSE_RATE) begin
			mem_filter_non_zero_data_r[j] = data;
			mem_filter_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			mem_filter_sparse_map_r[i] = 0;
		end
	end
endtask

int loop_z_num_int = (`LAYER_CHANNEL_NUM % `DIVIDED_CHANNEL_NUM) ? (`LAYER_CHANNEL_NUM / `DIVIDED_CHANNEL_NUM) + 1 
								 : (`LAYER_CHANNEL_NUM / `DIVIDED_CHANNEL_NUM);
int ifm_loop_y_num_int = `LAYER_FILTER_SIZE_X + `LAYER_OUTPUT_SIZE_X - 1;
initial begin
	@(posedge mem_gen_start_i);	
	fork
		// Gen filter
		begin
			automatic int chunk_dat_size_int = 0;
			automatic int channel_remain_int = 0;
			mem_filter_wr_valid_o = 1'b1;
			for (int i=0; i<loop_z_num_int; i=i+1) begin
				if (i == loop_z_num_int - 1) begin
					channel_remain_int = `LAYER_CHANNEL_NUM - (`DIVIDED_CHANNEL_NUM * i);
					chunk_dat_size_int = `LAYER_FILTER_SIZE_X * `LAYER_FILTER_SIZE_Y * channel_remain_int;
				end
				else begin
					chunk_dat_size_int = `LAYER_FILTER_SIZE_X * `LAYER_FILTER_SIZE_Y * `DIVIDED_CHANNEL_NUM;
				end

				mem_filter_wr_chunk_count_o = i;
				gen_filter_buf(chunk_dat_size_int);
				mem_filter_wr_dat_count_o = 0;
				repeat(`WR_DAT_CYC_NUM) begin
					mem_filter_wr_sparsemap_o = mem_filter_sparse_map_r[`BUS_SIZE*mem_filter_wr_dat_count_o +: `BUS_SIZE];
					mem_filter_wr_nonzero_data_o = mem_filter_non_zero_data_r[`BUS_SIZE*mem_filter_wr_dat_count_o +: `BUS_SIZE];
					@(posedge clk_i);
					mem_filter_wr_dat_count_o = mem_filter_wr_dat_count_o + 1;
				end
			end
			mem_filter_wr_valid_o = 1'b0;
		end

		// Gen ifm
		begin
			automatic int chunk_dat_size_int = 0;
			automatic int channel_remain_int = 0;
			mem_ifm_wr_valid_o = 1'b1;
			for (int i=0; i<loop_z_num_int; i=i+1) begin
				if (i == loop_z_num_int - 1) begin
					channel_remain_int = `LAYER_CHANNEL_NUM - (`DIVIDED_CHANNEL_NUM * i);
					chunk_dat_size_int = ifm_loop_y_num_int * channel_remain_int;
				end
				else begin
					chunk_dat_size_int = ifm_loop_y_num_int * `DIVIDED_CHANNEL_NUM;
				end

				for (int j=0; j<ifm_loop_y_num_int; j=j+1) begin
					mem_ifm_wr_chunk_count_o = i * ifm_loop_y_num_int + j;
					gen_ifm_buf(chunk_dat_size_int);
					mem_ifm_wr_dat_count_o = 0;
					repeat(`WR_DAT_CYC_NUM) begin
						mem_ifm_wr_sparsemap_o = mem_ifm_sparse_map_r[`BUS_SIZE*mem_ifm_wr_dat_count_o +: `BUS_SIZE];
						mem_ifm_wr_nonzero_data_o = mem_ifm_non_zero_data_r[`BUS_SIZE*mem_ifm_wr_dat_count_o +: `BUS_SIZE];
						@(posedge clk_i);
						mem_ifm_wr_dat_count_o = mem_ifm_wr_dat_count_o + 1;
					end
				end

			end
			mem_ifm_wr_valid_o = 1'b0;
		end
	join

	mem_gen_finish_o = 1'b1;
	@(posedge clk_i);
	mem_gen_finish_o = 1'b0;
end

endmodule
