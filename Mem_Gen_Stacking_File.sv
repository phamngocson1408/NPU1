`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2023 04:12:12 PM
// 
//////////////////////////////////////////////////////////////////////////////////


module Mem_Gen_Stacking_File #(
)(
);

// Gennerate IFM
logic [`SIM_CHUNK_SIZE-1:0][`DAT_SIZE-1:0] ifm_sram_non_zero_data_r = {`SIM_CHUNK_SIZE{`DAT_SIZE{1'b0}}};
logic [`SIM_CHUNK_SIZE-1:0] ifm_sram_sparse_map_r = {`SIM_CHUNK_SIZE{1'b0}};

task automatic gen_ifm_buf(int chunk_dat_size, int chunk_size);
	int j=0;
	int data;
	int valid_dat;

	ifm_sram_non_zero_data_r = {`SIM_CHUNK_SIZE{`DAT_SIZE{1'b0}}};
	ifm_sram_sparse_map_r = {`SIM_CHUNK_SIZE{1'b0}};

	for (int i=0; i<chunk_size; i=i+1) begin
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
logic [`SIM_CHUNK_SIZE-1:0] fil_sram_sparse_map_r = {`SIM_CHUNK_SIZE{1'b0}};

localparam int FIL_SUB_CHUNK_SIZE = `LAYER_FILTER_SIZE_X * `DIVIDED_CHANNEL_NUM;
//localparam int FIL_SUB_CHUNK_REMAIN = `SIM_CHUNK_SIZE % FIL_SUB_CHUNK_SIZE;

task automatic gen_fil_buf(int sub_chunk_dat_size);
	int data;
	int valid_dat;

	fil_sram_non_zero_data_r = {`SIM_CHUNK_SIZE{`DAT_SIZE{1'b0}}};
	fil_sram_sparse_map_r = {`SIM_CHUNK_SIZE{1'b0}};

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

int mem_stacking_fil_dat 	= $fopen("Mem_Stacking_Fil_Data.txt", "w");
int mem_stacking_fil_sparsemap 	= $fopen("Mem_Stacking_Fil_SparseMap.txt", "w");

int mem_stacking_ifm_dat 	= $fopen("Mem_Stacking_IFM_Data.txt", "w");
int mem_stacking_ifm_sparsemap 	= $fopen("Mem_Stacking_IFM_SparseMap.txt", "w");

initial begin
	// Gen fil
	begin
		for (int loop_z_idx = 0; loop_z_idx < SIM_LOOP_Z_NUM; loop_z_idx += 1) begin
			if (loop_z_idx == SIM_LOOP_Z_NUM - 1) begin
				fil_sub_chunk_dat_size = `LAYER_FILTER_SIZE_X * SIM_LAST_CHANNEL_SIZE;
			end
			else begin
				fil_sub_chunk_dat_size = `LAYER_FILTER_SIZE_X * `DIVIDED_CHANNEL_NUM;
			end

			for (int chunk_cu_idx = 0; chunk_cu_idx < `COMPUTE_UNIT_NUM; chunk_cu_idx += 1) begin
				gen_fil_buf(fil_sub_chunk_dat_size);
				$fdisplay(mem_stacking_fil_dat, "%h", fil_sram_non_zero_data_r);
				$fdisplay(mem_stacking_fil_sparsemap, "%h", fil_sram_sparse_map_r);
			end
		end
	end
	$fclose(mem_stacking_fil_dat);
	$fclose(mem_stacking_fil_sparsemap);

	// Gen ifm
	begin
		for (int loop_z_idx = 0; loop_z_idx < SIM_LOOP_Z_NUM; loop_z_idx += 1) begin
			if (loop_z_idx == SIM_LOOP_Z_NUM - 1) begin
				ifm_chunk_dat_size = `LAYER_IFM_SIZE_X * SIM_LAST_CHANNEL_SIZE;
			end
			else begin
				ifm_chunk_dat_size = `LAYER_IFM_SIZE_X * `DIVIDED_CHANNEL_NUM;
			end

			//ifm_chunk_dat_wr_cyc_num = (ifm_chunk_dat_size % `BUS_SIZE) ? ifm_chunk_dat_size/`BUS_SIZE + 1 : ifm_chunk_dat_size/`BUS_SIZE;

			for (int ifm_loop_y_idx = 0; ifm_loop_y_idx < `LAYER_IFM_SIZE_Y; ifm_loop_y_idx += 1) begin
				//gen_ifm_buf(ifm_chunk_dat_size, ifm_chunk_dat_wr_cyc_num * `BUS_SIZE);
				gen_ifm_buf(ifm_chunk_dat_size, `SIM_CHUNK_SIZE);
				$fdisplay(mem_stacking_ifm_dat, "%h", ifm_sram_non_zero_data_r);
				$fdisplay(mem_stacking_ifm_sparsemap, "%h", ifm_sram_sparse_map_r);
			end

		end
	end
	$fclose(mem_stacking_ifm_dat);
	$fclose(mem_stacking_ifm_sparsemap);
end

endmodule
