`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// This module is test the Compute_Cluster_Mem
//////////////////////////////////////////////////////////////////////////////////


module Compute_Cluster_Mem_tb(
    );

//CLock generate
reg clk_i;
initial begin
	clk_i=0;
	#(`CYCLE/2);
	while (1) begin
		clk_i = ~clk_i;
		#(`CYCLE/2);
	end
end

//Reset generate
reg rst_i;
initial begin
	rst_i = 1;
	#(`CYCLE*100);
	@(posedge clk_i);
	rst_i = 0;
end

//DUT instance
logic ifm_chunk_wr_valid_i;
logic [$clog2(`WR_DAT_CYC_NUM)-1:0] ifm_chunk_wr_count_i ;
logic ifm_chunk_wr_sel_i;
logic ifm_chunk_rd_sel_i;
logic [$clog2(`SRAM_IFM_NUM)-1:0] ifm_sram_rd_count_i;

logic fil_chunk_wr_valid_i;
logic [$clog2(`WR_DAT_CYC_NUM)-1:0] fil_chunk_wr_count_i ;
logic fil_chunk_wr_sel_i;
logic fil_chunk_rd_sel_i;
logic [`COMPUTE_UNIT_NUM-1:0] fil_chunk_cu_wr_sel_i = 1;
logic [$clog2(`SRAM_FILTER_NUM)-1:0] fil_sram_rd_count_i, fil_sram_rd_count_r;

logic run_valid_i;

`ifdef CHANNEL_PADDING
logic total_chunk_start_i;
logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_last_i;
logic [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_i;
`endif

logic total_chunk_end_o;

logic [$clog2(`COMPUTE_UNIT_NUM)-1:0] com_unit_out_buf_sel_i = 0;
logic [`OUTPUT_BUF_SIZE-1:0] out_buf_dat_o;

logic [`BUS_SIZE-1:0] 			ifm_sram_wr_sparsemap_w;
logic [`BUS_SIZE-1:0][7:0] 		ifm_sram_wr_nonzero_data_w;
logic 					ifm_sram_wr_valid_w;
logic [$clog2(`WR_DAT_CYC_NUM)-1:0] 	ifm_sram_wr_dat_count_w;
logic [$clog2(`SRAM_IFM_NUM)-1:0] 	ifm_sram_wr_chunk_count_w;

logic [`BUS_SIZE-1:0] 			fil_sram_wr_sparsemap_w;
logic [`BUS_SIZE-1:0][7:0] 		fil_sram_wr_nonzero_data_w;
logic 					fil_sram_wr_valid_w;
logic [$clog2(`WR_DAT_CYC_NUM)-1:0]	fil_sram_wr_dat_count_w;
logic [$clog2(`SRAM_FILTER_NUM)-1:0] 	fil_sram_wr_chunk_count_w;

`ifdef CHANNEL_STACKING
logic inner_loop_start;
int ifm_loop_y_idx;
int fil_loop_y_idx_start;
int fil_loop_y_idx_last;
int fil_loop_y_step;
int sub_channel_size;
logic total_inner_loop_finish_o;
`endif

Compute_Cluster_Mem u_Compute_Cluster_Mem (
	 .rst_i
	,.clk_i

	,.ifm_chunk_wr_valid_i
	,.ifm_chunk_wr_count_i
	,.ifm_chunk_wr_sel_i
	,.ifm_chunk_rd_sel_i
	,.ifm_sram_rd_count_i

	,.fil_chunk_wr_valid_i
	,.fil_chunk_wr_count_i
	,.fil_chunk_wr_sel_i
	,.fil_chunk_rd_sel_i
	,.fil_chunk_cu_wr_sel_i
	,.fil_sram_rd_count_i

	,.run_valid_i

`ifdef CHANNEL_STACKING
	,.inner_loop_start_i	(inner_loop_start)	
	,.ifm_loop_y_idx_i	(ifm_loop_y_idx)
	,.fil_loop_y_idx_start_i(fil_loop_y_idx_start)
	,.fil_loop_y_idx_last_i	(fil_loop_y_idx_last)
	,.fil_loop_y_step_i	(fil_loop_y_step)	
	,.sub_channel_size_i	(sub_channel_size)	
	,.total_inner_loop_finish_o
`elsif CHANNEL_PADDING
	,.total_chunk_start_i
	,.rd_fil_sparsemap_last_i
	,.acc_buf_sel_i
`endif
	,.total_chunk_end_o

	,.com_unit_out_buf_sel_i
	,.out_buf_dat_o

	,.ifm_sram_wr_sparsemap_i(ifm_sram_wr_sparsemap_w)
	,.ifm_sram_wr_nonzero_data_i(ifm_sram_wr_nonzero_data_w)
	,.ifm_sram_wr_valid_i(ifm_sram_wr_valid_w)
	,.ifm_sram_wr_dat_count_i(ifm_sram_wr_dat_count_w)
	,.ifm_sram_wr_chunk_count_i(ifm_sram_wr_chunk_count_w)

	,.fil_sram_wr_sparsemap_i(fil_sram_wr_sparsemap_w)
	,.fil_sram_wr_nonzero_data_i(fil_sram_wr_nonzero_data_w)
	,.fil_sram_wr_valid_i(fil_sram_wr_valid_w)
	,.fil_sram_wr_dat_count_i(fil_sram_wr_dat_count_w)
	,.fil_sram_wr_chunk_count_i(fil_sram_wr_chunk_count_w)
);

logic mem_gen_start_i;
logic mem_gen_finish_w;

`ifdef CHANNEL_STACKING
Mem_Gen_Stacking u_Mem_Gen_Stacking (
`elsif CHANNEL_PADDING
Mem_Gen_Padding u_Mem_Gen_Padding (
`endif
	 .rst_i
	,.clk_i

	,.mem_gen_start_i
	,.mem_gen_finish_o(mem_gen_finish_w)

	,.ifm_sram_wr_sparsemap_o(ifm_sram_wr_sparsemap_w)
	,.ifm_sram_wr_nonzero_data_o(ifm_sram_wr_nonzero_data_w)
	,.ifm_sram_wr_valid_o(ifm_sram_wr_valid_w)
	,.ifm_sram_wr_dat_count_o(ifm_sram_wr_dat_count_w)
	,.ifm_sram_wr_chunk_count_o(ifm_sram_wr_chunk_count_w)

	,.fil_sram_wr_sparsemap_o(fil_sram_wr_sparsemap_w)
	,.fil_sram_wr_nonzero_data_o(fil_sram_wr_nonzero_data_w)
	,.fil_sram_wr_valid_o(fil_sram_wr_valid_w)
	,.fil_sram_wr_dat_count_o(fil_sram_wr_dat_count_w)
	,.fil_sram_wr_chunk_count_o(fil_sram_wr_chunk_count_w)
);

logic [31:0] total_ifm_dat_rd_num_r = 0;
logic [31:0] total_fil_dat_rd_num_r = 0;
logic [31:0] total_dat_rd_num_r;
assign total_dat_rd_num_r = total_ifm_dat_rd_num_r + total_fil_dat_rd_num_r;

task wr_ifm_chunk(int ifm_chunk_dat_wr_cyc_num);
	ifm_chunk_wr_valid_i = 1;
	ifm_chunk_wr_count_i = 0;
	ifm_chunk_wr_sel_i = ~ifm_chunk_wr_sel_i;
	ifm_chunk_rd_sel_i = ~ifm_chunk_rd_sel_i;
	repeat (ifm_chunk_dat_wr_cyc_num) begin
		@(posedge clk_i) #1;
		ifm_chunk_wr_count_i += 1;
		total_ifm_dat_rd_num_r += `BUS_SIZE;
	end
	ifm_chunk_wr_valid_i = 0;
endtask

task wr_fil_chunk(int fil_chunk_dat_wr_cyc_num);
	fil_chunk_wr_valid_i = 1;
	fil_chunk_wr_sel_i = ~fil_chunk_wr_sel_i;
	fil_chunk_rd_sel_i = ~fil_chunk_rd_sel_i;

	for (int cu_idx = 0; cu_idx < `COMPUTE_UNIT_NUM; cu_idx += 1) begin
		fil_sram_rd_count_i = fil_sram_rd_count_r * `COMPUTE_UNIT_NUM + cu_idx;
		if (cu_idx == 0)
			fil_chunk_cu_wr_sel_i = 1;
		else
			fil_chunk_cu_wr_sel_i = 1 << cu_idx;

		fil_chunk_wr_count_i = 0;
		repeat (fil_chunk_dat_wr_cyc_num) begin
			@(posedge clk_i) #1;
			fil_chunk_wr_count_i += 1;
			total_fil_dat_rd_num_r += `BUS_SIZE;
		end
	end
	fil_chunk_wr_valid_i = 0;
endtask

event sub_chunk_end_event;

initial begin
forever begin
	@(posedge clk_i);
	if (total_chunk_end_o) begin
	//	#1;
		-> sub_chunk_end_event;
	end
end
end

// Initiate
`ifdef CHANNEL_STACKING
localparam int SIM_LOOP_Z_NUM = (`LAYER_CHANNEL_NUM % `DIVIDED_CHANNEL_NUM) ? (`LAYER_CHANNEL_NUM / `DIVIDED_CHANNEL_NUM) + 1 : (`LAYER_CHANNEL_NUM / `DIVIDED_CHANNEL_NUM);
localparam int SIM_LAST_CHANNEL_SIZE = (`LAYER_CHANNEL_NUM % `DIVIDED_CHANNEL_NUM) ? (`LAYER_CHANNEL_NUM % `DIVIDED_CHANNEL_NUM) : `DIVIDED_CHANNEL_NUM;

int fil_chunk_dat_size = `LAYER_FILTER_SIZE_X * `LAYER_FILTER_SIZE_Y * `DIVIDED_CHANNEL_NUM;
int fil_chunk_dat_wr_cyc_num = (fil_chunk_dat_size % `BUS_SIZE) ? fil_chunk_dat_size/`BUS_SIZE + 1 : fil_chunk_dat_size/`BUS_SIZE;
int ifm_chunk_dat_size;
int ifm_chunk_dat_wr_cyc_num;

int loop_z_idx;


int fil_loop_y_idx;
int fil_loop_y_dat_size;

int ifm_loop_x_idx;
int ifm_loop_x_dat_start;

initial begin
	run_valid_i = 0;
	ifm_chunk_wr_sel_i = 1;
	ifm_chunk_rd_sel_i = 0;
	ifm_sram_rd_count_i = 0;
	fil_chunk_wr_sel_i = 1;
	fil_chunk_rd_sel_i = 0;
	fil_sram_rd_count_r = 0;

	@(negedge rst_i) ;
	@(posedge clk_i) #1;

	// Write mem
	mem_gen_start_i = 1'b1;
	fork
		begin
			@(posedge clk_i) #1;
			mem_gen_start_i = 1'b0;
		end
	join_none

	// Finish wrting mem
	@(posedge mem_gen_finish_w);

	// Read mem to chunks
	if (SIM_LOOP_Z_NUM == 1)
		sub_channel_size = SIM_LAST_CHANNEL_SIZE;
	else
		sub_channel_size = `DIVIDED_CHANNEL_NUM;

	fork
		begin
			wr_fil_chunk(fil_chunk_dat_wr_cyc_num);
		end
		begin
			ifm_chunk_dat_size = `LAYER_IFM_SIZE_X * sub_channel_size;
			ifm_chunk_dat_wr_cyc_num = (ifm_chunk_dat_size % `BUS_SIZE) ? ifm_chunk_dat_size/`BUS_SIZE + 1 : ifm_chunk_dat_size/`BUS_SIZE;
			wr_ifm_chunk(ifm_chunk_dat_wr_cyc_num);
		end
	join

	// Start execution	
	@(negedge clk_i) #1;
	run_valid_i = 1'b1;

	for (loop_z_idx = 0; loop_z_idx < SIM_LOOP_Z_NUM; loop_z_idx += 1 ) begin
		if (loop_z_idx == SIM_LOOP_Z_NUM-1)
			sub_channel_size = SIM_LAST_CHANNEL_SIZE;
		else
			sub_channel_size = `DIVIDED_CHANNEL_NUM;

		fil_loop_y_dat_size = `LAYER_FILTER_SIZE_X * sub_channel_size;
		fil_loop_y_step = (fil_loop_y_dat_size % `PREFIX_SUM_SIZE) ? fil_loop_y_dat_size / `PREFIX_SUM_SIZE + 1 : fil_loop_y_dat_size / `PREFIX_SUM_SIZE;

		fork begin
			fil_sram_rd_count_r = loop_z_idx + 1;
			wr_fil_chunk(fil_chunk_dat_wr_cyc_num);
		end join_none


		for (ifm_loop_y_idx = 0; ifm_loop_y_idx < `LAYER_IFM_SIZE_Y; ifm_loop_y_idx += 1) begin
			fork begin
					ifm_sram_rd_count_i =  loop_z_idx * `LAYER_IFM_SIZE_Y + ifm_loop_y_idx + 1;
					ifm_chunk_dat_size = `LAYER_IFM_SIZE_X * sub_channel_size;
					ifm_chunk_dat_wr_cyc_num = (ifm_chunk_dat_size % `BUS_SIZE) ? ifm_chunk_dat_size/`BUS_SIZE + 1 : ifm_chunk_dat_size/`BUS_SIZE;
					wr_ifm_chunk(ifm_chunk_dat_wr_cyc_num);
			end join_none

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

			inner_loop_start = 1;
			fork
			begin
				@ (posedge clk_i);
				inner_loop_start = 0;
			end
			join_none

			@ (posedge total_inner_loop_finish_o);
			@ (posedge clk_i);
		end
	end
	$finish();
end

`elsif CHANNEL_PADDING
localparam int SIM_LOOP_Z_NUM = (`LAYER_CHANNEL_NUM % `SIM_CHUNK_SIZE) ? (`LAYER_CHANNEL_NUM / `SIM_CHUNK_SIZE) + 1 
							: (`LAYER_CHANNEL_NUM / `SIM_CHUNK_SIZE);
int chunk_dat_size;
int chunk_dat_wr_cyc_num;
assign	rd_fil_sparsemap_last_i =  chunk_dat_wr_cyc_num - 1;

initial begin
	run_valid_i = 0;
	ifm_chunk_wr_sel_i = 1;
	ifm_chunk_rd_sel_i = 0;
	ifm_sram_rd_count_i = 0;
	fil_chunk_wr_sel_i = 1;
	fil_chunk_rd_sel_i = 0;
	fil_sram_rd_count_r = 0;

	acc_buf_sel_i = 0;

	@(negedge rst_i) ;
	@(posedge clk_i) #1;

	// Write mem
	mem_gen_start_i = 1'b1;
	fork
		begin
			@(posedge clk_i) #1;
			mem_gen_start_i = 1'b0;
		end
	join_none

	// Finish wrting mem
	@(posedge mem_gen_finish_w);

	// Read mem to chunks
	if (SIM_LOOP_Z_NUM == 1)
		chunk_dat_size = `LAYER_CHANNEL_NUM % `SIM_CHUNK_SIZE;
	else
		chunk_dat_size = `SIM_CHUNK_SIZE;

	chunk_dat_wr_cyc_num = (chunk_dat_size % `BUS_SIZE) ? chunk_dat_size/`BUS_SIZE + 1 : chunk_dat_size/`BUS_SIZE;
	fork
		wr_fil_chunk(chunk_dat_wr_cyc_num);
		wr_ifm_chunk(chunk_dat_wr_cyc_num);
	join

	// Start execution	
	@(negedge clk_i) #1;
	run_valid_i = 1'b1;

	for (int loop_z_idx = 0; loop_z_idx < SIM_LOOP_Z_NUM; loop_z_idx += 1 ) begin
		if (loop_z_idx == SIM_LOOP_Z_NUM - 1)
			chunk_dat_size = `LAYER_CHANNEL_NUM % `SIM_CHUNK_SIZE;
		else
			chunk_dat_size = `SIM_CHUNK_SIZE;

		chunk_dat_wr_cyc_num = (chunk_dat_size % `BUS_SIZE) ? chunk_dat_size/`BUS_SIZE + 1 : chunk_dat_size/`BUS_SIZE;

		for (int fil_y_idx = 0; fil_y_idx < `LAYER_FILTER_SIZE_Y; fil_y_idx += 1) begin
			for (int fil_x_idx = 0; fil_x_idx < `LAYER_FILTER_SIZE_X; fil_x_idx += 1) begin
				fork begin
					fil_sram_rd_count_r = (loop_z_idx * `LAYER_FILTER_SIZE_Y * `LAYER_FILTER_SIZE_X) + (fil_y_idx * `LAYER_FILTER_SIZE_X) + fil_x_idx + 1;
					wr_fil_chunk(chunk_dat_wr_cyc_num);
				end join_none

				for (int ifm_y_idx = fil_y_idx; ifm_y_idx < `LAYER_OUTPUT_SIZE_Y + fil_y_idx; ifm_y_idx += 1) begin
					for (int ifm_x_idx = fil_x_idx; ifm_x_idx < `LAYER_OUTPUT_SIZE_X + fil_x_idx; ifm_x_idx += 1) begin
						fork begin
							ifm_sram_rd_count_i = (loop_z_idx * `LAYER_IFM_SIZE_Y * `LAYER_IFM_SIZE_X) + (ifm_y_idx * `LAYER_IFM_SIZE_X) + ifm_x_idx + 1;
							wr_ifm_chunk(chunk_dat_wr_cyc_num);
						end join_none

						acc_buf_sel_i = (ifm_y_idx - fil_y_idx) * `LAYER_OUTPUT_SIZE_X + ifm_x_idx - fil_x_idx;
						@sub_chunk_end_event;
					end
				end
			end
		end
	end
	$finish();
end
`endif

//Generate the total chunk start signal
logic run_valid_delay_r;
logic total_chunk_start_r;
always_ff @(posedge clk_i) begin
	if (rst_i)
		run_valid_delay_r <= 1'b0;
	else
		run_valid_delay_r <=  run_valid_i;
end

always_ff @(posedge clk_i) begin
	if (rst_i)
		total_chunk_start_r <= 1'b0;
	else if (total_chunk_end_o)
		total_chunk_start_r <= 1'b1;
	else if (total_chunk_start_r)
		total_chunk_start_r <= 1'b0;
end

`ifdef CHANNEL_PADDING
assign total_chunk_start_i = run_valid_i && (total_chunk_start_r || (run_valid_i && (!run_valid_delay_r)));
`endif


endmodule

