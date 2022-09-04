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


module IFM_Input_Sel (
	 input rst_i
	,input clk_i

	,input [$clog2(`PREFIX_SUM_SIZE)-1:0] pri_enc_match_addr_i
	,input pri_enc_end_i
	,input chunk_end_i

	,input [`PREFIX_SUM_SIZE-1:0] rd_sparsemap_i	
	,output [$clog2(`MEM_SIZE):0] rd_addr_o
);
	
	logic [$clog2(`PREFIX_SUM_SIZE):0] prefix_sum_out_w [`PREFIX_SUM_SIZE-1:0];

	logic [$clog2(`MEM_SIZE):0] rd_data_base_addr_r;	
	logic [$clog2(`PREFIX_SUM_SIZE):0] rd_data_addr_temp_w;	

	Prefix_Sum_v4 u_Prefix_Sum (
		.in_i(rd_sparsemap_i)
		,.out_o(prefix_sum_out_w)
	);

	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			rd_data_base_addr_r <= #1 {($clog2(`MEM_SIZE) + 1){1'b0}};
		end
		else if (chunk_end_i) begin
			rd_data_base_addr_r <= #1 {($clog2(`MEM_SIZE) + 1){1'b0}};
		end
		else if (pri_enc_end_i) begin
			rd_data_base_addr_r <= #1 rd_data_base_addr_r + prefix_sum_out_w[`PREFIX_SUM_SIZE-1];
		end
	end

	assign rd_data_addr_temp_w = prefix_sum_out_w[pri_enc_match_addr_i];
	assign rd_addr_o = rd_data_base_addr_r + rd_data_addr_temp_w;

endmodule
