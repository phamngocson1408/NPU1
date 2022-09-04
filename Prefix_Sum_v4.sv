`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Son N. P. 
// 
// Create Date: 07/19/2022 11:10:05 AM
// Design Name: 
// Module Name: Prefix_Sum
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


module Prefix_Sum_v4 (
	 input [`PREFIX_SUM_SIZE:1] in_i
	,output [$clog2(`PREFIX_SUM_SIZE):0] out_o [`PREFIX_SUM_SIZE:1]
);

	genvar d,i;
	genvar b,j;

	// Reduce
	for (d=0; d<=$clog2(`PREFIX_SUM_SIZE); d=d+1) begin: reduce_layer_b
		for (i=1; i<=`PREFIX_SUM_SIZE; i=i+1) begin: reduce_item_b
			logic [d:0] temp;
			if (d==0) begin
				assign temp = in_i[i];
			end
			else if (i%(2**d) == 0) begin
				assign temp = reduce_layer_b[d-1].reduce_item_b[i - (2**(d-1))].temp + reduce_layer_b[d-1].reduce_item_b[i].temp;
			end
			else begin
				assign temp = reduce_layer_b[d-1].reduce_item_b[i].temp;
			end
		end: reduce_item_b
	end: reduce_layer_b

	// Down sweep
	for (b=0; b<$clog2(`PREFIX_SUM_SIZE); b=b+1) begin: down_layer_b
		for (j=1; j<=`PREFIX_SUM_SIZE; j=j+1) begin: down_item_b
			localparam a = $clog2(`PREFIX_SUM_SIZE) - b;
			logic [$clog2(`PREFIX_SUM_SIZE):0] temp;
			if (a==$clog2(`PREFIX_SUM_SIZE)) begin
				assign temp = reduce_layer_b[$clog2(`PREFIX_SUM_SIZE)].reduce_item_b[j].temp;
			end
			else if ((j-(2**(a-1)))%(2**a)==0 & j > (2**(a-1))) begin
				assign temp = down_layer_b[b-1].down_item_b[j-(2**(a-1))].temp + down_layer_b[b-1].down_item_b[j].temp;
			end
			else begin
				assign temp = down_layer_b[b-1].down_item_b[j].temp;
			end

			if (a==1) begin
				assign out_o[j] = temp;
			end
		end: down_item_b
	end: down_layer_b
    
    
endmodule

