`timescale 100ps / 1ps
`define CYCLE 10

`define COMB_DAT_CHUNK
`define CHUNK_PADDING

`ifndef COMB_DAT_CHUNK
	`define CHUNK_PADDING
`endif

`define MEM_SIZE		128	//Bytes
`define BUS_SIZE		8	//Bytes
`define PREFIX_SUM_SIZE		8	//bits
`define OUTPUT_BUF_SIZE		32	//bits
`define OUTPUT_BUF_NUM		32 
`define COMPUTE_UNIT_NUM	32 
`define DAT_SIZE		8	//bits 
`define PARTIAL_OUT_SIZE	32	//bits 

`define CHANNEL_NUM 		3
`define IFM_DENSE_RATE 		75
`define FILTER_DENSE_RATE 	75

