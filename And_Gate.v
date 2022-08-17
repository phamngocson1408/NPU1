`timescale 1ns / 1ps
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


module And_Gate #(
    parameter   SIZE = 128
    )(
      input  [SIZE-1:0] IFM_i
     ,input  [SIZE-1:0] filter_i
     ,output [SIZE-1:0] out_o 
    );

assign out_o = IFM_i & filter_i;

endmodule
