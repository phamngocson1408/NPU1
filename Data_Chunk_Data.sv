`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2022 06:03:16 PM
// Design Name: 
// Module Name: Data_Chunk
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


module Data_Chunk_Data #(
)(
	 input rst_i
	,input clk_i
	,input [`BUS_SIZE-1:0][7:0] wr_nonzero_data_i 	//Bandwidth = 128 Bytes
	,input wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] wr_count_i

	,input [$clog2(`CHUNK_SIZE):0] rd_addr_i
	,output [7:0] rd_data_o
);
	
	//The Data array should start from 1
	logic [`CHUNK_SIZE:1][7:0] mem_nonzero_data_r;

	// Write data
	logic gated_clk_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_lat <= (rst_i || wr_valid_i);
		end
	end
	wire gated_clk_w = clk_i && gated_clk_lat;
	always_ff @(posedge gated_clk_w) begin
		if (rst_i) begin
			mem_nonzero_data_r <= {`CHUNK_SIZE{8'h00}};
		end
		else if (wr_valid_i) begin
			for (integer i=0; i<`WR_DAT_CYC_NUM; i=i+1) begin
				if (wr_count_i == i) begin
					mem_nonzero_data_r[(`BUS_SIZE*i+1) +: `BUS_SIZE] <= wr_nonzero_data_i;
				end
			end
		end
	end

	// Read Nonzero data
	assign rd_data_o = mem_nonzero_data_r[rd_addr_i];

endmodule
