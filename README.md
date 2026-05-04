# RV321 — RV32I Pipelined Processor

A 5-stage pipelined RISC-V processor core written in SystemVerilog, implementing the full RV32I base integer instruction set.

## Architecture

```
IF → ID → EX → MEM → WB
```

| Stage | Function |
|-------|----------|
| IF | PC → instruction memory fetch |
| ID | Decode, register file read, immediate generation |
| EX | ALU execute, branch resolution, byte-enable generation |
| MEM | Data memory read/write, load sign/zero extension |
| WB | Writeback mux → register file |

## Supported Instructions

- **ALU**: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU (R-type and I-type immediate variants)
- **Memory**: LB, LH, LW, LBU, LHU, SB, SH, SW
- **Branch**: BEQ, BNE, BLT, BGE, BLTU, BGEU
- **Jump**: JAL, JALR
- **Upper immediate**: LUI, AUIPC

## Hazard Handling

- **Data forwarding**: EX→EX and MEM→EX paths for both ALU inputs
- **Load-use stall**: 1-cycle stall when a load result is needed by the immediately following instruction
- **Branch/jump flush**: predict not-taken; flush IF and ID stages on misprediction (2-cycle penalty)

## File Structure

```
rtl/
├── core_singlecycle.sv   # single-cycle reference core (WIP)
├── decoder.sv            # RV32I control signal decoder
├── alu.sv                # ALU (10 operations)
├── regfile.sv            # 32×32 register file with synchronous reset
├── imem.sv               # instruction memory (ROM)
├── dmem.sv               # data memory with byte-enable write
├── imm_gen.sv            # immediate generator (I/S/B/U/J types)
└── pipeline/
    ├── core_pipeline.sv  # 5-stage pipeline top
    └── hazard_unit.sv    # forwarding + stall/flush control

mem/
├── imem.mem              # instruction memory image (hex)
└── dmem.mem              # data memory image (hex)

tb_core.v                 # testbench for single-cycle core
tb_pipeline.sv            # testbench for pipeline core
```

## Simulation

Load memories and run in QuestaSim or any SystemVerilog simulator:

```tcl
vsim -do "
  vlog rtl/alu.sv rtl/regfile.sv rtl/imem.sv rtl/dmem.sv \
       rtl/imm_gen.sv rtl/decoder.sv \
       rtl/pipeline/hazard_unit.sv rtl/pipeline/core_pipeline.sv \
       tb_pipeline.sv
  vsim tb_pipeline
  run -all
"
```

Pass/fail is signaled via `dmem[0]`: `0x1` = PASS, `0xdeadbeef` = FAIL.
