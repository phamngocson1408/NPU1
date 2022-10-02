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
	 localparam int SRAM_CHUNK_SIZE = `MEM_SIZE
 	,localparam int SRAM_IFM_SHIFT_NUM = SRAM_CHUNK_SIZE / `CHANNEL_NUM
	,localparam int SRAM_OUTPUT_NUM = (SRAM_IFM_SHIFT_NUM <= `OUTPUT_BUF_NUM) ? SRAM_IFM_SHIFT_NUM : `OUTPUT_BUF_NUM
 	,localparam int SRAM_IFM_NUM = SRAM_IFM_SHIFT_NUM + SRAM_OUTPUT_NUM
 	,localparam int SRAM_FILTER_NUM = SRAM_IFM_SHIFT_NUM * `COMPUTE_UNIT_NUM
	,localparam int PARAM_WR_DAT_CYC_NUM = `MEM_SIZE/`BUS_SIZE
	,localparam int PARAM_RD_SPARSEMAP_NUM = `MEM_SIZE/`PREFIX_SUM_SIZE
)(
	 input rst_i
	,input clk_i

	,input mem_gen_start_i
	,output logic mem_gen_finish_o

	,output logic [`BUS_SIZE-1:0] 			mem_ifm_wr_sparsemap_o
	,output logic [`BUS_SIZE*8-1:0] 		mem_ifm_wr_nonzero_data_o
	,output logic 					mem_ifm_wr_valid_o
	,output logic [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] mem_ifm_wr_dat_count_o
	,output logic [$clog2(SRAM_IFM_NUM)-1:0] 	mem_ifm_wr_chunk_count_o

	,output logic [`BUS_SIZE-1:0] 			mem_filter_wr_sparsemap_o
	,output logic [`BUS_SIZE*8-1:0] 		mem_filter_wr_nonzero_data_o
	,output logic 					mem_filter_wr_valid_o
	,output logic [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] mem_filter_wr_dat_count_o
	,output logic [$clog2(SRAM_FILTER_NUM)-1:0] 	mem_filter_wr_chunk_count_o
);

localparam int SIM_WR_DAT_CYC_NUM = ((SRAM_CHUNK_SIZE % `BUS_SIZE)!=0) ? SRAM_CHUNK_SIZE / `BUS_SIZE + 1
					: SRAM_CHUNK_SIZE / `BUS_SIZE;

// Gennerate IFM
logic [`MEM_SIZE-1:0][7:0] mem_ifm_non_zero_data_r = {`MEM_SIZE{8'h00}};
logic [`MEM_SIZE-1:0] mem_ifm_sparse_map_r ;

task automatic gen_ifm_buf();
	integer i;
	integer j=0;
	integer data;
	integer valid_dat;

	for (i=0; i<SRAM_CHUNK_SIZE; i=i+1) begin
`ifdef SHORT_CHANNEL
 `ifdef CHANNEL_PADDING
 		if (i < `CHANNEL_NUM) begin
 			data = $urandom_range(256,1);
 			valid_dat = $urandom_range(100,0);
 		end
 		else begin
 			data = 0;
 			valid_dat = 100;
 		end
 `else
 		data = $urandom_range(256,1);
 		valid_dat = $urandom_range(100,0);
 `endif
`elsif FULL_CHANNEL
 		data = $urandom_range(256,1);
 		valid_dat = $urandom_range(100,0);
`endif
		if (valid_dat <= `IFM_DENSE_RATE) begin
			mem_ifm_non_zero_data_r[j] = data;
			mem_ifm_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			mem_ifm_sparse_map_r[i] = 0;
		end
	end
endtask

task wr_ifm_buf();
	mem_ifm_wr_valid_o = 1'b1;
	mem_ifm_wr_chunk_count_o = 0;
	repeat (SRAM_IFM_NUM) begin
		gen_ifm_buf();
		mem_ifm_wr_dat_count_o = 0;
		repeat(SIM_WR_DAT_CYC_NUM) begin
			mem_ifm_wr_sparsemap_o = mem_ifm_sparse_map_r[`BUS_SIZE*mem_ifm_wr_dat_count_o +: `BUS_SIZE];
			mem_ifm_wr_nonzero_data_o = mem_ifm_non_zero_data_r[`BUS_SIZE*mem_ifm_wr_dat_count_o +: `BUS_SIZE];
			@(posedge clk_i);
			mem_ifm_wr_dat_count_o = mem_ifm_wr_dat_count_o + 1;
		end
		mem_ifm_wr_chunk_count_o = mem_ifm_wr_chunk_count_o + 1;
	end
	mem_ifm_wr_valid_o = 1'b0;
endtask

//Generate Filer
logic [`MEM_SIZE-1:0][7:0] mem_filter_non_zero_data_r = {`MEM_SIZE{8'h00}};
logic [`MEM_SIZE-1:0] mem_filter_sparse_map_r ;

task automatic gen_filter_buf();
	integer i;
	integer j=0;
	integer data;
	integer valid_dat;

	for (i=0; i<SRAM_CHUNK_SIZE; i=i+1) begin
`ifdef SHORT_CHANNEL
 `ifdef CHANNEL_PADDING
 		if (i < `CHANNEL_NUM) begin
 			data = $urandom_range(256,1);
 			valid_dat = $urandom_range(100,0);
 		end
 		else begin
 			data = 0;
 			valid_dat = 100;
 		end
 `else
 		data = $urandom_range(256,1);
 		valid_dat = $urandom_range(100,0);
 `endif
`else	// not define SHORT_CHANNEL
 		data = $urandom_range(256,1);
 		valid_dat = $urandom_range(100,0);
`endif
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

task wr_filter_buf();
	mem_filter_wr_valid_o = 1'b1;
	mem_filter_wr_chunk_count_o = 0;
	repeat (SRAM_FILTER_NUM) begin
		gen_filter_buf();
		mem_filter_wr_dat_count_o = 0;
		repeat(SIM_WR_DAT_CYC_NUM) begin
			mem_filter_wr_sparsemap_o = mem_filter_sparse_map_r[`BUS_SIZE*mem_filter_wr_dat_count_o +: `BUS_SIZE];
			mem_filter_wr_nonzero_data_o = mem_filter_non_zero_data_r[`BUS_SIZE*mem_filter_wr_dat_count_o +: `BUS_SIZE];
			@(posedge clk_i);
			mem_filter_wr_dat_count_o = mem_filter_wr_dat_count_o + 1;
		end
		mem_filter_wr_chunk_count_o = mem_filter_wr_chunk_count_o + 1;
	end
	mem_filter_wr_valid_o = 1'b0;
endtask

initial begin
	forever begin
		if (mem_gen_start_i) begin
			fork
				wr_ifm_buf();
				wr_filter_buf();
			join
			mem_gen_finish_o = 1'b1;
			@(posedge clk_i);
			mem_gen_finish_o = 1'b0;
		end
		else begin
			@(posedge clk_i);
		end
	end
end

endmodule
