set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ".."]]

if {[namespace exists ::tclapp] && [info commands ::tclapp::tcl_store_on] ne ""} {
    catch {rename ::tclapp::tcl_store_on ::tclapp::tcl_store_on_original}
    proc ::tclapp::tcl_store_on {} { return 0 }
}
if {[namespace exists ::tclapp] && [info commands ::tclapp::use_local] ne ""} {
    catch {rename ::tclapp::use_local ::tclapp::use_local_original}
    proc ::tclapp::use_local {} { return 0 }
}

set out_dir [file join $repo_dir "build" "bitstream"]
if {[info exists ::env(VIVADO_WORK_DIR)]} {
    set work_dir [file normalize [file join $::env(VIVADO_WORK_DIR) "bitstream_nonproject"]]
} else {
    set work_dir [file join $repo_dir "build" "bitstream_nonproject"]
}
set run_out_dir [file join $work_dir "out"]
file mkdir $work_dir
file mkdir $run_out_dir
file mkdir $out_dir
cd $work_dir

read_verilog [list \
    [file join $repo_dir "src" "vendor" "picorv32" "picorv32.v"] \
    [file join $repo_dir "src" "rtl" "instruction_memory.v"] \
    [file join $repo_dir "src" "rtl" "mmio_controller.v"] \
    [file join $repo_dir "src" "rtl" "seven_segment_decoder.v"] \
    [file join $repo_dir "src" "rtl" "riscv_password_lock_top.v"] \
]
read_xdc [file join $repo_dir "constraints" "basys3_password_lock.xdc"]

set mem_file [file normalize [file join $repo_dir "firmware" "final_project.mem"]]
synth_design -top riscv_password_lock_top -part xc7a35tcpg236-1 -generic "MEM_FILE=$mem_file"
opt_design
place_design
route_design

write_checkpoint -force [file join $run_out_dir "final_project_routed.dcp"]
write_bitstream -force [file join $run_out_dir "final_project.bit"]
report_utilization -file [file join $run_out_dir "utilization_report.txt"]
report_timing_summary -file [file join $run_out_dir "timing_summary.txt"]

file copy -force [file join $run_out_dir "final_project_routed.dcp"] [file join $out_dir "final_project_routed.dcp"]
file copy -force [file join $run_out_dir "final_project.bit"] [file join $out_dir "final_project.bit"]
file copy -force [file join $run_out_dir "utilization_report.txt"] [file join $out_dir "utilization_report.txt"]
file copy -force [file join $run_out_dir "timing_summary.txt"] [file join $out_dir "timing_summary.txt"]
puts "Bitstream written to [file join $out_dir final_project.bit]"
