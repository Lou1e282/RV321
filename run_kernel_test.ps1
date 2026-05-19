$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$OsDir = Join-Path $Root "os"
$ToolBin = Join-Path $env:APPDATA "xPacks\@xpack-dev-tools\riscv-none-elf-gcc\15.2.0-1.1\.content\bin"

function Run-Checked {
    param(
        [scriptblock] $Command,
        [string] $Name
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

$Gcc = Get-Command "riscv-none-elf-gcc" -ErrorAction SilentlyContinue
if (-not $Gcc) {
    $GccPath = Join-Path $ToolBin "riscv-none-elf-gcc.exe"
    if (Test-Path $GccPath) {
        $Gcc = $GccPath
    } else {
        throw "riscv-none-elf-gcc not found. Reopen PowerShell or add the xPack RISC-V GCC bin directory to PATH."
    }
}

$Objcopy = Get-Command "riscv-none-elf-objcopy" -ErrorAction SilentlyContinue
if (-not $Objcopy) {
    $ObjcopyPath = Join-Path $ToolBin "riscv-none-elf-objcopy.exe"
    if (Test-Path $ObjcopyPath) {
        $Objcopy = $ObjcopyPath
    } else {
        throw "riscv-none-elf-objcopy not found. Reopen PowerShell or add the xPack RISC-V GCC bin directory to PATH."
    }
}

Write-Host "[1/4] Building os/kernel.elf"
Push-Location $OsDir
Run-Checked {
    & $Gcc `
        -march=rv32i `
        -mabi=ilp32 `
        -nostdlib `
        -ffreestanding `
        -fno-builtin `
        -T linker.ld `
        boot.S kernel.c uart.c `
        -o kernel.elf
} "riscv-none-elf-gcc"

Write-Host "[2/4] Generating os/kernel.hex"
Run-Checked {
    & $Objcopy -O verilog kernel.elf kernel.hex
} "riscv-none-elf-objcopy"
Pop-Location

Write-Host "[3/4] Compiling RTL and tb_kernel"
Push-Location $Root
Run-Checked {
    vlog -sv `
        rtl\alu.sv `
        rtl\regfile.sv `
        rtl\imm_gen.sv `
        rtl\decoder.sv `
        rtl\dmem.sv `
        rtl\imem.sv `
        rtl\pipeline\hazard_unit.sv `
        rtl\pipeline\core_pipeline.sv `
        tb_kernel.sv
} "vlog"

Write-Host "[4/4] Running tb_kernel"
Run-Checked {
    vsim -c tb_kernel -do "run -all; quit"
} "vsim"
Pop-Location
