`timescale 10ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2022 04:06:08 AM
// Design Name: 
// Module Name: Only_Sim_tb
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

`define CYCLE 10

module Only_Sim_tb(
);

/*******************************************************************************************************/
//CLock generate
reg clk_i;
initial begin
	clk_i=0;
	#(`CYCLE/2);
	while (1) begin
		clk_i = ~clk_i;
		#(`CYCLE/2);
	end
end

/*******************************************************************************************************/
// Layer define
localparam int BUS_SIZE = 8;
localparam int STRIDE = 2;
localparam int LAY_CHNL_NUM = 3;
localparam int LAY_FIL_SIZE_X = 7;
localparam int LAY_FIL_SIZE_Y = 7;
localparam int LAY_OUT_SIZE_X = 7;
localparam int LAY_OUT_SIZE_Y = 14;
localparam int LAY_IFM_SIZE_X = (LAY_OUT_SIZE_X - 1) * STRIDE + 1 + LAY_FIL_SIZE_X - 1; 
localparam int LAY_IFM_SIZE_Y = (LAY_OUT_SIZE_Y - 1) * STRIDE + 1 + LAY_FIL_SIZE_Y - 1; 

/*********************************************/
//Channel stacking
int sta_fil_dat_rd_num;
int sta_ifm_dat_rd_num;
//int sta_tot_dat_rd_num;

localparam int STA_DIV_CHNL_NUM = 8;
localparam int STA_LOOP_Z_NUM = (LAY_CHNL_NUM % STA_DIV_CHNL_NUM) ? (LAY_CHNL_NUM / STA_DIV_CHNL_NUM) + 1 : (LAY_CHNL_NUM / STA_DIV_CHNL_NUM);
localparam int STA_LAST_CHNL_SIZE = (LAY_CHNL_NUM % STA_DIV_CHNL_NUM) ? (LAY_CHNL_NUM % STA_DIV_CHNL_NUM) : STA_DIV_CHNL_NUM;

int sta_loop_z_idx;
int sta_ifm_loop_y_idx;
int sta_sub_chnl_size;
int sta_fil_chnk_dat_size;
int sta_fil_chnk_dat_wr_cyc_num;
int sta_ifm_chnk_dat_size;
int sta_ifm_chnk_dat_wr_cyc_num;

/*********************************************/
//Channel padding
int pad_fil_dat_rd_num;
int pad_ifm_dat_rd_num;
//int pad_tot_dat_rd_num;
localparam int PAD_CHNK_SIZE = 128;
localparam int PAD_LOOP_Z_NUM = (LAY_CHNL_NUM % PAD_CHNK_SIZE) ? (LAY_CHNL_NUM / PAD_CHNK_SIZE) + 1 : (LAY_CHNL_NUM / PAD_CHNK_SIZE);
localparam int PAD_LAST_CHNL_SIZE = (LAY_CHNL_NUM % PAD_CHNK_SIZE) ? (LAY_CHNL_NUM % PAD_CHNK_SIZE) : PAD_CHNK_SIZE;

int pad_loop_z_idx;
int pad_chnk_dat_size;
int pad_chnk_dat_wr_cyc_num;
int pad_fil_loop_y_idx;
int pad_fil_loop_x_idx;
int pad_ifm_loop_y_idx;
int pad_ifm_loop_x_idx;

initial begin
fork
	/*********************************************/
	//Channel stacking
	begin
		sta_fil_dat_rd_num = 0;
		sta_ifm_dat_rd_num = 0;
		//sta_tot_dat_rd_num = 0;
		for (sta_loop_z_idx = 0; sta_loop_z_idx < STA_LOOP_Z_NUM; sta_loop_z_idx += 1) begin
		
			if (sta_loop_z_idx == STA_LOOP_Z_NUM - 1)
				sta_sub_chnl_size = STA_LAST_CHNL_SIZE;
			else
				sta_sub_chnl_size = STA_DIV_CHNL_NUM;

			sta_fil_chnk_dat_size = LAY_FIL_SIZE_X * LAY_FIL_SIZE_Y * sta_sub_chnl_size;
			sta_fil_chnk_dat_wr_cyc_num = (sta_fil_chnk_dat_size % BUS_SIZE) ? sta_fil_chnk_dat_size/BUS_SIZE + 1 : sta_fil_chnk_dat_size/BUS_SIZE;
			sta_fil_dat_rd_num += sta_fil_chnk_dat_wr_cyc_num * (BUS_SIZE + 1);
		
			sta_ifm_chnk_dat_size = LAY_IFM_SIZE_X * sta_sub_chnl_size;
			sta_ifm_chnk_dat_wr_cyc_num = (sta_ifm_chnk_dat_size % BUS_SIZE) ? sta_ifm_chnk_dat_size/BUS_SIZE + 1 : sta_ifm_chnk_dat_size/BUS_SIZE;
			for (sta_ifm_loop_y_idx = 0; sta_ifm_loop_y_idx < LAY_IFM_SIZE_Y; sta_ifm_loop_y_idx += 1) begin
				sta_ifm_dat_rd_num += sta_ifm_chnk_dat_wr_cyc_num * (BUS_SIZE + 1);
				//sta_tot_dat_rd_num = sta_fil_dat_rd_num + sta_ifm_dat_rd_num;
				@ (posedge clk_i);
			end
		end
	end

	/*********************************************/
	//Channel padding
	begin
		pad_fil_dat_rd_num = 0;
		pad_ifm_dat_rd_num = 0;
		//pad_tot_dat_rd_num = 0;
		for (pad_loop_z_idx = 0; pad_loop_z_idx < PAD_LOOP_Z_NUM; pad_loop_z_idx += 1) begin
		
			if (pad_loop_z_idx == PAD_LOOP_Z_NUM - 1)
				pad_chnk_dat_size = PAD_LAST_CHNL_SIZE;
			else
				pad_chnk_dat_size = PAD_CHNK_SIZE;

			pad_chnk_dat_wr_cyc_num = (pad_chnk_dat_size % BUS_SIZE) ? pad_chnk_dat_size / BUS_SIZE + 1 : pad_chnk_dat_size / BUS_SIZE;

			for (pad_fil_loop_y_idx = 0; pad_fil_loop_y_idx < LAY_FIL_SIZE_Y; pad_fil_loop_y_idx += 1) begin
				for (pad_fil_loop_x_idx = 0; pad_fil_loop_x_idx < LAY_FIL_SIZE_X; pad_fil_loop_x_idx += 1) begin
					pad_fil_dat_rd_num += pad_chnk_dat_wr_cyc_num * (BUS_SIZE + 1);

					for (pad_ifm_loop_y_idx = 0; pad_ifm_loop_y_idx < LAY_OUT_SIZE_Y; pad_ifm_loop_y_idx += 1) begin
						for (pad_ifm_loop_x_idx = 0; pad_ifm_loop_x_idx < LAY_OUT_SIZE_X; pad_ifm_loop_x_idx += 1) begin
							pad_ifm_dat_rd_num += pad_chnk_dat_wr_cyc_num * (BUS_SIZE + 1);
							//pad_tot_dat_rd_num = pad_fil_dat_rd_num + pad_ifm_dat_rd_num;				
							@ (posedge clk_i);
						end
					end
				end
			end
		
		end
	end
join
$display("Stacking ifm: %d", sta_ifm_dat_rd_num);
$display("Stacking fil: %d", sta_fil_dat_rd_num);
$display("Padding ifm: %d", pad_ifm_dat_rd_num);
$display("Padding fil: %d", pad_fil_dat_rd_num);
$finish();
end

endmodule
