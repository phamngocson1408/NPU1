`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2022 02:36:59 PM
// Design Name: 
// Module Name: Mem_IFM
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


module Mem_IFM #(
)(
	 input rst_i
	,input clk_i

	,output [`BUS_SIZE-1:0] rd_sparsemap_o
	,output [`BUS_SIZE-1:0][7:0] rd_nonzero_data_o
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] rd_dat_count_i
	,input [$clog2(`SRAM_IFM_NUM)-1:0] rd_chunk_count_i
);

logic [`CHUNK_SIZE*8-1:0] mem_nonzero_data_r[`SRAM_IFM_NUM-1:0];
logic [`CHUNK_SIZE-1:0] mem_sparsemap_r[`SRAM_IFM_NUM-1:0];

initial begin
`ifdef CHANNEL_STACKING
	$readmemh("Mem_Stacking_IFM_Data.txt", mem_nonzero_data_r);
	$readmemh("Mem_Stacking_IFM_SparseMap.txt", mem_sparsemap_r);
`else
	$readmemh("Mem_Padding_IFM_Data.txt", mem_nonzero_data_r);
	$readmemh("Mem_Padding_IFM_SparseMap.txt", mem_sparsemap_r);
`endif
end

assign rd_nonzero_data_o = mem_nonzero_data_r[rd_chunk_count_i][`BUS_SIZE*rd_dat_count_i*8 +: `BUS_SIZE*8];
assign rd_sparsemap_o = mem_sparsemap_r[rd_chunk_count_i][`BUS_SIZE*rd_dat_count_i +: `BUS_SIZE];

endmodule
