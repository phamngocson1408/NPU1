`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/13/2022 01:57:40 PM
// Design Name: 
// Module Name: MAC
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


module MAC (
	 input rst_i
	,input clk_i

	,input [`DAT_SIZE-1:0] in1_i
	,input [`DAT_SIZE-1:0] in2_i
	,input valid_i

	,input [`OUTPUT_BUF_SIZE-1:0] acc_dat_i	
	,output acc_val_o
	,output [`OUTPUT_BUF_SIZE-1:0] acc_dat_o
    	);

	logic [`DAT_SIZE*2-1:0] mul_r;
	logic valid_r;
	wire dat_changed_w = mul_r != {(`DAT_SIZE*2){1'b0}};

	logic gated_clk_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_lat <= (rst_i || valid_i || dat_changed_w);
		end
	end
	wire gated_clk_w = clk_i && gated_clk_lat;
	always_ff @(posedge gated_clk_w) begin
		if (rst_i) begin
			mul_r <= {(`DAT_SIZE*2){1'b0}};	
			valid_r <= 1'b0;
		end
		else if (valid_i) begin
			mul_r <= in1_i * in2_i;
			valid_r <= 1'b1;
		end
		else begin
			mul_r <= {(`DAT_SIZE*2){1'b0}};	
			valid_r <= 1'b0;
		end
	end

	assign acc_dat_o = acc_dat_i + mul_r;
	assign acc_val_o = valid_r;

endmodule
