`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2022 05:39:01 PM
// Design Name: 
// Module Name: Priority_Encoder
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


module Priority_Encoder_Exam_v2
    #(
    parameter SIZE = 4
    )(
     input [SIZE-1:0] in_i
    ,output[SIZE-1:0] out_o
    );

    reg [SIZE-1:0] out_r;
    integer i;

    always @(*) begin
/*  
    	out_r = {SIZE{1'b0}};   
          for (i=0; i<SIZE; i=i+1) begin  
               if (in_i[i:0] == 1<<i) out_r = i;
          end
*/
/*
        out_r = 0;
        if (in_i[0] == 1'b1) out_r = 1;
        if (in_i[1:0] == 2'b10) out_r = 2;
        if (in_i[2:0] == 3'b100) out_r = 3;
        if (in_i[3:0] == 4'b1000) out_r = 4;
*/
/*
        if (in_i[0] == 1'b1) out_r = 1;
        else if (in_i[1:0] == 2'b10) out_r = 2;
        else if (in_i[2:0] == 3'b100) out_r = 3;
        else if (in_i[3:0] == 4'b1000) out_r = 4;
        else  out_r = 0;
*/        

        casex (in_i)
            4'b???1 : begin out_r = 1; end
            4'b??10 : begin out_r = 2; end
            4'b?100 : begin out_r = 3; end
            4'b1000 : begin out_r = 4; end
            default : begin out_r = 0; end
        endcase
        
    end

    assign out_o = out_r;

endmodule
