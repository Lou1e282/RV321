# Vivado/xsim waveform setup for tb_pipeline.
#
# Usage in the Vivado Tcl Console after launching simulation:
#   source sim_wave_pipeline.tcl
#   restart
#   run all

catch {create_wave_config tb_pipeline_wave}

proc tb_add_divider {name} {
    catch {add_wave_divider $name}
}

tb_add_divider "Clock / Reset"
add_wave -radix unsigned /tb_pipeline/cycle
add_wave /tb_pipeline/clk
add_wave /tb_pipeline/rst_n

tb_add_divider "Pipeline PCs / Instructions"
add_wave -radix hexadecimal /tb_pipeline/if_pc
add_wave -radix hexadecimal /tb_pipeline/if_instr
add_wave -radix hexadecimal /tb_pipeline/id_pc
add_wave -radix hexadecimal /tb_pipeline/id_instr
add_wave -radix hexadecimal /tb_pipeline/ex_pc

tb_add_divider "Decode Register Fields"
add_wave -radix unsigned /tb_pipeline/id_rs1
add_wave -radix unsigned /tb_pipeline/id_rs2
add_wave -radix unsigned /tb_pipeline/id_rd
add_wave -radix unsigned /tb_pipeline/ex_rs1
add_wave -radix unsigned /tb_pipeline/ex_rs2
add_wave -radix unsigned /tb_pipeline/ex_rd

tb_add_divider "Execute / ALU"
add_wave -radix hexadecimal /tb_pipeline/ex_alu_a
add_wave -radix hexadecimal /tb_pipeline/ex_alu_b
add_wave -radix hexadecimal /tb_pipeline/ex_alu_y
add_wave /tb_pipeline/ex_branch_taken

tb_add_divider "Hazard / Forwarding"
add_wave -radix binary /tb_pipeline/hazard_forward_a_sel
add_wave -radix binary /tb_pipeline/hazard_forward_b_sel
add_wave /tb_pipeline/hazard_pc_stall
add_wave /tb_pipeline/hazard_if_id_stall
add_wave /tb_pipeline/hazard_if_id_flush
add_wave /tb_pipeline/hazard_id_ex_flush
add_wave /tb_pipeline/hazard_load_use_stall_event
add_wave /tb_pipeline/hazard_branch_flush_event

tb_add_divider "Writeback"
add_wave /tb_pipeline/wb_regwrite
add_wave -radix unsigned /tb_pipeline/wb_rd
add_wave -radix hexadecimal /tb_pipeline/wb_data

tb_add_divider "Register File x0-x31"
for {set i 0} {$i < 32} {incr i} {
    add_wave -radix hexadecimal /tb_pipeline/rf_x$i
}

tb_add_divider "Named Check Registers"
add_wave -radix hexadecimal /tb_pipeline/rf_x1_base_addr
add_wave -radix hexadecimal /tb_pipeline/rf_x2_loaded_word
add_wave -radix hexadecimal /tb_pipeline/rf_x3_load_use_result
add_wave -radix hexadecimal /tb_pipeline/rf_x4_forwarded_addi_result
add_wave -radix hexadecimal /tb_pipeline/rf_x5_forwarded_add_result
add_wave -radix hexadecimal /tb_pipeline/rf_x6_should_stay_zero
add_wave -radix hexadecimal /tb_pipeline/rf_x7_should_stay_zero
add_wave -radix hexadecimal /tb_pipeline/rf_x8_pass_value

tb_add_divider "Data Memory"
add_wave -radix hexadecimal /tb_pipeline/dmem_pass_sentinel
