`timescale 1ns / 1ps
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


module Priority_Encoder_Top #(
	parameter SIZE = 128
)(
	 input rst_i
	,input clk_i
	,input valid_i
	,input [SIZE-1:0] in1_i
	,input [SIZE-1:0] in2_i

	,output valid_o
	,output [$clog2(SIZE)-1:0] match_addr_o
	,output pri_enc_end_o
);

	logic [SIZE-1:0] and_gate_out;
	logic [SIZE-1:0] pri_enc_i_r;
	logic [SIZE-1:0] pri_enc_i_w;
	logic [$clog2(SIZE):0] pri_enc_o_w;
	logic [SIZE-1:0] pri_enc_temp_w;
	
	
	And_Gate #(
	        .SIZE(SIZE)
	) u_And_Gate (
	         .IFM_i(in1_i)
	        ,.filter_i(in2_i)
	        ,.out_o(and_gate_out)
	);
	
	Priority_Encoder_v2  #(
	        .SIZE(SIZE)
	) u_Priority_Encoder (
	         .in_i(pri_enc_i_w)
	        ,.out_o(pri_enc_o_w)
	);
	
	localparam INPUT_CHANGE = 0;
	localparam FLY = 1;
	logic  state_r;
	
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			state_r <= #1 INPUT_CHANGE;
		end
		else if (valid_i) begin
			if ((state_r == INPUT_CHANGE)) begin
				if (!pri_enc_end_o) begin
					state_r <= #1 FLY;
				end
			end
			else begin	// FLY
				if (pri_enc_end_o) begin
					state_r <= #1 INPUT_CHANGE;
				end
			end
		end
	end

	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			pri_enc_i_r <= #1 {SIZE{1'b0}};
		end
		else if (valid_i) begin
			if ((state_r == INPUT_CHANGE)) begin
				pri_enc_i_r <= #1 and_gate_out;
				pri_enc_i_r[pri_enc_o_w] <= #1 1'b0;
			end
			else begin	// FLY
				if (!pri_enc_end_o) begin
					pri_enc_i_r[pri_enc_o_w] <= #1 1'b0;
				end
			end
		end
	end

	always_comb begin
		pri_enc_temp_w = pri_enc_i_w;	
		pri_enc_temp_w[pri_enc_o_w[$clog2(SIZE)-1:0]] = 0;
	end
	
	assign pri_enc_i_w = 	  !valid_i ? {SIZE{1'b1}}
				: (state_r == INPUT_CHANGE) ? and_gate_out 
				: pri_enc_i_r;
	assign match_addr_o = pri_enc_o_w[$clog2(SIZE)-1:0];
	assign valid_o = (pri_enc_o_w != SIZE) && valid_i;
	assign pri_enc_end_o = (~|pri_enc_temp_w) && valid_i;

endmodule
