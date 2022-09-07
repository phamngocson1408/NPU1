`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Son N. P. 
// 
// Create Date: 07/18/2022 02:30:13 PM
// Design Name: 
// Module Name: Priority_Encoder_Top
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


module Priority_Encoder_Top (
	 input rst_i
	,input clk_i
	,input valid_i
	,input chunk_start_i
	,input [`PREFIX_SUM_SIZE-1:0] in1_i
	,input [`PREFIX_SUM_SIZE-1:0] in2_i

	,output valid_o
	,output [$clog2(`PREFIX_SUM_SIZE)-1:0] match_addr_o
	,output pri_enc_last_o
);

	logic [`PREFIX_SUM_SIZE-1:0] and_gate_out;
	logic [`PREFIX_SUM_SIZE-1:0] pri_enc_i_r;
	logic [`PREFIX_SUM_SIZE-1:0] pri_enc_i_w;
	logic [$clog2(`PREFIX_SUM_SIZE):0] pri_enc_o_w;
	logic [`PREFIX_SUM_SIZE-1:0] pri_enc_next_w;
	
	
	And_Gate u_And_Gate (
	         .IFM_i(in1_i)
	        ,.filter_i(in2_i)
	        ,.out_o(and_gate_out)
	);
	
	Priority_Encoder_v2 u_Priority_Encoder (
	         .in_i(pri_enc_i_w)
	        ,.out_o(pri_enc_o_w)
	);
	
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			pri_enc_i_r <= #1 {`PREFIX_SUM_SIZE{1'b0}};
		end
		else if (valid_i) begin
			if (chunk_start_i) begin
				pri_enc_i_r <= #1 and_gate_out;
			end

			pri_enc_i_r[pri_enc_o_w] <= #1 1'b0;
		end
	end


	always_comb begin
		pri_enc_next_w = pri_enc_i_w;	
		pri_enc_next_w[pri_enc_o_w[$clog2(`PREFIX_SUM_SIZE)-1:0]] = 0;
	end
	
	assign pri_enc_i_w = chunk_start_i ? and_gate_out : pri_enc_i_r;

	assign match_addr_o = pri_enc_o_w[$clog2(`PREFIX_SUM_SIZE)-1:0];

	assign valid_o = (pri_enc_o_w != `PREFIX_SUM_SIZE) && valid_i;

	assign pri_enc_last_o = (~|pri_enc_next_w) && valid_i;

endmodule
