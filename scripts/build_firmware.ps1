param(
    [string]$Prefix = "riscv64-unknown-elf-"
)

$ErrorActionPreference = "Stop"
$Repo = Resolve-Path (Join-Path $PSScriptRoot "..")
$Asm = Join-Path $Repo "firmware\final_project.s"
$Elf = Join-Path $Repo "build\final_project.elf"
$Bin = Join-Path $Repo "firmware\final_project.bin"

New-Item -ItemType Directory -Force -Path (Join-Path $Repo "build") | Out-Null
& "$Prefix`as" -march=rv32i -mabi=ilp32 -o (Join-Path $Repo "build\final_project.o") $Asm
& "$Prefix`ld" -Ttext=0x0 -o $Elf (Join-Path $Repo "build\final_project.o")
& "$Prefix`objcopy" -O binary $Elf $Bin
& "python" (Join-Path $Repo "scripts\firmware_to_mem.py") $Bin --hex (Join-Path $Repo "firmware\final_project.hex") --mem (Join-Path $Repo "firmware\final_project.mem")
