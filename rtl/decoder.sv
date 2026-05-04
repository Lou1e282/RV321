// RV32I decoder — standard opcodes

module decoder (
    input  logic [31:0] instr,
    output logic        regwrite,
    output logic        memread,
    output logic        memwrite,
    output logic        memtoreg,
    output logic        alusrc,
    output logic        branch,
    output logic        jump,
    output logic        jalr,   // set alongside jump for JALR; pipeline uses alu_y as target
    output logic        lui,    // rd = imm_u (ALU A forced to 0 in pipeline)
    output logic        auipc,  // rd = PC + imm_u (ALU A forced to PC in pipeline)
    output logic [3:0]  alu_ctrl
);
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    always_comb begin
        // defaults — NOP
        regwrite = 0; memread  = 0; memwrite = 0; memtoreg = 0;
        alusrc   = 0; branch   = 0; jump     = 0; jalr     = 0;
        lui      = 0; auipc    = 0; alu_ctrl = 4'b0000;

        case (opcode)
            // ── OP-IMM (I-type) ─────────────────────────────────────────
            7'b0010011: begin
                regwrite = 1; alusrc = 1;
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000;                         // ADDI
                    3'b001: alu_ctrl = 4'b0101;                         // SLLI
                    3'b010: alu_ctrl = 4'b1000;                         // SLTI
                    3'b011: alu_ctrl = 4'b1001;                         // SLTIU
                    3'b100: alu_ctrl = 4'b0100;                         // XORI
                    3'b101: alu_ctrl = funct7[5] ? 4'b0111 : 4'b0110;  // SRAI/SRLI
                    3'b110: alu_ctrl = 4'b0011;                         // ORI
                    3'b111: alu_ctrl = 4'b0010;                         // ANDI
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            // ── OP (R-type) ──────────────────────────────────────────────
            7'b0110011: begin
                regwrite = 1;
                case (funct3)
                    3'b000: alu_ctrl = funct7[5] ? 4'b0001 : 4'b0000;  // SUB/ADD
                    3'b001: alu_ctrl = 4'b0101;                         // SLL
                    3'b010: alu_ctrl = 4'b1000;                         // SLT
                    3'b011: alu_ctrl = 4'b1001;                         // SLTU
                    3'b100: alu_ctrl = 4'b0100;                         // XOR
                    3'b101: alu_ctrl = funct7[5] ? 4'b0111 : 4'b0110;  // SRA/SRL
                    3'b110: alu_ctrl = 4'b0011;                         // OR
                    3'b111: alu_ctrl = 4'b0010;                         // AND
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            // ── LOAD (I-type) ────────────────────────────────────────────
            7'b0000011: begin
                regwrite = 1; memread = 1; memtoreg = 1;
                alusrc = 1; alu_ctrl = 4'b0000;  // addr = rs1 + imm_i
            end

            // ── STORE (S-type) ───────────────────────────────────────────
            7'b0100011: begin
                memwrite = 1; alusrc = 1; alu_ctrl = 4'b0000;  // addr = rs1 + imm_s
            end

            // ── BRANCH (B-type) ──────────────────────────────────────────
            7'b1100011: begin
                branch = 1;
                case (funct3)
                    3'b000, 3'b001: alu_ctrl = 4'b0001;  // BEQ/BNE:  SUB → check zero
                    3'b100, 3'b101: alu_ctrl = 4'b1000;  // BLT/BGE:  SLT → check y[0]
                    3'b110, 3'b111: alu_ctrl = 4'b1001;  // BLTU/BGEU: SLTU → check y[0]
                    default:        alu_ctrl = 4'b0001;
                endcase
            end

            // ── JAL (J-type) ─────────────────────────────────────────────
            7'b1101111: begin
                jump = 1; regwrite = 1;  // target = PC + imm_j (computed in pipeline)
            end

            // ── JALR (I-type) ────────────────────────────────────────────
            7'b1100111: begin
                jump = 1; jalr = 1; regwrite = 1;
                alusrc = 1; alu_ctrl = 4'b0000;  // target = (rs1 + imm_i) & ~1
            end

            // ── LUI (U-type) ─────────────────────────────────────────────
            7'b0110111: begin
                regwrite = 1; lui = 1;  // rd = imm_u (ALU: 0 + imm_u)
            end

            // ── AUIPC (U-type) ───────────────────────────────────────────
            7'b0010111: begin
                regwrite = 1; auipc = 1;  // rd = PC + imm_u
            end

            default: begin end  // NOP
        endcase
    end
endmodule
