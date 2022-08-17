`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/13/2022 02:13:19 PM
// Design Name: 
// Module Name: Compute_Unit
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


module Compute_Unit #(
	 parameter MEM_SIZE = 128	//Bytes
	,parameter BUS_SIZE = 8	//Bytes
	,parameter PREFIX_SUM_SIZE = 8	//bits
	,parameter OUTPUT_BUF_SIZE = 32 // bits
)(
	 input rst_i
	,input clk_i
	,input [BUS_SIZE-1:0] ifm_sparsemap_i
	,input [BUS_SIZE*8-1:0] ifm_nonzero_data_i
	,input ifm_wr_valid_i
	,output ifm_wr_ready_o
	,input [BUS_SIZE-1:0] filter_sparsemap_i
	,input [BUS_SIZE*8-1:0] filter_nonzero_data_i
	,input filter_wr_valid_i
	,output filter_wr_ready_o

	,output chunk_end_o

	,input [OUTPUT_BUF_SIZE-1:0] acc_dat_i
	,output acc_val_o
	,output [OUTPUT_BUF_SIZE-1:0] acc_dat_o
);

	logic [7:0] ifm_data_w;
	logic [7:0] filter_data_w;
	logic data_valid_w;

	Input_Selector_v2 #(
		 .MEM_SIZE(MEM_SIZE)
		,.BUS_SIZE(BUS_SIZE)
		,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
	) u_Input_Selector (
		 .*
		,.ifm_data_o(ifm_data_w)
		,.filter_data_o(filter_data_w)
		,.data_valid_o(data_valid_w)
	);

	MAC #(
		 .DATA_SIZE(8)
		,.OUTPUT_BUF_SIZE(OUTPUT_BUF_SIZE)
	) u_MAC (
		 .in1_i(ifm_data_w)
		,.in2_i(filter_data_w)
		,.valid_i(data_valid_w)
		,.chunk_end_i(chunk_end_o)
		,.*
	);

endmodule
