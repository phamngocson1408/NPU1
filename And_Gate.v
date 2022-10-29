`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2022 01:35:48 PM
// Design Name: 
// Module Name: And_Gate
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


module And_Gate (
	 input  [`PREFIX_SUM_SIZE-1:0] IFM_i
	,input  [`PREFIX_SUM_SIZE-1:0] fil_i
	,output [`PREFIX_SUM_SIZE-1:0] out_o 
);

assign out_o = IFM_i & fil_i;

endmodule
