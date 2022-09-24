`timescale 100ps / 1ps
`define CYCLE 20

//`define SHORT_CHANNEL
//`define FULL_CHANNEL

`define CHANNEL_STACKING
//`define CHANNEL_PADDING

`define COMB_DAT_CHUNK

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

`define CHANNEL_NUM 		8


`ifdef SHORT_CHANNEL
	`undef FULL_CHANNEL
`else
	`define FULL_CHANNEL
`endif

`ifdef CHANNEL_STACKING
	`undef CHANNEL_PADDING
`else
	`define CHANNEL_PADDING
`endif

`ifdef CHANNEL_STACKING
	`ifndef COMB_DAT_CHUNK
		`define COMB_DAT_CHUNK
	`endif
`endif

