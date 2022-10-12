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
	#(`CYCLE*500);
	@(posedge clk_i);
	rst_i = 0;
end

//Instance
`ifdef SHORT_CHANNEL
 `ifdef CHANNEL_STACKING
	localparam int SIM_CHUNK_DAT_SIZE = (`MEM_SIZE / `CHANNEL_NUM) * `CHANNEL_NUM;
 	localparam int SIM_FILTER_REF_NUM = 1;
 	localparam int SIM_IFM_SHIFT_NUM = SIM_CHUNK_DAT_SIZE / `CHANNEL_NUM;
	localparam int SIM_OUTPUT_NUM = (SIM_IFM_SHIFT_NUM <= `OUTPUT_BUF_NUM) ? SIM_IFM_SHIFT_NUM : `OUTPUT_BUF_NUM;
 `elsif CHANNEL_PADDING
	localparam int SIM_CHUNK_DAT_SIZE = `CHANNEL_NUM;
 	localparam int SIM_FILTER_REF_NUM = `MEM_SIZE / SIM_CHUNK_DAT_SIZE;
 	localparam int SIM_IFM_SHIFT_NUM = 1;
	localparam int SIM_OUTPUT_NUM = (SIM_FILTER_REF_NUM <= `OUTPUT_BUF_NUM) ? SIM_FILTER_REF_NUM : `OUTPUT_BUF_NUM;
 `endif
`elsif FULL_CHANNEL
 `ifdef CHANNEL_STACKING
	localparam int SIM_CHUNK_DAT_SIZE = `MEM_SIZE;
 	localparam int SIM_FILTER_REF_NUM = SIM_CHUNK_DAT_SIZE / `CHANNEL_NUM;
 	localparam int SIM_IFM_SHIFT_NUM = SIM_CHUNK_DAT_SIZE / `CHANNEL_NUM;
	localparam int SIM_OUTPUT_NUM = (SIM_IFM_SHIFT_NUM <= `OUTPUT_BUF_NUM) ? SIM_IFM_SHIFT_NUM : `OUTPUT_BUF_NUM;
 `elsif CHANNEL_PADDING
	localparam int SIM_CHUNK_DAT_SIZE = `MEM_SIZE;
 	localparam int SIM_FILTER_REF_NUM = SIM_CHUNK_DAT_SIZE / `CHANNEL_NUM;
 	localparam int SIM_IFM_SHIFT_NUM = 1;
	localparam int SIM_OUTPUT_NUM = (SIM_FILTER_REF_NUM <= `OUTPUT_BUF_NUM) ? SIM_FILTER_REF_NUM : `OUTPUT_BUF_NUM;
 `endif
`endif

localparam int SIM_WR_DAT_CYC_NUM = ((SIM_CHUNK_DAT_SIZE % `BUS_SIZE)!=0) ? SIM_CHUNK_DAT_SIZE / `BUS_SIZE + 1
					: SIM_CHUNK_DAT_SIZE / `BUS_SIZE;
localparam int SIM_RD_SPARSEMAP_NUM = ((SIM_CHUNK_DAT_SIZE % `PREFIX_SUM_SIZE)!=0) ? SIM_CHUNK_DAT_SIZE / `PREFIX_SUM_SIZE + 1
					: SIM_CHUNK_DAT_SIZE / `PREFIX_SUM_SIZE;

localparam int PARAM_WR_DAT_CYC_NUM = `MEM_SIZE/`BUS_SIZE;
localparam int PARAM_RD_SPARSEMAP_NUM = `MEM_SIZE/`PREFIX_SUM_SIZE;

localparam int SRAM_CHUNK_SIZE = `MEM_SIZE;
localparam int SRAM_IFM_SHIFT_NUM = SRAM_CHUNK_SIZE / `CHANNEL_NUM;
localparam int SRAM_OUTPUT_NUM = (SRAM_IFM_SHIFT_NUM <= `OUTPUT_BUF_NUM) ? SRAM_IFM_SHIFT_NUM : `OUTPUT_BUF_NUM;
localparam int SRAM_IFM_NUM = SRAM_IFM_SHIFT_NUM + SRAM_OUTPUT_NUM;
localparam int SRAM_FILTER_NUM = SRAM_IFM_SHIFT_NUM * `COMPUTE_UNIT_NUM;

//DUT instance
logic ifm_wr_valid_i, ifm_wr_valid_r;
logic [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] ifm_wr_count_i ;
logic ifm_wr_count_last_w;
logic ifm_wr_sel_i;
logic ifm_rd_sel_i;
logic [$clog2(SRAM_IFM_NUM)-1:0] ifm_wr_chunk_count_i;

logic filter_wr_valid_i, filter_wr_valid_r;
logic [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] filter_wr_count_i ;
logic filter_wr_count_last_w;
logic filter_wr_sel_i;
logic filter_rd_sel_i;
logic [`COMPUTE_UNIT_NUM-1:0] filter_wr_chunk_sel_i;
logic [$clog2(SRAM_FILTER_NUM)-1:0] filter_rd_sram_count_i;

logic run_valid_i, run_valid_r;
logic total_chunk_start_i;
logic [$clog2(PARAM_RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_last_i;

`ifdef CHANNEL_STACKING
	logic [$clog2(`PREFIX_SUM_SIZE)-1:0] shift_left_i;
	logic [$clog2(PARAM_RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_step_i;
`elsif CHANNEL_PADDING
	logic [$clog2(`PREFIX_SUM_SIZE)-1:0] shift_left_i = 0;
	logic [$clog2(PARAM_RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_step_i = 0;
`endif

logic total_chunk_end_o;

logic [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_i;
logic [$clog2(`OUTPUT_BUF_NUM)-1:0] out_buf_sel_i;
logic [$clog2(`COMPUTE_UNIT_NUM)-1:0] com_unit_out_buf_sel_i = 0;
logic [`OUTPUT_BUF_SIZE-1:0] out_buf_dat_o;

logic [`BUS_SIZE-1:0] 			 mem_ifm_wr_sparsemap_w;
logic [`BUS_SIZE-1:0][7:0] 		 mem_ifm_wr_nonzero_data_w;
logic 					 mem_ifm_wr_valid_w;
logic [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] mem_ifm_wr_dat_count_w;
logic [$clog2(SRAM_IFM_NUM)-1:0] 	 mem_ifm_wr_sram_count_w;

logic [`BUS_SIZE-1:0] 			 mem_filter_wr_sparsemap_w;
logic [`BUS_SIZE-1:0][7:0] 		 mem_filter_wr_nonzero_data_w;
logic 					 mem_filter_wr_valid_w;
logic [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] mem_filter_wr_dat_count_w;
logic [$clog2(SRAM_FILTER_NUM)-1:0] 	 mem_filter_wr_sram_count_w;

Compute_Cluster_Mem u_Compute_Cluster_Mem (
	 .rst_i
	,.clk_i

	,.ifm_wr_valid_i
	,.ifm_wr_count_i
	,.ifm_wr_sel_i
	,.ifm_rd_sel_i
	,.ifm_wr_chunk_count_i

	,.filter_wr_valid_i
	,.filter_wr_count_i
	,.filter_wr_sel_i
	,.filter_rd_sel_i
	,.filter_wr_chunk_sel_i
	,.filter_rd_sram_count_i

	,.run_valid_i
	,.total_chunk_start_i
	,.rd_sparsemap_last_i

`ifdef CHANNEL_STACKING
       ,.shift_left_i
       ,.rd_sparsemap_step_i
`endif
	,.total_chunk_end_o

	,.acc_buf_sel_i
	,.out_buf_sel_i
	,.com_unit_out_buf_sel_i
	,.out_buf_dat_o

	,.mem_ifm_wr_sparsemap_i(mem_ifm_wr_sparsemap_w)
	,.mem_ifm_wr_nonzero_data_i(mem_ifm_wr_nonzero_data_w)
	,.mem_ifm_wr_valid_i(mem_ifm_wr_valid_w)
	,.mem_ifm_wr_dat_count_i(mem_ifm_wr_dat_count_w)
	,.mem_ifm_wr_chunk_count_i(mem_ifm_wr_sram_count_w)

	,.mem_filter_wr_sparsemap_i(mem_filter_wr_sparsemap_w)
	,.mem_filter_wr_nonzero_data_i(mem_filter_wr_nonzero_data_w)
	,.mem_filter_wr_valid_i(mem_filter_wr_valid_w)
	,.mem_filter_wr_dat_count_i(mem_filter_wr_dat_count_w)
	,.mem_filter_wr_chunk_count_i(mem_filter_wr_sram_count_w)
);

logic mem_gen_start_i;
logic mem_gen_finish_w;

Mem_Gen u_Mem_Gen (
	 .rst_i
	,.clk_i

	,.mem_gen_start_i
	,.mem_gen_finish_o(mem_gen_finish_w)

	,.mem_ifm_wr_sparsemap_o(mem_ifm_wr_sparsemap_w)
	,.mem_ifm_wr_nonzero_data_o(mem_ifm_wr_nonzero_data_w)
	,.mem_ifm_wr_valid_o(mem_ifm_wr_valid_w)
	,.mem_ifm_wr_dat_count_o(mem_ifm_wr_dat_count_w)
	,.mem_ifm_wr_chunk_count_o(mem_ifm_wr_sram_count_w)

	,.mem_filter_wr_sparsemap_o(mem_filter_wr_sparsemap_w)
	,.mem_filter_wr_nonzero_data_o(mem_filter_wr_nonzero_data_w)
	,.mem_filter_wr_valid_o(mem_filter_wr_valid_w)
	,.mem_filter_wr_dat_count_o(mem_filter_wr_dat_count_w)
	,.mem_filter_wr_chunk_count_o(mem_filter_wr_sram_count_w)
);

integer filter_ref_num;
integer ifm_shift_num;

logic ifm_wr_last_w;

// wr_ifm_chunk
always_ff @(posedge clk_i) begin
	if (rst_i) begin
		ifm_wr_valid_i <= 0;
		ifm_wr_count_i <= 0;
		ifm_wr_chunk_count_i <= 0;
		ifm_wr_sel_i <= 1;
		ifm_rd_sel_i <= 0;
	end
	else begin
		if (ifm_wr_valid_r) begin
			ifm_wr_valid_i <= 1;
			ifm_wr_sel_i <= ~ifm_wr_sel_i;
			ifm_rd_sel_i <= ~ifm_rd_sel_i;
		end

		if (ifm_wr_count_last_w)
			ifm_wr_valid_i <= 1'b0;
			
//		if (ifm_wr_count_last_w)
//			ifm_wr_sel_i <= ~ifm_wr_sel_i;

		if (ifm_wr_count_last_w) begin
			ifm_wr_count_i <= 0;
			ifm_wr_chunk_count_i <= ifm_wr_chunk_count_i + 1;
		end
		else if (ifm_wr_valid_i) begin
			ifm_wr_count_i <= ifm_wr_count_i + 1;
		end
	end
end

assign ifm_wr_count_last_w = ifm_wr_valid_i && (ifm_wr_count_i == SIM_WR_DAT_CYC_NUM - 1);

// wr_filter_chunk
always_ff @(posedge clk_i) begin
	if (rst_i) begin
		filter_wr_valid_i <= 0;
		filter_wr_count_i <= 0;
		filter_rd_sram_count_i <= 0;
		filter_wr_chunk_sel_i <= 1;
		filter_wr_sel_i <= 1;
		filter_rd_sel_i <= 0;
	end
	else begin
		if (filter_wr_valid_r) begin
			filter_wr_valid_i <= 1;
			filter_wr_sel_i <= ~filter_wr_sel_i;
			filter_rd_sel_i <= ~filter_rd_sel_i;
		end

		if (filter_wr_count_last_w & filter_wr_chunk_sel_i[`COMPUTE_UNIT_NUM-1])
			filter_wr_valid_i <= 0;

		if (filter_wr_count_last_w) begin
			filter_wr_count_i <= 0;
			filter_rd_sram_count_i <= filter_rd_sram_count_i + 1;
			if (filter_wr_chunk_sel_i[`COMPUTE_UNIT_NUM-1]) begin
				filter_wr_chunk_sel_i <= 1;
			end
			else
				filter_wr_chunk_sel_i <= filter_wr_chunk_sel_i << 1;
		end
		else if (filter_wr_valid_i) begin
			filter_wr_count_i <= filter_wr_count_i + 1;
		end
	end
end

assign filter_wr_count_last_w = filter_wr_valid_i && (filter_wr_count_i == SIM_WR_DAT_CYC_NUM - 1);



// Initiate
initial begin
	ifm_wr_valid_r = 1'b0;
	filter_wr_valid_r = 1'b0;
	run_valid_r = 1'b0;

	@(negedge rst_i) ;
	@(posedge clk_i) ;

	// Write mem
	mem_gen_start_i = 1'b1;
	@(posedge clk_i)
	mem_gen_start_i = 1'b0;

	// Finish wrting mem
	@(posedge mem_gen_finish_w);

	// Read mem to chunks
	fork
		begin
			filter_wr_valid_r = 1'b1;
			@(posedge filter_wr_valid_i)
			filter_wr_valid_r = 1'b0;
		end
		begin
			ifm_wr_valid_r = 1'b1;
			@(posedge ifm_wr_valid_i)
			ifm_wr_valid_r = 1'b0;
		end
	join
	
	// Finish reading chunks & start processing
	if (filter_wr_count_last_w & filter_wr_chunk_sel_i[`COMPUTE_UNIT_NUM-1]) ;
	else
		@(posedge (filter_wr_count_last_w & filter_wr_chunk_sel_i[`COMPUTE_UNIT_NUM-1]));

	run_valid_r = 1'b1;
	@(posedge run_valid_i)
	run_valid_r = 1'b0;

`ifdef SHORT_CHANNEL
 `ifdef CHANNEL_PADDING
	fork
		begin
			filter_wr_valid_r = 1'b1;
			@(posedge filter_wr_valid_i)
			filter_wr_valid_r = 1'b0;
		end
		begin
			ifm_wr_valid_r = 1'b1;
			@(posedge ifm_wr_valid_i)
			ifm_wr_valid_r = 1'b0;
		end
	join
 `else
	ifm_wr_valid_r = 1'b1;
	@(posedge ifm_wr_valid_i)
	ifm_wr_valid_r = 1'b0;
 `endif
`else
	fork
		begin
			filter_wr_valid_r = 1'b1;
			@(posedge filter_wr_valid_i)
			filter_wr_valid_r = 1'b0;
		end
		begin
			ifm_wr_valid_r = 1'b1;
			@(posedge ifm_wr_valid_i)
			ifm_wr_valid_r = 1'b0;
		end
	join
`endif
end

// Re-generate IFM and Filter after chunk end
`ifdef SHORT_CHANNEL
 `ifdef CHANNEL_PADDING
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			acc_buf_sel_i <= 0;
			out_buf_sel_i <= 0;
		end
		else if (total_chunk_end_o) begin
			if (out_buf_sel_i == (SIM_OUTPUT_NUM-1)) begin
				acc_buf_sel_i <= 0;
				out_buf_sel_i <= 0;
			end
			else begin
				acc_buf_sel_i <= acc_buf_sel_i + 1;
				out_buf_sel_i <= out_buf_sel_i + 1;
			end
			ifm_wr_valid_i <= 1;
			ifm_wr_sel_i <= ~ifm_wr_sel_i;
			ifm_rd_sel_i <= ~ifm_rd_sel_i;
		end
	end

	assign ifm_wr_last_w = ifm_wr_valid_i && (ifm_wr_count_i == (SIM_WR_DAT_CYC_NUM-1));
	
	always @(posedge clk_i) begin
		if (rst_i) begin
			filter_ref_num <= 0;
		end
		else if (total_chunk_end_o && (out_buf_sel_i == (SIM_OUTPUT_NUM-1))) begin
			if (filter_ref_num == (SIM_FILTER_REF_NUM-1)) $finish;
			filter_ref_num <= filter_ref_num + 1;
	
			filter_wr_valid_i <= 1;
			filter_wr_sel_i <= ~filter_wr_sel_i;
			filter_rd_sel_i <= ~filter_rd_sel_i;
			
		end
	end
	
	assign rd_sparsemap_last_i = SIM_RD_SPARSEMAP_NUM - 1;

 `elsif CHANNEL_STACKING
	always @(posedge clk_i) begin
		if (rst_i) begin
			ifm_shift_num <= 0;
			acc_buf_sel_i <= 0;
			out_buf_sel_i <= 0;
		end
		else if (total_chunk_end_o) begin
			if (ifm_shift_num == (SIM_IFM_SHIFT_NUM-1)) $finish;
			ifm_shift_num <= ifm_shift_num + 1;

			if (out_buf_sel_i == (SIM_OUTPUT_NUM-1)) begin
				acc_buf_sel_i <= 0;
				out_buf_sel_i <= 0;

				ifm_rd_sel_i <= ~ifm_rd_sel_i;
				ifm_wr_sel_i <= ~ifm_wr_sel_i;
				ifm_wr_valid_i <= 1;

				filter_rd_sel_i <= ~filter_rd_sel_i;
				filter_wr_sel_i <= ~filter_wr_sel_i;
				filter_wr_valid_i <= 1;
			end
			else begin
				acc_buf_sel_i <= acc_buf_sel_i + 1;
				out_buf_sel_i <= out_buf_sel_i + 1;
			end
		end
	end

	assign shift_left_i = (ifm_shift_num * `CHANNEL_NUM) % `PREFIX_SUM_SIZE;
	assign rd_sparsemap_step_i = (ifm_shift_num * `CHANNEL_NUM) / `PREFIX_SUM_SIZE;
	assign rd_sparsemap_last_i = SIM_RD_SPARSEMAP_NUM - 1 + rd_sparsemap_step_i;
 `endif
`elsif FULL_CHANNEL
 `ifdef CHANNEL_PADDING
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			acc_buf_sel_i <= 0;
			out_buf_sel_i <= 0;
		end
		else begin
			if (total_chunk_end_o) begin
				if (out_buf_sel_i == (SIM_OUTPUT_NUM-1)) begin
					acc_buf_sel_i <= 0;
					out_buf_sel_i <= 0;
				end
				else begin
					acc_buf_sel_i <= acc_buf_sel_i + 1;
					out_buf_sel_i <= out_buf_sel_i + 1;
				end
			end

			if (total_chunk_end_o) begin
				ifm_wr_valid_i <= 1'b1;
				ifm_wr_sel_i = ~ifm_wr_sel_i;
				ifm_rd_sel_i = ~ifm_rd_sel_i;
			end
		end
	end

	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			filter_ref_num <= 0;
			filter_rd_sel_i <= 0;
		end
		else begin
			if (total_chunk_end_o && (out_buf_sel_i == (SIM_OUTPUT_NUM-1))) begin

				if (filter_ref_num == (SIM_FILTER_REF_NUM-1)) $finish;
				filter_ref_num <= filter_ref_num + 1;
	
				filter_wr_valid_i <= 1;
				filter_wr_sel_i <= ~filter_wr_sel_i;
				filter_rd_sel_i <= ~filter_rd_sel_i;
			end
		end
	end
	
	assign rd_sparsemap_last_i = SIM_RD_SPARSEMAP_NUM - 1;

 `elsif CHANNEL_STACKING
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			ifm_shift_num <= 0;
			filter_ref_num <= 0;
			acc_buf_sel_i <= 0;
			out_buf_sel_i <= 0;
		end
		else if (total_chunk_end_o) begin
			if (ifm_shift_num == (SIM_IFM_SHIFT_NUM-1))
				ifm_shift_num <= 0;
			else
				ifm_shift_num <= ifm_shift_num + 1;

			if (out_buf_sel_i == (SIM_OUTPUT_NUM-1)) begin
				if (filter_ref_num == (SIM_FILTER_REF_NUM-1)) $finish;
				filter_ref_num <= filter_ref_num + 1;

				acc_buf_sel_i <= 0;
				out_buf_sel_i <= 0;

				ifm_wr_valid_i <= 1;
				ifm_wr_sel_i <= ~ifm_wr_sel_i;
				ifm_rd_sel_i <= ~ifm_rd_sel_i;

				filter_wr_valid_i <= 1;
				filter_wr_sel_i <= ~filter_wr_sel_i;
				filter_rd_sel_i <= ~filter_rd_sel_i;
			end
			else begin
				acc_buf_sel_i <= acc_buf_sel_i + 1;
				out_buf_sel_i <= out_buf_sel_i + 1;
			end
		end
	end

	assign shift_left_i = (ifm_shift_num * `CHANNEL_NUM) % `PREFIX_SUM_SIZE;
	assign rd_sparsemap_step_i = (ifm_shift_num * `CHANNEL_NUM) / `PREFIX_SUM_SIZE;
	assign rd_sparsemap_last_i = SIM_RD_SPARSEMAP_NUM - 1 + rd_sparsemap_step_i;
 `endif
`endif

always_ff @(posedge clk_i) begin
	if (rst_i)
		run_valid_i <= 0;
	else begin
		if (run_valid_r)
			run_valid_i <= 1;
	end
end

//Generate the total chunk start signal
logic run_valid_delay_r;
logic total_chunk_start_r;
always_ff @(posedge clk_i) begin
	if (rst_i)
		run_valid_delay_r <= 1'b0;
	else
		run_valid_delay_r <= run_valid_i;
end

always_ff @(posedge clk_i) begin
	if (rst_i)
		total_chunk_start_r <= 1'b0;
	else if (total_chunk_end_o)
		total_chunk_start_r <= 1'b1;
	else if (total_chunk_start_r)
		total_chunk_start_r <= 1'b0;
end

assign total_chunk_start_i = run_valid_i && (total_chunk_start_r || (run_valid_i && (!run_valid_delay_r)));


endmodule

