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


module Mem_Gen_Stacking #(
)(
	 input rst_i
	,input clk_i

	,input mem_gen_start_i
	,output logic mem_gen_finish_o

	,output logic [`BUS_SIZE-1:0] 			ifm_sram_wr_sparsemap_o
	,output logic [`BUS_SIZE*8-1:0] 		ifm_sram_wr_nonzero_data_o
	,output logic 					ifm_sram_wr_valid_o
	,output logic [$clog2(`WR_DAT_CYC_NUM)-1:0] 	ifm_sram_wr_dat_count_o
	,output logic [$clog2(`SRAM_IFM_NUM)-1:0] 	ifm_sram_wr_chunk_count_o

	,output logic [`BUS_SIZE-1:0] 			fil_sram_wr_sparsemap_o
	,output logic [`BUS_SIZE*8-1:0] 		fil_sram_wr_nonzero_data_o
	,output logic 					fil_sram_wr_valid_o
	,output logic [$clog2(`WR_DAT_CYC_NUM)-1:0] 	fil_sram_wr_dat_count_o
	,output logic [$clog2(`SRAM_FILTER_NUM)-1:0] 	fil_sram_wr_chunk_count_o
);

// Gennerate IFM
logic [`SIM_CHUNK_SIZE-1:0][`DAT_SIZE-1:0] ifm_sram_non_zero_data_r = {`SIM_CHUNK_SIZE{`DAT_SIZE{1'b0}}};
logic [`SIM_CHUNK_SIZE-1:0] ifm_sram_sparse_map_r;

task automatic gen_ifm_buf(int chunk_dat_size);
	int j=0;
	int data;
	int valid_dat;

	for (int i=0; i<`SIM_CHUNK_SIZE; i=i+1) begin
 		if (i < chunk_dat_size) begin
 			data = $urandom_range(256,1);
 			valid_dat = $urandom_range(100,0);
 		end
 		else begin
 			data = 0;
 			valid_dat = 100;
 		end

		if (valid_dat <= `FILTER_DENSE_RATE) begin
			ifm_sram_non_zero_data_r[j] = data;
			ifm_sram_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			ifm_sram_sparse_map_r[i] = 0;
		end
	end
endtask

//Generate Filer
logic [`SIM_CHUNK_SIZE-1:0][`DAT_SIZE-1:0] fil_sram_non_zero_data_r = {`SIM_CHUNK_SIZE{`DAT_SIZE{1'b0}}};
logic [`SIM_CHUNK_SIZE-1:0] fil_sram_sparse_map_r;

task automatic gen_fil_buf(int chunk_dat_size);
	int j=0;
	int data;
	int valid_dat;

	for (int i=0; i<`SIM_CHUNK_SIZE; i=i+1) begin
 		if (i < chunk_dat_size) begin
 			data = $urandom_range(256,1);
 			valid_dat = $urandom_range(100,0);
 		end
 		else begin
 			data = 0;
 			valid_dat = 100;
 		end

		if (valid_dat <= `FILTER_DENSE_RATE) begin
			fil_sram_non_zero_data_r[j] = data;
			fil_sram_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			fil_sram_sparse_map_r[i] = 0;
		end
	end
endtask

int loop_z_num = (`LAYER_CHANNEL_NUM % `DIVIDED_CHANNEL_NUM) ? (`LAYER_CHANNEL_NUM / `DIVIDED_CHANNEL_NUM) + 1 : (`LAYER_CHANNEL_NUM / `DIVIDED_CHANNEL_NUM);
int ifm_loop_y_num = `LAYER_FILTER_SIZE_X + `LAYER_OUTPUT_SIZE_X - 1;
initial begin
	@(posedge mem_gen_start_i) #1;	
	fork
		// Gen fil
		begin
			automatic int fil_chunk_dat_size = 0;
			automatic int fil_channel_remain = 0;
			fil_sram_wr_valid_o = 1'b1;
			for (int i=0; i<loop_z_num; i=i+1) begin
				if (i == loop_z_num - 1) begin
					fil_channel_remain = `LAYER_CHANNEL_NUM - (`DIVIDED_CHANNEL_NUM * i);
					fil_chunk_dat_size = `LAYER_FILTER_SIZE_X * `LAYER_FILTER_SIZE_Y * fil_channel_remain;
				end
				else begin
					fil_chunk_dat_size = `LAYER_FILTER_SIZE_X * `LAYER_FILTER_SIZE_Y * `DIVIDED_CHANNEL_NUM;
				end

				fil_sram_wr_chunk_count_o = i;
				gen_fil_buf(fil_chunk_dat_size);
				fil_sram_wr_dat_count_o = 0;
				repeat(`SIM_WR_DAT_CYC_NUM) begin
					fil_sram_wr_sparsemap_o = fil_sram_sparse_map_r[`BUS_SIZE*fil_sram_wr_dat_count_o +: `BUS_SIZE];
					fil_sram_wr_nonzero_data_o = fil_sram_non_zero_data_r[`BUS_SIZE*fil_sram_wr_dat_count_o +: `BUS_SIZE];
					@(posedge clk_i) #1;
					fil_sram_wr_dat_count_o = fil_sram_wr_dat_count_o + 1;
				end
			end
			fil_sram_wr_valid_o = 1'b0;
		end

		// Gen ifm
		begin
			automatic int ifm_chunk_dat_size = 0;
			automatic int ifm_channel_remain = 0;
			ifm_sram_wr_valid_o = 1'b1;
			for (int i=0; i<loop_z_num; i=i+1) begin
				if (i == loop_z_num - 1) begin
					ifm_channel_remain = `LAYER_CHANNEL_NUM - (`DIVIDED_CHANNEL_NUM * i);
					ifm_chunk_dat_size = ifm_loop_y_num * ifm_channel_remain;
				end
				else begin
					ifm_chunk_dat_size = ifm_loop_y_num * `DIVIDED_CHANNEL_NUM;
				end

				for (int j=0; j<ifm_loop_y_num; j=j+1) begin
					ifm_sram_wr_chunk_count_o = i * ifm_loop_y_num + j;
					gen_ifm_buf(ifm_chunk_dat_size);
					ifm_sram_wr_dat_count_o = 0;
					repeat(`SIM_WR_DAT_CYC_NUM) begin
						ifm_sram_wr_sparsemap_o = ifm_sram_sparse_map_r[`BUS_SIZE*ifm_sram_wr_dat_count_o +: `BUS_SIZE];
						ifm_sram_wr_nonzero_data_o = ifm_sram_non_zero_data_r[`BUS_SIZE*ifm_sram_wr_dat_count_o +: `BUS_SIZE];
						@(posedge clk_i) #1;
						ifm_sram_wr_dat_count_o = ifm_sram_wr_dat_count_o + 1;
					end
				end

			end
			ifm_sram_wr_valid_o = 1'b0;
		end
	join

	mem_gen_finish_o = 1'b1;
	@(posedge clk_i) #1;
	mem_gen_finish_o = 1'b0;
end

endmodule
