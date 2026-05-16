// Single-cycle RV32I core — golden reference for pipeline verification

module core_singlecycle (
    input logic clk,
    input logic rst_n
);

    // PC
    logic [31:0] pc, pc_next;

    // IF
    logic [31:0] instr;

    // Decode fields
    logic [4:0]  rs1, rs2, rd;
    logic [2:0]  funct3;
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];

    // Immediates
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

    // Regfile read values
    logic [31:0] rs1_val, rs2_val;

    // Control signals
    logic regwrite, memread, memwrite, memtoreg;
    logic alusrc, branch, jump, jalr, lui, auipc;
    logic [3:0] alu_ctrl;

    // ALU
    logic [31:0] alu_a, alu_b, alu_y;
    logic        alu_zero;

    // Memory and writeback
    logic [31:0] dmem_rdata, load_data, wb_data;
    logic [3:0]  dmem_be;

    // ── Instances ────────────────────────────────────────────────
    imem u_imem (
        .addr  (pc),
        .rdata (instr)
    );

    imm_gen u_imm (
        .instr (instr),
        .imm_i (imm_i), .imm_s (imm_s), .imm_b (imm_b),
        .imm_u (imm_u), .imm_j (imm_j)
    );

    decoder u_dec (
        .instr    (instr),
        .regwrite (regwrite),  .memread  (memread),
        .memwrite (memwrite),  .memtoreg (memtoreg),
        .alusrc   (alusrc),    .branch   (branch),
        .jump     (jump),      .jalr     (jalr),
        .lui      (lui),       .auipc    (auipc),
        .alu_ctrl (alu_ctrl)
    );

    regfile u_rf (
        .clk (clk),    .rst  (!rst_n),
        .we  (regwrite), .wa  (rd),   .wd  (wb_data),
        .ra1 (rs1),    .rd1 (rs1_val),
        .ra2 (rs2),    .rd2 (rs2_val)
    );

    alu u_alu (
        .a        (alu_a),
        .b        (alu_b),
        .alu_ctrl (alu_ctrl),
        .y        (alu_y),
        .zero     (alu_zero)
    );

    dmem u_dmem (
        .clk   (clk),
        .be    (dmem_be),
        .re    (memread),
        .addr  (alu_y),
        .wdata (rs2_val),
        .rdata (dmem_rdata)
    );

    // ── ALU operands ─────────────────────────────────────────────
    always_comb begin
        // A: 0 for LUI, PC for AUIPC, else rs1
        if      (lui)   alu_a = 32'h0;
        else if (auipc) alu_a = pc;
        else            alu_a = rs1_val;

        // B: imm_u for LUI/AUIPC, imm_s for stores, imm_i for I-type, else rs2
        if      (lui || auipc) alu_b = imm_u;
        else if (alusrc)       alu_b = memwrite ? imm_s : imm_i;
        else                   alu_b = rs2_val;
    end

    // ── Store byte enables ────────────────────────────────────────
    always_comb begin
        if (memwrite) begin
            case (funct3[1:0])
                2'b00:   dmem_be = 4'b0001 << alu_y[1:0];
                2'b01:   dmem_be = 4'b0011 << {alu_y[1], 1'b0};
                default: dmem_be = 4'b1111;
            endcase
        end else begin
            dmem_be = 4'b0000;
        end
    end

    // ── Load sign/zero extension ──────────────────────────────────
    always_comb begin
        case (funct3)
            3'b000:  load_data = {{24{dmem_rdata[7]}},  dmem_rdata[7:0]};
            3'b001:  load_data = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
            3'b010:  load_data = dmem_rdata;
            3'b100:  load_data = {24'h0, dmem_rdata[7:0]};
            3'b101:  load_data = {16'h0, dmem_rdata[15:0]};
            default: load_data = dmem_rdata;
        endcase
    end

    // ── Writeback mux ─────────────────────────────────────────────
    always_comb begin
        if      (jump)     wb_data = pc + 32'd4;  // JAL / JALR: link address
        else if (memtoreg) wb_data = load_data;
        else               wb_data = alu_y;
    end

    // ── Branch condition ──────────────────────────────────────────
    logic branch_taken;
    always_comb begin
        case (funct3)
            3'b000:  branch_taken = alu_zero;     // BEQ
            3'b001:  branch_taken = !alu_zero;    // BNE
            3'b100:  branch_taken = alu_y[0];     // BLT
            3'b101:  branch_taken = !alu_y[0];    // BGE
            3'b110:  branch_taken = alu_y[0];     // BLTU
            3'b111:  branch_taken = !alu_y[0];    // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

    // ── Next PC ───────────────────────────────────────────────────
    always_comb begin
        if      (jalr)                  pc_next = {alu_y[31:1], 1'b0};
        else if (jump)                  pc_next = pc + imm_j;
        else if (branch && branch_taken) pc_next = pc + imm_b;
        else                            pc_next = pc + 32'd4;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) pc <= 32'h0;
        else        pc <= pc_next;
    end

endmodule
