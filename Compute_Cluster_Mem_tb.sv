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
	#(`CYCLE*50);
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
localparam int SRAM_FILTER_NUM = SRAM_CHUNK_SIZE / `CHANNEL_NUM;
localparam int SRAM_OUTPUT_NUM = (SRAM_FILTER_NUM <= `OUTPUT_BUF_NUM) ? SRAM_FILTER_NUM : `OUTPUT_BUF_NUM;
localparam int SRAM_IFM_NUM = SRAM_FILTER_NUM + SRAM_OUTPUT_NUM;

//DUT instance
logic ifm_wr_valid_i;
logic [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] ifm_wr_count_i ;
logic ifm_wr_sel_i;
logic ifm_rd_sel_i;
logic [$clog2(SRAM_IFM_NUM)-1:0] ifm_wr_chunk_count_i;

logic filter_wr_valid_i;
logic [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] filter_wr_count_i ;
logic filter_wr_sel_i;
logic filter_rd_sel_i;
logic [$clog2(`OUTPUT_BUF_NUM)-1:0] filter_wr_order_sel_i;

logic run_valid_i;
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

logic [`BUS_SIZE-1:0] 		mem_ifm_wr_sparsemap_i;
logic [`BUS_SIZE-1:0][7:0] 	mem_ifm_wr_nonzero_data_i;
logic 				mem_ifm_wr_valid_i;
logic [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] mem_ifm_wr_dat_count_i;
logic [$clog2(SRAM_IFM_NUM)-1:0] 	mem_ifm_wr_chunk_count_i;

logic [`BUS_SIZE-1:0] 		mem_filter_wr_sparsemap_i;
logic [`BUS_SIZE-1:0][7:0] 	mem_filter_wr_nonzero_data_i;
logic 				mem_filter_wr_valid_i;
logic [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] mem_filter_wr_dat_count_i;
logic [$clog2(SRAM_FILTER_NUM)-1:0] 	mem_filter_wr_chunk_count_i;

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
	,.filter_wr_order_sel_i

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

	,.mem_ifm_wr_sparsemap_i
	,.mem_ifm_wr_nonzero_data_i
	,.mem_ifm_wr_valid_i
	,.mem_ifm_wr_dat_count_i
	,.mem_ifm_wr_chunk_count_i

	,.mem_filter_wr_sparsemap_i
	,.mem_filter_wr_nonzero_data_i
	,.mem_filter_wr_valid_i
	,.mem_filter_wr_dat_count_i
	,.mem_filter_wr_chunk_count_i
);

integer filter_ref_num;
integer ifm_shift_num;

logic ifm_wr_last_w;

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
`else	// not define SHORT_CHANNEL
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
	mem_ifm_wr_valid_i = 1'b1;
	mem_ifm_wr_chunk_count_i = 0;
	repeat (SRAM_IFM_NUM) begin
		gen_ifm_buf();
		mem_ifm_wr_dat_count_i = 0;
		mem_ifm_wr_sparsemap_i = mem_ifm_sparse_map_r[`BUS_SIZE*mem_ifm_wr_dat_count_i +: `BUS_SIZE];
		mem_ifm_wr_nonzero_data_i = mem_ifm_non_zero_data_r[`BUS_SIZE*mem_ifm_wr_dat_count_i +: `BUS_SIZE];
		repeat(SIM_WR_DAT_CYC_NUM) @(posedge (clk_i && !rst_i)) begin
			mem_ifm_wr_dat_count_i = mem_ifm_wr_dat_count_i + 1;
			mem_ifm_wr_sparsemap_i = mem_ifm_sparse_map_r[`BUS_SIZE*mem_ifm_wr_dat_count_i +: `BUS_SIZE];
			mem_ifm_wr_nonzero_data_i = mem_ifm_non_zero_data_r[`BUS_SIZE*mem_ifm_wr_dat_count_i +: `BUS_SIZE];
		end
		mem_ifm_wr_chunk_count_i = mem_ifm_wr_chunk_count_i + 1;
	end
	mem_ifm_wr_valid_i = 1'b0;
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
	mem_filter_wr_valid_i = 1'b1;
	mem_filter_wr_chunk_count_i = 0;
	repeat (SRAM_FILTER_NUM) begin
		gen_filter_buf();
		mem_filter_wr_dat_count_i = 0;
		mem_filter_wr_sparsemap_i = mem_filter_sparse_map_r[`BUS_SIZE*mem_filter_wr_dat_count_i +: `BUS_SIZE];
		mem_filter_wr_nonzero_data_i = mem_filter_non_zero_data_r[`BUS_SIZE*mem_filter_wr_dat_count_i +: `BUS_SIZE];
		repeat(SIM_WR_DAT_CYC_NUM) @(posedge (clk_i && !rst_i)) begin
			gen_filter_buf();
			mem_filter_wr_dat_count_i = mem_filter_wr_dat_count_i + 1;
			mem_filter_wr_sparsemap_i = mem_filter_sparse_map_r[`BUS_SIZE*mem_filter_wr_dat_count_i +: `BUS_SIZE];
			mem_filter_wr_nonzero_data_i = mem_filter_non_zero_data_r[`BUS_SIZE*mem_filter_wr_dat_count_i +: `BUS_SIZE];
		end
		mem_filter_wr_chunk_count_i = mem_filter_wr_chunk_count_i + 1;
	end
	mem_filter_wr_valid_i = 1'b0;
endtask

task rd_ifm_buf();
	ifm_wr_valid_i = 1'b1;
	ifm_wr_count_i = 0;
	repeat(SIM_WR_DAT_CYC_NUM) @(posedge (clk_i && !rst_i)) begin
		ifm_wr_count_i = ifm_wr_count_i+1;
	end
	ifm_wr_valid_i = 1'b0;
	ifm_wr_count_i = 0;
	ifm_wr_chunk_count_i = ifm_wr_chunk_count_i + 1;
endtask

task rd_filter_buf();
	filter_wr_valid_i = 1'b1;
	filter_wr_count_i = 0;
	repeat(SIM_WR_DAT_CYC_NUM) @(posedge (clk_i && !rst_i)) begin
		filter_wr_count_i = filter_wr_count_i+1;
	end
	filter_wr_valid_i = 1'b0;
	filter_wr_count_i = 0;
endtask

task rd_total_filter_buf();
	filter_wr_order_sel_i = 0;
	repeat(`COMPUTE_UNIT_NUM) begin
		rd_filter_buf();
		filter_wr_order_sel_i = filter_wr_order_sel_i + 1;
	end
endtask



// Initiate
initial begin
	@(negedge rst_i) ;
	@(posedge clk_i) ;
	run_valid_i = 1'b0;
	acc_buf_sel_i = 0;
	out_buf_sel_i = 0;
	ifm_wr_chunk_count_i = 0;

	fork
		wr_ifm_buf();
		wr_filter_buf();
	join

	fork
		begin
			filter_wr_sel_i = 1'b0;
			rd_total_filter_buf();
		end
		begin
			ifm_wr_sel_i = 1'b0;
			rd_ifm_buf();
		end
	join

	ifm_rd_sel_i = 1'b0;
	filter_rd_sel_i = 1'b0;
	run_valid_i = 1'b1;
`ifdef SHORT_CHANNEL
 `ifdef CHANNEL_PADDING
 	fork
 		begin
 			filter_wr_sel_i = 1'b1;
 			rd_total_filter_buf();
 		end
 		begin
 			ifm_wr_sel_i = 1'b1;
 			rd_ifm_buf();
 		end
 	join
 `else
 	ifm_wr_sel_i = 1'b1;
 	rd_ifm_buf();
 `endif
`else
 	fork
 		begin
 			filter_wr_sel_i = 1'b1;
 			rd_total_filter_buf();
 		end
 		begin
 			ifm_wr_sel_i = 1'b1;
 			rd_ifm_buf();
 		end
 	join
`endif
end

// Re-generate IFM and Filter after chunk end
`ifdef SHORT_CHANNEL
 `ifdef CHANNEL_PADDING
	always @(posedge clk_i) begin
		if (total_chunk_end_o) begin
			if (ifm_wr_valid_i && (!ifm_wr_last_w)) begin
				run_valid_i = 1'b0;
			end
			else begin
				run_valid_i = 1'b1;
				if (out_buf_sel_i == (SIM_OUTPUT_NUM-1)) begin
					acc_buf_sel_i = 0;
					out_buf_sel_i = 0;
				end
				else begin
					acc_buf_sel_i = acc_buf_sel_i + 1;
					out_buf_sel_i = out_buf_sel_i + 1;
				end
				ifm_rd_sel_i = ~ifm_rd_sel_i;
				ifm_wr_sel_i = ~ifm_wr_sel_i;
				rd_ifm_buf();
			end
		end
	end
	assign ifm_wr_last_w = ifm_wr_valid_i && (ifm_wr_count_i == (SIM_WR_DAT_CYC_NUM-1));
	
	always @(posedge clk_i) begin
		if (rst_i) begin
			filter_ref_num = 0;
		end
		else if (total_chunk_end_o && (out_buf_sel_i == (SIM_OUTPUT_NUM-1))) begin
			if (filter_wr_valid_i) begin
				run_valid_i = 1'b0;
			end
			else begin
				if (filter_ref_num == (SIM_FILTER_REF_NUM-1)) $finish;
				filter_ref_num = filter_ref_num + 1;
	
				run_valid_i = 1'b1;
				filter_rd_sel_i = ~filter_rd_sel_i;
				filter_wr_sel_i = ~filter_wr_sel_i;
				rd_total_filter_buf();
			end
		end
	end
	
	assign rd_sparsemap_last_i = SIM_RD_SPARSEMAP_NUM - 1;

 `elsif CHANNEL_STACKING
	always @(posedge clk_i) begin
		if (rst_i) begin
			ifm_shift_num = 0;
		end
		else if (total_chunk_end_o) begin
			if (ifm_shift_num == (SIM_IFM_SHIFT_NUM-1)) $finish;
			ifm_shift_num = ifm_shift_num + 1;

			if (out_buf_sel_i == (SIM_OUTPUT_NUM-1)) begin
				acc_buf_sel_i = 0;
				out_buf_sel_i = 0;
				fork
					begin
						ifm_rd_sel_i = ~ifm_rd_sel_i;
						ifm_wr_sel_i = ~ifm_wr_sel_i;
						rd_ifm_buf();
					end
					begin
						filter_rd_sel_i = ~filter_rd_sel_i;
						filter_wr_sel_i = ~filter_wr_sel_i;
						rd_total_filter_buf();
					end
				join
			end
			else begin
				acc_buf_sel_i = acc_buf_sel_i + 1;
				out_buf_sel_i = out_buf_sel_i + 1;
			end
		end
	end

	assign shift_left_i = (ifm_shift_num * `CHANNEL_NUM) % `PREFIX_SUM_SIZE;
	assign rd_sparsemap_step_i = (ifm_shift_num * `CHANNEL_NUM) / `PREFIX_SUM_SIZE;
	assign rd_sparsemap_last_i = SIM_RD_SPARSEMAP_NUM - 1 + rd_sparsemap_step_i;
 `endif
`elsif FULL_CHANNEL
 `ifdef CHANNEL_PADDING
	always @(posedge clk_i) begin
		if (total_chunk_end_o) begin
			if (ifm_wr_valid_i && (!ifm_wr_last_w)) begin
				run_valid_i = 1'b0;
			end
			else begin
				run_valid_i = 1'b1;
				if (out_buf_sel_i == (SIM_OUTPUT_NUM-1)) begin
					acc_buf_sel_i = 0;
					out_buf_sel_i = 0;
				end
				else begin
					acc_buf_sel_i = acc_buf_sel_i + 1;
					out_buf_sel_i = out_buf_sel_i + 1;
				end
				ifm_rd_sel_i = ~ifm_rd_sel_i;
				ifm_wr_sel_i = ~ifm_wr_sel_i;
				rd_ifm_buf();
			end
		end
	end
	assign ifm_wr_last_w = ifm_wr_valid_i && (ifm_wr_count_i == (SIM_WR_DAT_CYC_NUM-1));
	
	always @(posedge clk_i) begin
		if (rst_i) begin
			filter_ref_num = 0;
		end
		else if (total_chunk_end_o && (out_buf_sel_i == (SIM_OUTPUT_NUM-1))) begin
			if (filter_wr_valid_i) begin
				run_valid_i = 1'b0;
			end
			else begin
				if (filter_ref_num == (SIM_FILTER_REF_NUM-1)) $finish;
				filter_ref_num = filter_ref_num + 1;
	
				run_valid_i = 1'b1;
				filter_rd_sel_i = ~filter_rd_sel_i;
				filter_wr_sel_i = ~filter_wr_sel_i;
				rd_total_filter_buf();
			end
		end
	end
	
	assign rd_sparsemap_last_i = SIM_RD_SPARSEMAP_NUM - 1;

 `elsif CHANNEL_STACKING
	always @(posedge clk_i) begin
		if (rst_i) begin
			ifm_shift_num = 0;
			filter_ref_num = 0;
		end
		else if (total_chunk_end_o) begin
			if (ifm_shift_num == (SIM_IFM_SHIFT_NUM-1))
				ifm_shift_num = 0;
			else
				ifm_shift_num = ifm_shift_num + 1;

			if (out_buf_sel_i == (SIM_OUTPUT_NUM-1)) begin
				if (filter_ref_num == (SIM_FILTER_REF_NUM-1)) $finish;
				filter_ref_num = filter_ref_num + 1;

				acc_buf_sel_i = 0;
				out_buf_sel_i = 0;
				fork
					begin
						ifm_rd_sel_i = ~ifm_rd_sel_i;
						ifm_wr_sel_i = ~ifm_wr_sel_i;
						rd_ifm_buf();
					end
					begin
						filter_rd_sel_i = ~filter_rd_sel_i;
						filter_wr_sel_i = ~filter_wr_sel_i;
						rd_total_filter_buf();
					end
				join
			end
			else begin
				acc_buf_sel_i = acc_buf_sel_i + 1;
				out_buf_sel_i = out_buf_sel_i + 1;
			end
		end
	end

	assign shift_left_i = (ifm_shift_num * `CHANNEL_NUM) % `PREFIX_SUM_SIZE;
	assign rd_sparsemap_step_i = (ifm_shift_num * `CHANNEL_NUM) / `PREFIX_SUM_SIZE;
	assign rd_sparsemap_last_i = SIM_RD_SPARSEMAP_NUM - 1 + rd_sparsemap_step_i;
 `endif
`endif

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

