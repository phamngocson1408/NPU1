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


module Data_Chunk_Top_Filter #(
)(
	 input rst_i
	,input clk_i
	,input [`BUS_SIZE-1:0] wr_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] wr_nonzero_data_i 
	,input wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] wr_count_i
	,input wr_sel_i

	,input rd_sel_i
	,output logic [7:0] rd_data_o

	,input  [$clog2(`PREFIX_SUM_SIZE)-1:0] pri_enc_match_addr_i
	,input pri_enc_end_i
	,input sub_chunk_start_i

	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_sparsemap_addr_i
	,output logic [`PREFIX_SUM_SIZE-1:0] rd_sparsemap_o

`ifdef CHANNEL_STACKING
	,input [$clog2(`RD_DAT_CYC_NUM)-1:0] rd_fil_nonzero_dat_first_i
	,input sub_chunk_end_i
`endif

);
	
	logic [1:0] wr_val_w;
	logic [$clog2(`CHUNK_SIZE):0] rd_dat_addr_w;	
	logic [1:0][7:0] rd_dat_w;
	logic [1:0][`PREFIX_SUM_SIZE-1:0] rd_sparsemap_w;

	Data_Chunk u_Data_Chunk_0 (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i
		,.wr_nonzero_data_i
		,.wr_valid_i(wr_val_w[0])
		,.wr_count_i

		,.rd_addr_i(rd_dat_addr_w)
		,.rd_data_o(rd_dat_w[0])

		,.rd_sparsemap_addr_i
		,.rd_sparsemap_o(rd_sparsemap_w[0])
	);

	Data_Chunk u_Data_Chunk_1 (
		 .clk_i
		,.rst_i
		,.wr_sparsemap_i
		,.wr_nonzero_data_i
		,.wr_valid_i(wr_val_w[1])
		,.wr_count_i

		,.rd_addr_i(rd_dat_addr_w)
		,.rd_data_o(rd_dat_w[1])

		,.rd_sparsemap_addr_i
		,.rd_sparsemap_o(rd_sparsemap_w[1])
	);

	Data_Addr_Cal u_Data_Addr_Cal (
		 .clk_i
		,.rst_i
		
		,.pri_enc_match_addr_i
		,.pri_enc_end_i
		,.sub_chunk_start_i
		,.sparsemap_i(rd_sparsemap_o)

		,.rd_dat_addr_o(rd_dat_addr_w)
`ifdef CHANNEL_STACKING
		,.rd_fil_nonzero_dat_first_i
		,.sub_chunk_end_i
`endif
	);


	always_comb begin
		if (rd_sel_i) begin
			rd_data_o 		= rd_dat_w[1];
			rd_sparsemap_o	 	= rd_sparsemap_w[1];
		end
		else begin
			rd_data_o 		= rd_dat_w[0];
			rd_sparsemap_o	 	= rd_sparsemap_w[0];
		end
	end

	assign wr_val_w[1] =   wr_sel_i  && wr_valid_i;
	assign wr_val_w[0] = (!wr_sel_i) && wr_valid_i;

endmodule
