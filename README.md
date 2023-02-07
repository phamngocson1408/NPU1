To run on Vivado
1. Create Vivado version 2021.2 project
   1.1 Select  Zynq UltraScale+ ZCU104 Evaluation Board
2. Pull the NPU1 to source folder of Vivado project
3. Rename NPU1 to new
4. Move *.tb, Mem_Gen* files to Simulation Sources
5. Click Setting
   5.1. in Simulation tab:
      5.1.1. Set Simulation runtime to 1ms
      5.1.2. Save saif file + check saif_all_signals
   5.2 in Synthesis tab:
      Choose -faltten_hierarchy = none
6. Generate data first
	6.1 Set Mem_Gen_*_File as Top
	6.2 Data is generated in sim1/behave/xsim
7. Or compy data from githup folder to sim1/behave/xsim


20220817 - Add Output_Buffer.sv
20220828 - Add Compute_Clustersv
20220828-16:00 - Add COMB_DAT_CHUNK define macro
20220902 - Simulate at 1GHz
20220903 - Change to global parameters
20220903-16:33 - To run multiple filter batches
20220903-16:33 - Before adding shallow channels
20220904 - Before moving chunk_start_i to the fist cycle of chunk
20220904-16:27 - After moving chunk_start_i to the fist cycle of chunk
20220907 - Before combining multiple thin channels
20220911 - After combining multiple thin channels
20220911-17:52 - Add missing file
20220911-18:33 - Correct chunk padding scenerial
20220911-23:55 - Change IFM_Dat_Chunk_Comb.sv
20220912-02:16 - Correct Priority_Encoder_Top.sv
20220913-18:42 - Correct simulation condition
20220919 - Add Data_Addr_Cal.sv
20220920 - Before removing #1
20220921 - Simulate short channel
20220921-17:26 - Add IFM_REUSE
20220923 - Breakdown Dat_Chunk_Comb to analyze power
20220923-17:46 - Add buffer RAMs
20220925 - Rearrange Macros
20220925-16:23 - Pass all tests
20220925-17:40 - Fix rd_total_filter_buf
20221002 - Split Mem_Gen
20221009 - Use nonblocking procedures in tb
20221010 - Gated clock
20221012 - Not much changed
20221012-17:22 - Gate clock with latch
20221029 - Finish makine CHANNEL_STACKING
20221029-17:46 - Before changing name
20221030 - Finish makine CHANNEL_PADDING
20221101 - Before making short channel
20221102 - After making short channel
20221103 - Before fragment filter chunk
20221105 - After fragment filter chunk
20221105-8:22 - Create inner loop
20221107 - Make ifm_loop_y_idx out of order
20221108 - Can operate but not completed
20221108-16:02 - Forget adding Stacking_Inner_Loop.sv
20221108 - Make ifm_loop_y_idx in order
20221117 - Create Only_Sim_tb.sv
20230206 - Clean Global_Include.vh
20230206-15:30 - Rename Data_Chunk_Top.sv to Data_Chunk_Top_IFM.sv
20230207 - Generate memories in files