param(
    [string]$VivadoBat = "C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat"
)

$ErrorActionPreference = "Stop"
$Repo = Resolve-Path (Join-Path $PSScriptRoot "..")
$Work = Join-Path $env:LOCALAPPDATA "Temp\final_project_vivado_work"
New-Item -ItemType Directory -Force -Path $Work | Out-Null

$env:VIVADO_WORK_DIR = $Work
Push-Location $Repo
try {
    & "C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat" `
        src\vendor\picorv32\picorv32.v `
        src\rtl\instruction_memory.v `
        src\rtl\mmio_controller.v `
        src\rtl\seven_segment_decoder.v `
        src\rtl\riscv_password_lock_top.v `
        sim\tb_riscv_password_lock.v
    if ($LASTEXITCODE -ne 0) { throw "xvlog failed" }

    & "C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat" tb_riscv_password_lock -s tb_riscv_password_lock_snapshot
    if ($LASTEXITCODE -ne 0) { Write-Warning "xelab returned a cleanup error. Continuing because the snapshot is often still generated on OneDrive."; }

    & "C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat" tb_riscv_password_lock_snapshot -runall
    if ($LASTEXITCODE -ne 0) { throw "xsim failed" }

    & $VivadoBat -mode batch -source scripts\build_bitstream_nonproject.tcl -nojournal -log (Join-Path $Work "vivado_bitstream.log")
    if ($LASTEXITCODE -ne 0) { throw "Vivado bitstream generation failed. See $Work\vivado_bitstream.log" }

    Write-Host "Done. Bitstream: build\bitstream\final_project.bit"
}
finally {
    Pop-Location
}
