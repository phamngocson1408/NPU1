`timescale 100ps / 1ps
`define CYCLE 20

//`define SHORT_CHANNEL

`define CHANNEL_STACKING

`define COMB_DAT_CHUNK

`define RUN_TIME		10

`ifdef CHANNEL_STACKING
	`define CHUNK_SIZE	128*2	//Bytes
`elsif CHANNEL_PADDING
	`define CHUNK_SIZE	128	//Bytes
`endif

`define BUS_SIZE		8	//Bytes
`define PREFIX_SUM_SIZE		8	//bits
`define OUTPUT_BUF_SIZE		32	//bits
`define OUTPUT_BUF_NUM		100 
`define COMPUTE_UNIT_NUM	8 
`define DAT_SIZE		8	//bits 
`define DIVIDED_CHANNEL_NUM 	8

`define IFM_DENSE_RATE 		70
`define FILTER_DENSE_RATE 	70

// Do not change when FULL_CHANNEL and CHANNEL_PADDING
`define LAYER_CHANNEL_NUM 	192
`define LAYER_FILTER_SIZE_MAX 	11
`define LAYER_FILTER_SIZE_X 	3
`define LAYER_FILTER_SIZE_Y 	3
`define LAYER_OUTPUT_SIZE_X 	10
`define LAYER_OUTPUT_SIZE_Y 	10
`define LAYER_IFM_SIZE_X 	(`LAYER_FILTER_SIZE_X + `LAYER_OUTPUT_SIZE_X - 1)
`define LAYER_IFM_SIZE_Y 	(`LAYER_FILTER_SIZE_Y + `LAYER_OUTPUT_SIZE_Y - 1)

`define SRAM_IFM_NUM 		10000
`define SRAM_FILTER_NUM 	1000

`define WR_DAT_CYC_NUM		(`CHUNK_SIZE/`BUS_SIZE)
`define RD_DAT_CYC_NUM		(`CHUNK_SIZE/`PREFIX_SUM_SIZE)

`ifdef CHANNEL_STACKING
	`define SIM_CHUNK_SIZE	256
`elsif CHANNEL_PADDING
	`define SIM_CHUNK_SIZE	128	//Bytes
`endif

`define SIM_WR_DAT_CYC_NUM	(`SIM_CHUNK_SIZE/`BUS_SIZE)
`define SIM_RD_DAT_CYC_NUM	(`SIM_CHUNK_SIZE/`PREFIX_SUM_SIZE)


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
	`define COMB_DAT_CHUNK
`endif

