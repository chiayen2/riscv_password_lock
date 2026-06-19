set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ".."]]
set build_dir [file join $repo_dir "build" "vivado_project"]
set project_name "riscv_password_lock"

file mkdir $build_dir
cd $build_dir
create_project $project_name $build_dir -part xc7a35tcpg236-1 -force

add_files [list \
    [file join $repo_dir "src" "vendor" "picorv32" "picorv32.v"] \
    [file join $repo_dir "src" "rtl" "instruction_memory.v"] \
    [file join $repo_dir "src" "rtl" "mmio_controller.v"] \
    [file join $repo_dir "src" "rtl" "seven_segment_decoder.v"] \
    [file join $repo_dir "src" "rtl" "riscv_password_lock_top.v"] \
]
add_files -fileset constrs_1 [file join $repo_dir "constraints" "basys3_password_lock.xdc"]

set_property top riscv_password_lock_top [current_fileset]
set_property verilog_define "VIVADO=1" [current_fileset]
set_property generic "MEM_FILE=[file normalize [file join $repo_dir firmware final_project.mem]]" [get_filesets sources_1]

update_compile_order -fileset sources_1

puts "Vivado project created/opened:"
puts [file join $build_dir "${project_name}.xpr"]
puts ""
puts "To build inside this project, click Run Synthesis / Run Implementation / Generate Bitstream in Vivado."
puts "If you want Tcl to build immediately, run:"
puts "set RUN_IMPL 1"
puts "source [file join $repo_dir scripts create_vivado_project.tcl]"

if {[info exists RUN_IMPL] && $RUN_IMPL == 1} {
    reset_run synth_1
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1

    file mkdir [file join $repo_dir "build" "bitstream"]
    set bit_file [file join $build_dir $project_name ".runs" "impl_1" "riscv_password_lock_top.bit"]
    if {[file exists $bit_file]} {
        file copy -force $bit_file [file join $repo_dir "build" "bitstream" "final_project.bit"]
        puts "Bitstream copied to build/bitstream/final_project.bit"
    } else {
        puts "WARNING: Bitstream was not found at $bit_file"
    }
}
