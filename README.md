# RISC-V MMIO Dynamic Password Lock on Basys 3

This repository contains the source code for a final project in Digital System Design with Lab.

The project implements a 4-bit dynamic password lock on a Digilent Basys 3 FPGA. A PicoRV32 RISC-V CPU controls the lock through memory-mapped I/O. The user enters a password with `sw[3:0]`, confirms with `btnU`, and can change the password with `btnD` after a successful unlock.

## Features

- PicoRV32 RV32I soft CPU
- Memory-mapped I/O interface
- 4-bit password input through `sw[3:0]`
- `btnU` confirm input
- `btnD` password-change input after unlock
- `btnC` reset, restoring the default password `1010`
- LED unlock/alarm status
- Seven-segment display for remaining attempts and `PASS`
- Firmware, simulation testbench, Vivado project script, and bitstream build script

## Hardware

- Board: Digilent Basys 3
- FPGA part: `xc7a35tcpg236-1`
- Verified tool: Vivado 2025.2

## Button and Switch Controls

| Control | Function |
|---|---|
| `btnC` | Hardware reset. It restarts the system, restores the default password `1010`, clears the unlocked state, and resets remaining attempts to 3. |
| `btnU` | Confirm button. Press and release it to submit the current `sw[3:0]` password input. |
| `btnD` | Change-password button. It is active only after a successful unlock while `PASS` is displayed. |
| `sw[3:0]` | 4-bit password input or new-password value. |

## Folder Structure

```text
.
|-- constraints/
|   `-- basys3_password_lock.xdc
|-- bitstream/
|   `-- final_project.bit
|-- firmware/
|   |-- final_project.s
|   |-- final_project.bin
|   |-- final_project.hex
|   `-- final_project.mem
|-- scripts/
|   |-- assemble_firmware.py
|   |-- build_bitstream_nonproject.tcl
|   |-- build_firmware.ps1
|   |-- create_vivado_project.tcl
|   |-- firmware_to_mem.py
|   |-- run_simulation.tcl
|   `-- run_vivado_build.ps1
|-- sim/
|   `-- tb_riscv_password_lock.v
`-- src/
    |-- rtl/
    `-- vendor/picorv32/
```

## MMIO Map

| Address | Direction | Bits | Description |
|---|---|---|---|
| Hardware reset | Input | `btnC` | Reset the system, restore default password `1010`, clear unlock state, and reset remaining attempts to 3. |
| `0x80000000` | Read | `[0]` | `btnU` confirm |
| `0x80000000` | Read | `[4:1]` | `sw[3:0]` password input |
| `0x80000000` | Read | `[5]` | `btnD` change-password button |
| `0x80000004` | Write | `[3:0]` | LED status |
| `0x80000004` | Write | `[7:4]` | remaining attempts digit |
| `0x80000004` | Write | `[11:8]` | display mode, `0` = digit, `1` = `PASS` |

## Build Firmware

The generated firmware files are already included. To rebuild them:

```powershell
python scripts/assemble_firmware.py
```

Outputs:

- `firmware/final_project.bin`
- `firmware/final_project.hex`
- `firmware/final_project.mem`

## Create Vivado Project

In Vivado Tcl Console:

```tcl
source scripts/create_vivado_project.tcl
```

This creates:

```text
build/vivado_project/riscv_password_lock.xpr
```

## Run Simulation and Build Bitstream

On Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\run_vivado_build.ps1
```

The script runs the xsim testbench and then generates:

```text
build/bitstream/final_project.bit
```

The generated bitstream is also included at:

```text
bitstream/final_project.bit
```

The `build/` folder is intentionally ignored by Git because it contains generated Vivado logs and temporary outputs.

## Board Operation

1. Press `btnC` to reset. The seven-segment display shows `3`.
2. Enter the current 4-bit password with `sw[3:0]`. The default password is `1010`.
3. Press and release `btnU`.
4. Correct password: LED0-LED3 turn on and the seven-segment display shows `PASS`.
5. Wrong password: remaining attempts decrease from 3 to 2 to 1 to 0.
6. Three wrong attempts: the system locks, LED shows `1010`, and reset is required.
7. To change password: while `PASS` is displayed, set `sw[3:0]` to the new password, then press and release `btnD`.
8. The new password is runtime-only. Pressing `btnC` resets it back to `1010`.

## External Sources

- PicoRV32 by YosysHQ: <https://github.com/YosysHQ/picorv32>, ISC license.
- Basys 3 XDC pin mapping references Digilent digilent-xdc: <https://github.com/Digilent/digilent-xdc>.
