`timescale 100ps / 1ps
`define CYCLE 20

`define COMB_DAT_CHUNK
//`define CHUNK_PADDING

`ifndef COMB_DAT_CHUNK
	`define CHUNK_PADDING
	`ifdef IFM_REUSE
		`undef IFM_REUSE
	`endif
`endif

`define MEM_SIZE		128	//Bytes
`define BUS_SIZE		8	//Bytes
`define PREFIX_SUM_SIZE		8	//bits
`define OUTPUT_BUF_SIZE		32	//bits
`define OUTPUT_BUF_NUM		16 
`define COMPUTE_UNIT_NUM	1 
`define DAT_SIZE		8	//bits 
`define PARTIAL_OUT_SIZE	32	//bits 

`define IFM_DENSE_RATE 		70
`define FILTER_DENSE_RATE 	70

//`define SHORT_CHANNEL
//`define IFM_REUSE
`define CHANNEL_NUM 		8
