`timescale 100ps / 1ps
`define CYCLE 10

`define COMB_DAT_CHUNK
`define CHUNK_PADDING

`define MEM_SIZE		128	//Bytes
`define BUS_SIZE		8	//Bytes
`define PREFIX_SUM_SIZE		8	//bits
`define OUTPUT_BUF_SIZE		32	//bits
`define OUTPUT_BUF_NUM		32 
`define COMPUTE_UNIT_NUM	32 
`define DAT_SIZE		8	//bits 
`define PARTIAL_OUT_SIZE	32	//bits 

`define CHANNEL_NUM 		16

//`ifdef CHUNK_PADDING
//	if (`CHANNEL_NUM > `MEM_SIZE)
//		`define WR_DAT_CYC_NUM		`MEM_SIZE/`BUS_SIZE
//	elseif ((`CHANNEL_NUM % `BUS_SIZE)!=0)
//		`define WR_DAT_CYC_NUM		`CHANNEL_NUM/`BUS_SIZE + 1
//	else
//		`define WR_DAT_CYC_NUM		`CHANNEL_NUM/`BUS_SIZE
//
//	if (`CHANNEL_NUM > `MEM_SIZE)
//		`define RD_SPARSEMAP_NUM	`MEM_SIZE/`PREFIX_SUM_SIZE
//	elseif ((`CHANNEL_NUM % `BUS_SIZE)!=0)
//		`define RD_SPARSEMAP_NUM	`CHANNEL_NUM/`PREFIX_SUM_SIZE + 1
//	else
//		`define RD_SPARSEMAP_NUM	`CHANNEL_NUM/`PREFIX_SUM_SIZE
//`else
//	`define WR_DAT_CYC_NUM 		`MEM_SIZE/`BUS_SIZE
//	`define RD_SPARSEMAP_NUM	`MEM_SIZE/`PREFIX_SUM_SIZE
//`endif
