`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2022 12:22:13 PM
// Design Name: 
// Module Name: IFM_Data_Chunk_Top
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


module IFM_Dat_Chunk_Comb_Non_Padding_v2 #(
	 localparam int PARAM_WR_DAT_CYC_NUM = `MEM_SIZE/`BUS_SIZE
	,localparam int PARAM_RD_SPARSEMAP_NUM = `MEM_SIZE/`PREFIX_SUM_SIZE
)(
	 input rst_i
	,input clk_i

	,input [`BUS_SIZE-1:0] wr_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] wr_nonzero_data_i 
	,input wr_valid_i
	,input [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] wr_count_i
	,input wr_sel_i
	,input rd_sel_i

	,input chunk_start_i
	,input [$clog2(`PREFIX_SUM_SIZE)-1:0] shift_left_i
	,input [`COMPUTE_UNIT_NUM-1:0] pri_enc_last_i

	,input [`COMPUTE_UNIT_NUM-1:0][$clog2(`MEM_SIZE):0] rd_addr_i
	,output logic [`COMPUTE_UNIT_NUM-1:0][7:0] rd_data_o

	,input [`COMPUTE_UNIT_NUM-1:0][$clog2(PARAM_RD_SPARSEMAP_NUM)-1:0] rd_sparsemap_addr_i
	,output logic [`COMPUTE_UNIT_NUM-1:0][`PREFIX_SUM_SIZE-1:0] rd_sparsemap_o	
);
	
	logic [1:0] wr_val_w;
	logic [1:0][`MEM_SIZE:1][7:0] rd_nonzero_data_w;
	logic [1:0][`MEM_SIZE-1:0] rd_sparsemap_w;

	logic [`COMPUTE_UNIT_NUM-1:0] rd_sel_r, rd_sel_w;

	logic [1:0][`COMPUTE_UNIT_NUM-1:0][`PREFIX_SUM_SIZE*2-1:0] rd_sparsemap_o_w;
	logic [`COMPUTE_UNIT_NUM-1:0][`PREFIX_SUM_SIZE*2-1:0] rd_sparsemap_o_comb_w;
	logic [`COMPUTE_UNIT_NUM-1:0][`PREFIX_SUM_SIZE*2-1:0] rd_sparsemap_o_shift_w;

	logic [1:0][`COMPUTE_UNIT_NUM-1:0][7:0] rd_data_w;

//	genvar n;
//	integer i, j, k;

	for (genvar n=0; n<2; n=n+1) begin
		Dat_Chunk_Comb u_Dat_Chunk_Comb (
			 .clk_i
			,.rst_i
			,.wr_sparsemap_i
			,.wr_nonzero_data_i
			,.wr_valid_i(wr_val_w[n])
			,.wr_count_i
		
			,.rd_nonzero_data_o(rd_nonzero_data_w[n])
			,.rd_sparsemap_o(rd_sparsemap_w[n])
		);
	end

	assign wr_val_w[1] =   wr_sel_i  && wr_valid_i;
	assign wr_val_w[0] = (!wr_sel_i) && wr_valid_i;

	// Read Sparsemap
	always_comb begin
		for (integer i=0; i<2; i=i+1) begin
			for (integer j=0; j<`COMPUTE_UNIT_NUM; j=j+1) begin
				rd_sparsemap_o_w[i][j] = {`PREFIX_SUM_SIZE{1'b0}};
				for (integer k=1; k<PARAM_RD_SPARSEMAP_NUM-1; k = k+1) begin
					if (rd_sparsemap_addr_i[j] == k)
						rd_sparsemap_o_w[i][j] = rd_sparsemap_w[i][`PREFIX_SUM_SIZE*k +: (`PREFIX_SUM_SIZE*2)];
				end
				if (rd_sparsemap_addr_i[j] == (PARAM_RD_SPARSEMAP_NUM-1))
					rd_sparsemap_o_w[i][j] = {rd_sparsemap_w[i][`PREFIX_SUM_SIZE*(PARAM_RD_SPARSEMAP_NUM-1) +: `PREFIX_SUM_SIZE],{`PREFIX_SUM_SIZE{1'b0}}};
				if (rd_sparsemap_addr_i[j] == 0)
					rd_sparsemap_o_w[i][j] = {{`PREFIX_SUM_SIZE{1'b0}},rd_sparsemap_w[i][`PREFIX_SUM_SIZE*0 +: `PREFIX_SUM_SIZE]};
			end
		end
	end

	always_comb begin
		for (integer i=0; i<`COMPUTE_UNIT_NUM; i=i+1) begin
			if (rd_sel_w[i])
				rd_sparsemap_o_comb_w[i] = rd_sparsemap_o_w[1][i];
			else
				rd_sparsemap_o_comb_w[i] = rd_sparsemap_o_w[0][i];
		end
	end

	always_comb begin
		for (integer i=0; i<`COMPUTE_UNIT_NUM; i=i+1) begin
			rd_sparsemap_o_shift_w[i] = rd_sparsemap_o_comb_w[i] << shift_left_i;

			rd_sparsemap_o[i] = rd_sparsemap_o_shift_w[i][`PREFIX_SUM_SIZE-1:0];
		end
	end

	// Read Nonzero data
	always_comb begin
		for (integer i=0; i<2; i=i+1) begin
			for (integer j=0; j<`COMPUTE_UNIT_NUM; j=j+1) begin
				rd_data_w[i][j] = rd_nonzero_data_w[i][rd_addr_i[i]];
			end
		end
	end

	always_comb begin
		for (integer i=0; i<`COMPUTE_UNIT_NUM; i=i+1) begin
			if (rd_sel_w[i])
				rd_data_o[i] = rd_data_w[1][i];
			else
				rd_data_o[i] = rd_data_w[0][i];
		end
	end

	always_ff @(posedge clk_i) begin
		for (integer i=0; i<`COMPUTE_UNIT_NUM; i=i+1) begin
			if (rst_i) begin
				rd_sel_r[i] <= 1'b0;
			end
			else begin
				if ((rd_sparsemap_addr_i[i] == (PARAM_RD_SPARSEMAP_NUM-1)) && pri_enc_last_i[i])
					rd_sel_r[i] <= ~rd_sel_i;
				else
					rd_sel_r[i] <= rd_sel_w[i];
			end
		end
	end	

	for (genvar n=0; n<`COMPUTE_UNIT_NUM; n=n+1) begin
		assign rd_sel_w[n] = chunk_start_i ? rd_sel_i : rd_sel_r[n];
	end


endmodule
