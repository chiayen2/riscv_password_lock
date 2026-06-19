.section .text
.globl _start

_start:
    # s0: remaining attempts, s1/s2: MMIO input/output, s3: current password.
    # MMIO input [0] btnU confirm, [4:1] sw[3:0], [5] btnD change-password.
    # MMIO output [3:0] LEDs, [7:4] attempt digit, [11:8] display mode.
    li s0, 3
    li s1, 0x80000000
    li s2, 0x80000004
    li s3, 0xA

update_display:
    # Display mode 0: show remaining attempt digit.
    slli t0, s0, 4
    sw t0, 0(s2)

wait_btn_press:
    lw t1, 0(s1)
    andi t2, t1, 1
    beq t2, zero, wait_btn_press

wait_btn_release:
    lw t1, 0(s1)
    andi t2, t1, 1
    bne t2, zero, wait_btn_release

    srli t3, t1, 1
    andi t3, t3, 0xF
    beq t3, s3, unlock_success

wrong_password:
    addi s0, s0, -1
    beq s0, zero, lock_dead
    j update_display

unlock_success:
    # Display mode 1: show PASS. LED0-LED3 on.
    li t0, 0x10F
    sw t0, 0(s2)

wait_change_press:
    # In unlocked/PASS state, btnD saves sw[3:0] as the new password.
    lw t1, 0(s1)
    andi t2, t1, 0x20
    beq t2, zero, wait_change_press

wait_change_release:
    lw t1, 0(s1)
    andi t2, t1, 0x20
    bne t2, zero, wait_change_release

    srli s3, t1, 1
    andi s3, s3, 0xF
    li s0, 3
    j update_display

lock_dead:
    # Attempts digit = 0, LED pattern = 1010. Reset is required to restart.
    li t0, 0x0A
    sw t0, 0(s2)
dead_loop:
    j dead_loop
