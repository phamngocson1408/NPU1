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
	,input [BUS_SIZE-1:0][7:0] ifm_nonzero_data_i
	,input ifm_wr_valid_i
	,input [$clog2(MEM_SIZE/BUS_SIZE)-1:0] ifm_wr_count_i
	,input ifm_wr_sel_i
	,input ifm_rd_sel_i

	,input [BUS_SIZE-1:0] filter_sparsemap_i
	,input [BUS_SIZE-1:0][7:0] filter_nonzero_data_i
	,input filter_wr_valid_i
	,input [$clog2(MEM_SIZE/BUS_SIZE)-1:0] filter_wr_count_i
	,input filter_wr_sel_i
	,input filter_rd_sel_i

	,input init_i
	,input chunk_start_i

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
		 .rst_i
		,.clk_i
		
		,.ifm_sparsemap_i
		,.ifm_nonzero_data_i
		,.ifm_wr_valid_i
		,.ifm_wr_count_i
		,.ifm_wr_sel_i
		,.ifm_rd_sel_i
		
		,.filter_sparsemap_i
		,.filter_nonzero_data_i
		,.filter_wr_valid_i
		,.filter_wr_count_i
		,.filter_wr_sel_i
		,.filter_rd_sel_i
		
		,.init_i
		,.chunk_start_i
		
		,.ifm_data_o(ifm_data_w)
		,.filter_data_o(filter_data_w)
		,.data_valid_o(data_valid_w)
		,.chunk_end_o
	);

	MAC #(
		 .DATA_SIZE(8)
		,.OUTPUT_BUF_SIZE(OUTPUT_BUF_SIZE)
	) u_MAC (
		 .rst_i
		,.clk_i
		
		,.in1_i(ifm_data_w)
		,.in2_i(filter_data_w)
		,.valid_i(data_valid_w)
		,.chunk_end_i(chunk_end_o)
		
		,.acc_dat_i	
		,.acc_val_o
		,.acc_dat_o
	);

endmodule
