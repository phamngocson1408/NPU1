`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/07/2023 03:12:12 PM
// 
//////////////////////////////////////////////////////////////////////////////////


module Mem_Gen_Padding_File #(
)(
);

// Gennerate IFM
logic [`SIM_CHUNK_SIZE-1:0][`DAT_SIZE-1:0] ifm_sram_non_zero_data_r = {`SIM_CHUNK_SIZE{`DAT_SIZE{1'b0}}};
logic [`SIM_CHUNK_SIZE-1:0] ifm_sram_sparse_map_r;

task automatic gen_ifm_buf(int chunk_dat_size);
	int j=0;
	int data;
	int valid_dat;

	ifm_sram_non_zero_data_r = {`SIM_CHUNK_SIZE{`DAT_SIZE{1'b0}}};
	ifm_sram_sparse_map_r = {`SIM_CHUNK_SIZE{1'b0}};

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

	fil_sram_non_zero_data_r = {`SIM_CHUNK_SIZE{`DAT_SIZE{1'b0}}};
	fil_sram_sparse_map_r = {`SIM_CHUNK_SIZE{1'b0}};

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

int loop_z_num = (`LAYER_CHANNEL_NUM % `SIM_CHUNK_SIZE) ? (`LAYER_CHANNEL_NUM / `SIM_CHUNK_SIZE) + 1 
		: (`LAYER_CHANNEL_NUM / `SIM_CHUNK_SIZE);
localparam int SIM_LAST_CHANNEL_SIZE = (`LAYER_CHANNEL_NUM % `SIM_CHUNK_SIZE) ? (`LAYER_CHANNEL_NUM % `SIM_CHUNK_SIZE) : `SIM_CHUNK_SIZE;
int fil_chunk_dat_size;
int ifm_chunk_dat_size;

int mem_padding_fil_dat 	= $fopen("Mem_Padding_Fil_Data.txt", "w");
int mem_padding_fil_sparsemap 	= $fopen("Mem_Padding_Fil_SparseMap.txt", "w");

int mem_padding_ifm_dat 	= $fopen("Mem_Padding_IFM_Data.txt", "w");
int mem_padding_ifm_sparsemap 	= $fopen("Mem_Padding_IFM_SparseMap.txt", "w");

initial begin

	// Gen fil
	begin
		for (int fil_z_idx = 0; fil_z_idx < loop_z_num; fil_z_idx += 1) begin
			if (fil_z_idx == loop_z_num - 1) begin
				fil_chunk_dat_size = SIM_LAST_CHANNEL_SIZE;
			end
			else begin
				fil_chunk_dat_size = `SIM_CHUNK_SIZE;
			end

			for (int fil_y_idx = 0; fil_y_idx < `LAYER_FILTER_SIZE_Y; fil_y_idx += 1) begin
				for (int fil_x_idx = 0; fil_x_idx < `LAYER_FILTER_SIZE_X; fil_x_idx += 1) begin
					for (int chunk_cu_idx = 0; chunk_cu_idx < `COMPUTE_UNIT_NUM; chunk_cu_idx += 1) begin
						gen_fil_buf(fil_chunk_dat_size);
						$fdisplay(mem_padding_fil_dat, "%h", fil_sram_non_zero_data_r);
						$fdisplay(mem_padding_fil_sparsemap, "%h", fil_sram_sparse_map_r);
					end
				end
			end
		end
	end
	$fclose(mem_padding_fil_dat);
	$fclose(mem_padding_fil_sparsemap);

	// Gen ifm
	begin
		for (integer ifm_z_idx = 0; ifm_z_idx < loop_z_num; ifm_z_idx += 1) begin
			if (ifm_z_idx == loop_z_num - 1) begin
				ifm_chunk_dat_size = SIM_LAST_CHANNEL_SIZE;
			end
			else begin
				ifm_chunk_dat_size = `SIM_CHUNK_SIZE;
			end

			for (integer ifm_y_idx = 0; ifm_y_idx < `LAYER_IFM_SIZE_Y; ifm_y_idx += 1) begin
				for (integer ifm_x_idx = 0; ifm_x_idx < `LAYER_IFM_SIZE_X; ifm_x_idx += 1) begin
					gen_ifm_buf(ifm_chunk_dat_size);
					$fdisplay(mem_padding_ifm_dat, "%h", ifm_sram_non_zero_data_r);
					$fdisplay(mem_padding_ifm_sparsemap, "%h", ifm_sram_sparse_map_r);
				end
			end
		end
	end
	$fclose(mem_padding_ifm_dat);
	$fclose(mem_padding_ifm_sparsemap);
end

endmodule
