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

localparam int FIL_SUB_CHUNK_SIZE = `LAYER_FILTER_SIZE_X * `DIVIDED_CHANNEL_NUM;
//localparam int FIL_SUB_CHUNK_REMAIN = `SIM_CHUNK_SIZE % FIL_SUB_CHUNK_SIZE;

task automatic gen_fil_buf(int sub_chunk_dat_size);
	int data;
	int valid_dat;

	for (int loop_y_idx = 0; loop_y_idx < `LAYER_FILTER_SIZE_Y; loop_y_idx += 1) begin
		int j=0;
		for (int loop_x_idx = 0; loop_x_idx < FIL_SUB_CHUNK_SIZE; loop_x_idx += 1) begin
 			if (loop_x_idx < sub_chunk_dat_size) begin
 				data = $urandom_range(256,1);
 				valid_dat = $urandom_range(100,0);
 			end
 			else begin
 				data = 0;
 				valid_dat = 100;
 			end

			if (valid_dat <= `FILTER_DENSE_RATE) begin
				fil_sram_non_zero_data_r[loop_y_idx * FIL_SUB_CHUNK_SIZE + j] = data;
				fil_sram_sparse_map_r[loop_y_idx * FIL_SUB_CHUNK_SIZE + loop_x_idx] = 1;
				j = j+1;
			end
			else begin
				fil_sram_sparse_map_r[loop_y_idx * FIL_SUB_CHUNK_SIZE + loop_x_idx] = 0;
			end
		end
	end
//	for (int loop_x_idx = 0; loop_x_idx < FIL_SUB_CHUNK_REMAIN; loop_x_idx += 1) begin
//			fil_sram_sparse_map_r[`LAYER_FILTER_SIZE_Y * FIL_SUB_CHUNK_SIZE + loop_x_idx] = 0;
//	end
endtask

localparam int SIM_LOOP_Z_NUM = (`LAYER_CHANNEL_NUM % `DIVIDED_CHANNEL_NUM) ? (`LAYER_CHANNEL_NUM / `DIVIDED_CHANNEL_NUM) + 1 : (`LAYER_CHANNEL_NUM / `DIVIDED_CHANNEL_NUM);
localparam int SIM_LAST_CHANNEL_SIZE = (`LAYER_CHANNEL_NUM % `DIVIDED_CHANNEL_NUM) ? (`LAYER_CHANNEL_NUM % `DIVIDED_CHANNEL_NUM) : `DIVIDED_CHANNEL_NUM;

int fil_sub_chunk_dat_size;
int fil_chunk_dat_wr_cyc_num;
int ifm_chunk_dat_size;
int ifm_chunk_dat_wr_cyc_num;

initial begin
	@(posedge mem_gen_start_i) #1;	
	fork
		// Gen fil
		begin
			fil_sram_wr_valid_o = 1'b1;
			for (int loop_z_idx = 0; loop_z_idx < SIM_LOOP_Z_NUM; loop_z_idx += 1) begin
				if (loop_z_idx == SIM_LOOP_Z_NUM - 1) begin
					fil_sub_chunk_dat_size = `LAYER_FILTER_SIZE_X * SIM_LAST_CHANNEL_SIZE;
				end
				else begin
					fil_sub_chunk_dat_size = `LAYER_FILTER_SIZE_X * `DIVIDED_CHANNEL_NUM;
				end

				fil_chunk_dat_wr_cyc_num = `LAYER_FILTER_SIZE_Y * `LAYER_FILTER_SIZE_X;

				for (int chunk_cu_idx = 0; chunk_cu_idx < `COMPUTE_UNIT_NUM; chunk_cu_idx += 1) begin
					fil_sram_wr_chunk_count_o = loop_z_idx * `COMPUTE_UNIT_NUM + chunk_cu_idx;
					gen_fil_buf(fil_sub_chunk_dat_size);
					fil_sram_wr_dat_count_o = 0;
					repeat(fil_chunk_dat_wr_cyc_num) begin
						fil_sram_wr_sparsemap_o = fil_sram_sparse_map_r[`BUS_SIZE*fil_sram_wr_dat_count_o +: `BUS_SIZE];
						fil_sram_wr_nonzero_data_o = fil_sram_non_zero_data_r[`BUS_SIZE*fil_sram_wr_dat_count_o +: `BUS_SIZE];
						@(posedge clk_i) #1;
						fil_sram_wr_dat_count_o = fil_sram_wr_dat_count_o + 1;
					end
				end
			end
			fil_sram_wr_valid_o = 1'b0;
		end
		// Gen ifm
		begin
			ifm_sram_wr_valid_o = 1'b1;
			for (int loop_z_idx = 0; loop_z_idx < SIM_LOOP_Z_NUM; loop_z_idx += 1) begin
				if (loop_z_idx == SIM_LOOP_Z_NUM - 1) begin
					ifm_chunk_dat_size = `LAYER_IFM_SIZE_X * SIM_LAST_CHANNEL_SIZE;
				end
				else begin
					ifm_chunk_dat_size = `LAYER_IFM_SIZE_X * `DIVIDED_CHANNEL_NUM;
				end

				ifm_chunk_dat_wr_cyc_num = (ifm_chunk_dat_size % `BUS_SIZE) ? ifm_chunk_dat_size/`BUS_SIZE + 1 : ifm_chunk_dat_size/`BUS_SIZE;

				for (int ifm_loop_y_idx = 0; ifm_loop_y_idx < `LAYER_IFM_SIZE_Y; ifm_loop_y_idx += 1) begin
					ifm_sram_wr_chunk_count_o = loop_z_idx * `LAYER_IFM_SIZE_Y + ifm_loop_y_idx;
					gen_ifm_buf(ifm_chunk_dat_size);
					ifm_sram_wr_dat_count_o = 0;
					repeat(ifm_chunk_dat_wr_cyc_num) begin
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
