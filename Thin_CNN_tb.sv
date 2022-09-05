`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// This module is test the Compute_Cluster at thin CNN layers
//////////////////////////////////////////////////////////////////////////////////


module Thin_CNN_tb(
    );

//CLock generate
reg clk_r;
initial begin
	clk_r=0;
	#(`CYCLE/2);
	while (1) begin
		clk_r = ~clk_r;
		#(`CYCLE/2);
	end
end

//Reset generate
reg rst_r;
initial begin
	rst_r = 1;
	#(`CYCLE*50);
	@(posedge clk_r);
	#1;
	rst_r = 0;
end

//Instance
`ifdef CHUNK_PADDING
localparam int WR_DAT_CYC_NUM =   (`CHANNEL_NUM > `MEM_SIZE) ?  `MEM_SIZE/`BUS_SIZE
				: ((`CHANNEL_NUM % `BUS_SIZE)!=0) ? `CHANNEL_NUM/`BUS_SIZE + 1
				: `CHANNEL_NUM/`BUS_SIZE;
localparam int RD_SPARSEMAP_NUM =   (`CHANNEL_NUM > `MEM_SIZE) ?  `MEM_SIZE/`PREFIX_SUM_SIZE
				: ((`CHANNEL_NUM % `PREFIX_SUM_SIZE)!=0) ? `CHANNEL_NUM/`PREFIX_SUM_SIZE + 1
				: `CHANNEL_NUM/`PREFIX_SUM_SIZE;
`else
localparam int WR_DAT_CYC_NUM = `MEM_SIZE/`BUS_SIZE;
localparam int RD_SPARSEMAP_NUM = `MEM_SIZE/`PREFIX_SUM_SIZE;
`endif

logic [`MEM_SIZE-1:0][7:0] mem_ifm_non_zero_data_r = {`MEM_SIZE{8'h00}};
logic [`MEM_SIZE-1:0] mem_ifm_sparse_map_r ;

logic [`BUS_SIZE-1:0][7:0] ifm_nonzero_data_r;
logic [`BUS_SIZE-1:0] ifm_sparse_map_r ;
logic ifm_wr_valid_r;
logic [$clog2(WR_DAT_CYC_NUM)-1:0] ifm_wr_count_r ;
logic ifm_wr_sel_r;
logic ifm_rd_sel_r;

logic [`MEM_SIZE-1:0][7:0] mem_filter_non_zero_data_r = {`MEM_SIZE{8'h00}};
logic [`MEM_SIZE-1:0] mem_filter_sparse_map_r ;

logic [`BUS_SIZE-1:0][7:0] filter_nonzero_data_r;
logic [`BUS_SIZE-1:0] filter_sparse_map_r ;
logic filter_wr_valid_r;
logic [$clog2(WR_DAT_CYC_NUM)-1:0] filter_wr_count_r ;
logic filter_wr_sel_r;
logic filter_rd_sel_r;
logic [$clog2(`OUTPUT_BUF_NUM)-1:0] filter_wr_order_sel_r;

logic run_valid_r;
logic total_chunk_start_r;
logic [$clog2(RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_num_r;
logic total_chunk_end_o;

logic [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_buf_sel_r;
logic [$clog2(`OUTPUT_BUF_NUM)-1:0] out_buf_sel_r;
logic [$clog2(`COMPUTE_UNIT_NUM)-1:0] com_unit_out_buf_sel_r = 0;
logic [`OUTPUT_BUF_SIZE-1:0] out_buf_dat_o;

logic ifm_wr_last_w;


Compute_Cluster u_Compute_Cluster (
	 .rst_i(rst_r)
	,.clk_i(clk_r)

	,.ifm_sparsemap_i(ifm_sparse_map_r)
	,.ifm_nonzero_data_i(ifm_nonzero_data_r)
	,.ifm_wr_valid_i(ifm_wr_valid_r)	
	,.ifm_wr_count_i(ifm_wr_count_r)	
	,.ifm_wr_sel_i(ifm_wr_sel_r)	
	,.ifm_rd_sel_i(ifm_rd_sel_r)	

	,.filter_sparsemap_i(filter_sparse_map_r)
	,.filter_nonzero_data_i(filter_nonzero_data_r)
	,.filter_wr_valid_i(filter_wr_valid_r)	
	,.filter_wr_count_i(filter_wr_count_r)	
	,.filter_wr_sel_i(filter_wr_sel_r)	
	,.filter_rd_sel_i(filter_rd_sel_r)	
	,.filter_wr_order_sel_i(filter_wr_order_sel_r)	

	,.run_valid_i(run_valid_r)
	,.chunk_start_i(total_chunk_start_r)
	,.rd_sparsemap_num_i(rd_sparsemap_num_r)
	,.total_chunk_end_o

	,.acc_buf_sel_i(acc_buf_sel_r)
	,.out_buf_sel_i(out_buf_sel_r)
	,.com_unit_out_buf_sel_i(com_unit_out_buf_sel_r)
	,.out_buf_dat_o
);

task ifm_mem_gen();
	integer i;
	logic [$clog2(`MEM_SIZE):0] j=0;
	logic [7:0] data;
	integer low_bound = $urandom_range(10,3);

	for (i=0; i<`MEM_SIZE; i=i+1) begin

`ifdef CHUNK_PADDING
		if (i < `CHANNEL_NUM)
			data = $urandom_range(256,0);
		else
			data = 0;
`else
		data = $urandom_range(256,0);
`endif

		if (data > 10*low_bound) begin
			mem_ifm_non_zero_data_r[j] = data;
			mem_ifm_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			mem_ifm_sparse_map_r[i] = 0;
		end
	end
endtask

task ifm_input_gen();
	ifm_mem_gen();
	ifm_wr_valid_r = 1'b1;
	ifm_wr_count_r = 0;
	ifm_sparse_map_r = mem_ifm_sparse_map_r[`BUS_SIZE*ifm_wr_count_r +: `BUS_SIZE];
	ifm_nonzero_data_r = mem_ifm_non_zero_data_r[`BUS_SIZE*ifm_wr_count_r +: `BUS_SIZE];

	repeat(WR_DAT_CYC_NUM) @(posedge (clk_r && !rst_r)) begin
		#1;
		ifm_wr_count_r = ifm_wr_count_r+1;
		ifm_sparse_map_r = mem_ifm_sparse_map_r[`BUS_SIZE*ifm_wr_count_r +: `BUS_SIZE];
		ifm_nonzero_data_r = mem_ifm_non_zero_data_r[`BUS_SIZE*ifm_wr_count_r +: `BUS_SIZE];
	end

	ifm_wr_valid_r = 1'b0;
	ifm_wr_count_r = 0;
endtask

task filter_mem_gen();
	integer i;
	logic [$clog2(`MEM_SIZE):0] j=0;
	logic [7:0] data;

	for (i=0; i<`MEM_SIZE; i=i+1) begin

`ifdef CHUNK_PADDING
		if (i < `CHANNEL_NUM)
			data = $urandom_range(256,0);
		else
			data = 0;
`else
		data = $urandom_range(256,0);
`endif

		if (data > 50) begin
			mem_filter_non_zero_data_r[j] = data;
			mem_filter_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			mem_filter_sparse_map_r[i] = 0;
		end
	end
endtask

task filter_input_gen();
	filter_mem_gen();
	filter_wr_valid_r = 1'b1;
	filter_wr_count_r = 0;
	filter_sparse_map_r = mem_filter_sparse_map_r[`BUS_SIZE*filter_wr_count_r +: `BUS_SIZE];
	filter_nonzero_data_r = mem_filter_non_zero_data_r[`BUS_SIZE*filter_wr_count_r +: `BUS_SIZE];

	repeat(WR_DAT_CYC_NUM) @(posedge (clk_r && !rst_r)) begin
		#1;
		filter_wr_count_r = filter_wr_count_r+1;
		filter_sparse_map_r = mem_filter_sparse_map_r[`BUS_SIZE*filter_wr_count_r +: `BUS_SIZE];
		filter_nonzero_data_r = mem_filter_non_zero_data_r[`BUS_SIZE*filter_wr_count_r +: `BUS_SIZE];
	end

	filter_wr_valid_r = 1'b0;
	filter_wr_count_r = 0;
endtask

task wr_total_filter();
	filter_wr_order_sel_r = 0;
	repeat(`COMPUTE_UNIT_NUM) begin
		filter_input_gen();
		filter_wr_order_sel_r = filter_wr_order_sel_r + 1;
	end
endtask


initial begin
	 @(negedge rst_r) ;
	 @(posedge clk_r) #1;
	run_valid_r = 1'b0;
	rd_sparsemap_num_r = RD_SPARSEMAP_NUM - 1;
	acc_buf_sel_r = 0;
	out_buf_sel_r = 0;

	fork
		begin
			filter_wr_sel_r = 1'b0;
			wr_total_filter();
		end
		begin
			ifm_wr_sel_r = 1'b0;
			ifm_input_gen();
		end
	join

	ifm_rd_sel_r = 1'b0;
	filter_rd_sel_r = 1'b0;
	run_valid_r = 1'b1;

	fork
		begin
			filter_wr_sel_r = 1'b1;
			wr_total_filter();
		end
		begin
			ifm_wr_sel_r = 1'b1;
			ifm_input_gen();
		end
	join
end

always @(posedge clk_r) begin
	if (total_chunk_end_o) begin
		#1;
		if (ifm_wr_valid_r && (!ifm_wr_last_w)) begin
			run_valid_r = 1'b0;
		end
		else begin
			run_valid_r = 1'b1;
			acc_buf_sel_r = acc_buf_sel_r + 1;
			out_buf_sel_r = out_buf_sel_r + 1;
			ifm_rd_sel_r = ~ifm_rd_sel_r;
			ifm_wr_sel_r = ~ifm_wr_sel_r;
			ifm_input_gen();
		end
	end
end

integer check_int = 0;
always @(posedge clk_r) begin
	if (total_chunk_end_o && (out_buf_sel_r == (`OUTPUT_BUF_NUM-1))) begin
		#1; 
		if (filter_wr_valid_r) begin
			run_valid_r = 1'b0;
		end
		else begin
			check_int = check_int + 1;
			if (check_int == 2) $finish;

			run_valid_r = 1'b1;
			filter_rd_sel_r = ~filter_rd_sel_r;
			filter_wr_sel_r = ~filter_wr_sel_r;
			wr_total_filter();
		end
	end
end

always_ff @(posedge clk_r) begin
	if (rst_r)
		total_chunk_start_r <= #1 1'b0;
	else if (total_chunk_end_o && (!ifm_wr_valid_r))
		total_chunk_start_r <= #1 1'b1;
	else if (total_chunk_start_r)
		total_chunk_start_r <= #1 1'b0;
end

//assign total_chunk_start_r = total_chunk_end_o && (!ifm_wr_valid_r);
assign ifm_wr_last_w = ifm_wr_valid_r && (ifm_wr_count_r == (WR_DAT_CYC_NUM-1));


endmodule
