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

logic filter_chunk_wr_valid_i;
logic [$clog2(`WR_DAT_CYC_NUM)-1:0] filter_chunk_wr_count_i ;
logic filter_chunk_wr_sel_i;
logic filter_chunk_rd_sel_i;
logic [`COMPUTE_UNIT_NUM-1:0] filter_chunk_cu_wr_sel_i = 1;
logic [$clog2(`SRAM_FILTER_NUM)-1:0] filter_sram_rd_count_i;

logic run_valid_i;
logic total_chunk_start_i;

`ifdef CHANNEL_STACKING
	logic [$clog2(`PREFIX_SUM_SIZE)-1:0] sparsemap_shift_left_i;
	logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_first_i;
	logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_ifm_sparsemap_next_i;
	logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_first_i;
	logic [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_sparsemap_last_i;
	logic [$clog2(`LAYER_FILTER_SIZE_MAX)-1:0] rd_fil_nonzero_dat_first_i;
`endif

logic total_chunk_end_o;

logic [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_i;
//logic [$clog2(`OUTPUT_BUF_NUM)-1:0] out_buf_sel_i;
logic [$clog2(`COMPUTE_UNIT_NUM)-1:0] com_unit_out_buf_sel_i = 0;
logic [`OUTPUT_BUF_SIZE-1:0] out_buf_dat_o;

logic [`BUS_SIZE-1:0] 			ifm_sram_wr_sparsemap_w;
logic [`BUS_SIZE-1:0][7:0] 		ifm_sram_wr_nonzero_data_w;
logic 					ifm_sram_wr_valid_w;
logic [$clog2(`WR_DAT_CYC_NUM)-1:0] 	ifm_sram_wr_dat_count_w;
logic [$clog2(`SRAM_IFM_NUM)-1:0] 	ifm_sram_wr_chunk_count_w;

logic [`BUS_SIZE-1:0] 			filter_sram_wr_sparsemap_w;
logic [`BUS_SIZE-1:0][7:0] 		filter_sram_wr_nonzero_data_w;
logic 					filter_sram_wr_valid_w;
logic [$clog2(`WR_DAT_CYC_NUM)-1:0]	filter_sram_wr_dat_count_w;
logic [$clog2(`SRAM_FILTER_NUM)-1:0] 	filter_sram_wr_chunk_count_w;

Compute_Cluster_Mem u_Compute_Cluster_Mem (
	 .rst_i
	,.clk_i

	,.ifm_chunk_wr_valid_i
	,.ifm_chunk_wr_count_i
	,.ifm_chunk_wr_sel_i
	,.ifm_chunk_rd_sel_i
	,.ifm_sram_rd_count_i

	,.filter_chunk_wr_valid_i
	,.filter_chunk_wr_count_i
	,.filter_chunk_wr_sel_i
	,.filter_chunk_rd_sel_i
	,.filter_chunk_cu_wr_sel_i
	,.filter_sram_rd_count_i

	,.run_valid_i
	,.total_chunk_start_i

`ifdef CHANNEL_STACKING
	,.sparsemap_shift_left_i
	,.rd_ifm_sparsemap_first_i
	,.rd_ifm_sparsemap_next_i
	,.rd_fil_sparsemap_first_i
	,.rd_fil_sparsemap_last_i
	,.rd_fil_nonzero_dat_first_i
`endif
	,.total_chunk_end_o

	,.acc_buf_sel_i
//	,.out_buf_sel_i
	,.com_unit_out_buf_sel_i
	,.out_buf_dat_o

	,.ifm_sram_wr_sparsemap_i(ifm_sram_wr_sparsemap_w)
	,.ifm_sram_wr_nonzero_data_i(ifm_sram_wr_nonzero_data_w)
	,.ifm_sram_wr_valid_i(ifm_sram_wr_valid_w)
	,.ifm_sram_wr_dat_count_i(ifm_sram_wr_dat_count_w)
	,.ifm_sram_wr_chunk_count_i(ifm_sram_wr_chunk_count_w)

	,.filter_sram_wr_sparsemap_i(filter_sram_wr_sparsemap_w)
	,.filter_sram_wr_nonzero_data_i(filter_sram_wr_nonzero_data_w)
	,.filter_sram_wr_valid_i(filter_sram_wr_valid_w)
	,.filter_sram_wr_dat_count_i(filter_sram_wr_dat_count_w)
	,.filter_sram_wr_chunk_count_i(filter_sram_wr_chunk_count_w)
);

logic mem_gen_start_i;
logic mem_gen_finish_w;

Mem_Gen_Stacking u_Mem_Gen_Stacking (
	 .rst_i
	,.clk_i

	,.mem_gen_start_i
	,.mem_gen_finish_o(mem_gen_finish_w)

	,.mem_ifm_wr_sparsemap_o(ifm_sram_wr_sparsemap_w)
	,.mem_ifm_wr_nonzero_data_o(ifm_sram_wr_nonzero_data_w)
	,.mem_ifm_wr_valid_o(ifm_sram_wr_valid_w)
	,.mem_ifm_wr_dat_count_o(ifm_sram_wr_dat_count_w)
	,.mem_ifm_wr_chunk_count_o(ifm_sram_wr_chunk_count_w)

	,.mem_filter_wr_sparsemap_o(filter_sram_wr_sparsemap_w)
	,.mem_filter_wr_nonzero_data_o(filter_sram_wr_nonzero_data_w)
	,.mem_filter_wr_valid_o(filter_sram_wr_valid_w)
	,.mem_filter_wr_dat_count_o(filter_sram_wr_dat_count_w)
	,.mem_filter_wr_chunk_count_o(filter_sram_wr_chunk_count_w)
);

logic ifm_wr_last_w;

task wr_ifm_chunk(int ifm_sram_rd_count_int);
	ifm_chunk_wr_valid_i = 1;
	ifm_chunk_wr_count_i = 0;
	ifm_chunk_wr_sel_i = ~ifm_chunk_wr_sel_i;
	ifm_chunk_rd_sel_i = ~ifm_chunk_rd_sel_i;
	ifm_sram_rd_count_i = ifm_sram_rd_count_int;
	repeat (`SIM_WR_DAT_CYC_NUM) begin
		@(posedge clk_i) #1;
		ifm_chunk_wr_count_i += 1;
	end
	ifm_chunk_wr_valid_i = 0;
endtask

task wr_filter_chunk(int filter_sram_rd_count_int);
	filter_chunk_wr_valid_i = 1;
	filter_chunk_wr_count_i = 0;
	filter_chunk_wr_sel_i = ~filter_chunk_wr_sel_i;
	filter_chunk_rd_sel_i = ~filter_chunk_rd_sel_i;
	filter_sram_rd_count_i = filter_sram_rd_count_int;
	repeat (`SIM_WR_DAT_CYC_NUM) begin
		@(posedge clk_i) #1;
		filter_chunk_wr_count_i += 1;
	end
	filter_chunk_wr_valid_i = 0;
endtask

event sub_chunk_end_event;

initial begin
forever begin
	@(posedge clk_i);
	if (total_chunk_end_o) begin
		#1;
		-> sub_chunk_end_event;
	end
end
end

// Initiate
initial begin
	int loop_z_num = (`LAYER_CHANNEL_NUM % `DIVIDED_CHANNEL_NUM) ? (`LAYER_CHANNEL_NUM / `DIVIDED_CHANNEL_NUM) + 1 
									 : (`LAYER_CHANNEL_NUM / `DIVIDED_CHANNEL_NUM);
	int ifm_loop_y_num = `LAYER_FILTER_SIZE_X + `LAYER_OUTPUT_SIZE_X - 1;

	int filter_loop_y_idx_last = 1;
	int filter_loop_y_idx_start = 1;

	run_valid_i = 0;
	ifm_chunk_wr_sel_i = 1;
	ifm_chunk_rd_sel_i = 0;
	ifm_sram_rd_count_i = 0;
	filter_chunk_wr_sel_i = 1;
	filter_chunk_rd_sel_i = 0;
	filter_sram_rd_count_i = 0;

	acc_buf_sel_i = 0;
	sparsemap_shift_left_i = 0;

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
	fork
		wr_ifm_chunk(0);
		wr_filter_chunk(0);
	join

	// Start execution	
	@(negedge clk_i) #1;
	run_valid_i = 1'b1;

	for (int loop_z_idx = 1; loop_z_idx <= loop_z_num; loop_z_idx += 1 ) begin
		fork
			wr_filter_chunk(loop_z_idx);
		join_none
		for (int ifm_loop_y_idx = 1; ifm_loop_y_idx <= ifm_loop_y_num; ifm_loop_y_idx += 1) begin
			fork
				begin
					int ifm_sram_rd_count_int =  (loop_z_idx - 1) * loop_z_num + ifm_loop_y_idx;
					wr_ifm_chunk(ifm_sram_rd_count_int);
				end
			join_none
			if (ifm_loop_y_idx < `LAYER_FILTER_SIZE_X) begin
				filter_loop_y_idx_start = 1;
				filter_loop_y_idx_last = ifm_loop_y_idx;
			end
			else if ((`LAYER_FILTER_SIZE_X <= ifm_loop_y_idx) && (ifm_loop_y_idx <= ifm_loop_y_num - `LAYER_FILTER_SIZE_X)) begin
				filter_loop_y_idx_start = 1;
				filter_loop_y_idx_last = `LAYER_FILTER_SIZE_X;
			end
			else begin
				filter_loop_y_idx_start = `LAYER_FILTER_SIZE_X - (ifm_loop_y_num - ifm_loop_y_idx);
				filter_loop_y_idx_last = `LAYER_FILTER_SIZE_X;
			end
			
			for (int filter_loop_y_idx = filter_loop_y_idx_start; filter_loop_y_idx <= filter_loop_y_idx_last; filter_loop_y_idx += 1) begin
				rd_fil_sparsemap_first_i = (filter_loop_y_idx - 1) * `LAYER_FILTER_SIZE_X;
				rd_fil_sparsemap_last_i =  rd_fil_sparsemap_first_i + `LAYER_FILTER_SIZE_X - 1;
				rd_fil_nonzero_dat_first_i = filter_loop_y_idx - 1;

				for (int ifm_loop_x_idx = 1; ifm_loop_x_idx <= `LAYER_OUTPUT_SIZE_X; ifm_loop_x_idx += 1) begin
					rd_ifm_sparsemap_first_i = ifm_loop_x_idx - 1;

					if (ifm_loop_x_idx == `LAYER_OUTPUT_SIZE_X)
						rd_ifm_sparsemap_next_i = 0;
					else
						rd_ifm_sparsemap_next_i = rd_ifm_sparsemap_first_i + 1;

					acc_buf_sel_i = (ifm_loop_y_idx - filter_loop_y_idx) * `LAYER_OUTPUT_SIZE_X + ifm_loop_x_idx - 1;
				//	wait(sub_chunk_end_event.triggered);
					@sub_chunk_end_event;
				end
			end
		end
	end
	$finish();
end

//Generate the total chunk start signal
logic run_valid_delay_r;
logic total_chunk_start_r;
always @(posedge clk_i) begin
	if (rst_i)
		run_valid_delay_r = #1 1'b0;
	else
		run_valid_delay_r = #1 run_valid_i;
end

always @(posedge clk_i) begin
	if (rst_i)
		total_chunk_start_r = #1 1'b0;
	else if (total_chunk_end_o)
		total_chunk_start_r = #1 1'b1;
	else if (total_chunk_start_r)
		total_chunk_start_r = #1 1'b0;
end

assign total_chunk_start_i = run_valid_i && (total_chunk_start_r || (run_valid_i && (!run_valid_delay_r)));


endmodule

