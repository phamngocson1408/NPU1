`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2022 12:32:36 PM
// Design Name: 
// Module Name: Output_Buffer
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


module Output_Buffer (
	 input rst_i
	,input clk_i
	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] acc_sel_i
	,input acc_val_i
	,input [`OUTPUT_BUF_SIZE-1:0] acc_dat_i
	,output [`OUTPUT_BUF_SIZE-1:0] acc_dat_o

//	,input [$clog2(`OUTPUT_BUF_NUM)-1:0] out_sel_i
	,output [`OUTPUT_BUF_SIZE-1:0] out_dat_o
);

	logic [`OUTPUT_BUF_NUM-1:0][`OUTPUT_BUF_SIZE-1:0] partial_output_mem;

	integer i;

	logic gated_clk_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_lat <= (rst_i || acc_val_i);
		end
	end
	wire gated_clk_w = clk_i && gated_clk_lat;
	always_ff @(posedge gated_clk_w) begin
		if (rst_i) begin
			for(i=0; i<`OUTPUT_BUF_NUM; i=i+1) begin
				partial_output_mem[i] <= {`OUTPUT_BUF_SIZE{1'b0}};
			end
		end
		else if (acc_val_i) begin
			partial_output_mem[acc_sel_i] <= acc_dat_i;
		end
	end

	assign acc_dat_o = partial_output_mem[acc_sel_i];
	assign out_dat_o = acc_dat_o;

endmodule
