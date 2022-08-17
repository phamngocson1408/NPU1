`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2022 01:04:54 PM
// Design Name: 
// Module Name: Compute_Unit_Top
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


module Compute_Unit_Top #(
	 parameter MEM_SIZE = 128	//Bytes
	,parameter BUS_SIZE = 8	//Bytes
	,parameter PREFIX_SUM_SIZE = 8	//bits
	,parameter OUTPUT_BUF_SIZE = 32 // bits
	,parameter OUTPUT_BUF_NUM = 32
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

	,input [$clog2(OUTPUT_BUF_NUM)-1:0] acc_buf_sel_i

	,input [$clog2(OUTPUT_BUF_NUM)-1:0] out_buf_sel_i
	,output [OUTPUT_BUF_SIZE-1:0] out_buf_dat_o
);

	logic [OUTPUT_BUF_SIZE-1:0] acc_dat_i_w;
	logic acc_val_o_w;
	logic [OUTPUT_BUF_SIZE-1:0] acc_dat_o_w;

	Compute_Unit #(
		 .MEM_SIZE(MEM_SIZE)
		,.BUS_SIZE(BUS_SIZE)
		,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
		,.OUTPUT_BUF_SIZE(OUTPUT_BUF_SIZE)
	) u_Compute_Unit (
		 .*
		,.acc_dat_i(acc_dat_i_w)
		,.acc_val_o(acc_val_o_w)
		,.acc_dat_o(acc_dat_o_w)
	);

	Output_Buffer #(
		 .BUF_SIZE(OUTPUT_BUF_SIZE)
		,.BUF_NUM(OUTPUT_BUF_NUM)
	) u_Output_Buffer (
		 .*
		,.acc_sel_i(acc_buf_sel_i)
		,.acc_val_i(acc_val_o_w)
		,.acc_dat_i(acc_dat_o_w)
		,.acc_dat_o(acc_dat_i_w)

		,.out_sel_i(out_buf_sel_i)
		,.out_dat_o(out_buf_dat_o)
	);
	
endmodule
