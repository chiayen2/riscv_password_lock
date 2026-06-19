set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ".."]]
if {[info exists ::env(VIVADO_WORK_DIR)]} {
    set build_dir [file normalize [file join $::env(VIVADO_WORK_DIR) "vivado_sim"]]
} else {
    set build_dir [file join $repo_dir "build" "vivado_sim"]
}
file mkdir $build_dir
cd $build_dir

create_project riscv_password_lock_sim $build_dir -part xc7a35tcpg236-1 -force
add_files [list \
    [file join $repo_dir "src" "vendor" "picorv32" "picorv32.v"] \
    [file join $repo_dir "src" "rtl" "instruction_memory.v"] \
    [file join $repo_dir "src" "rtl" "mmio_controller.v"] \
    [file join $repo_dir "src" "rtl" "seven_segment_decoder.v"] \
    [file join $repo_dir "src" "rtl" "riscv_password_lock_top.v"] \
]
add_files -fileset sim_1 [file join $repo_dir "sim" "tb_riscv_password_lock.v"]
set_property top tb_riscv_password_lock [get_filesets sim_1]
set_property generic "MEM_FILE=[file normalize [file join $repo_dir firmware final_project.mem]]" [get_filesets sim_1]
launch_simulation
run all
