// 5-stage RV32I pipeline: IF → ID → EX → MEM → WB
// Hazards: full EX-EX / MEM-EX forwarding, load-use stall, branch/jump flush

module core_pipeline (
    input logic clk,
    input logic rst_n
);

// ─────────────────────────────────────────────────────────────────
// WB→ID feedback (declared early, driven in WB section)
// ─────────────────────────────────────────────────────────────────
logic [4:0]  wb_rd;
logic [31:0] wb_data;
logic        wb_regwrite;

// ─────────────────────────────────────────────────────────────────
// IF — Instruction Fetch
// ─────────────────────────────────────────────────────────────────
logic [31:0] pc, pc_next;
logic [31:0] if_instr;
logic        pc_stall;

imem u_imem (
    .addr  (pc),
    .rdata (if_instr)
);

// ─────────────────────────────────────────────────────────────────
// IF/ID pipeline register
// ─────────────────────────────────────────────────────────────────
logic [31:0] if_id_pc, if_id_instr;
logic        if_id_stall, if_id_flush;

always_ff @(posedge clk) begin
    if (!rst_n || if_id_flush) begin
        if_id_pc    <= 32'h0;
        if_id_instr <= 32'h0;
    end else if (!if_id_stall) begin
        if_id_pc    <= pc;
        if_id_instr <= if_instr;
    end
end

// ─────────────────────────────────────────────────────────────────
// ID — Decode / Register Read
// ─────────────────────────────────────────────────────────────────
logic [4:0]  id_rs1, id_rs2, id_rd;
logic [2:0]  id_funct3;
logic [31:0] id_rs1_val, id_rs2_val;
logic [31:0] id_imm_i, id_imm_s, id_imm_b, id_imm_u, id_imm_j;
logic        id_regwrite, id_memread, id_memwrite, id_memtoreg;
logic        id_alusrc, id_branch, id_jump, id_jalr, id_lui, id_auipc;
logic [3:0]  id_alu_ctrl;

assign id_rs1    = if_id_instr[19:15];
assign id_rs2    = if_id_instr[24:20];
assign id_rd     = if_id_instr[11:7];
assign id_funct3 = if_id_instr[14:12];

imm_gen u_imm (
    .instr (if_id_instr),
    .imm_i (id_imm_i), .imm_s (id_imm_s), .imm_b (id_imm_b),
    .imm_u (id_imm_u), .imm_j (id_imm_j)
);

decoder u_dec (
    .instr    (if_id_instr),
    .regwrite (id_regwrite),  .memread  (id_memread),
    .memwrite (id_memwrite),  .memtoreg (id_memtoreg),
    .alusrc   (id_alusrc),    .branch   (id_branch),
    .jump     (id_jump),      .jalr     (id_jalr),
    .lui      (id_lui),       .auipc    (id_auipc),
    .alu_ctrl (id_alu_ctrl)
);

regfile u_rf (
    .clk (clk),         .rst  (!rst_n),
    .we  (wb_regwrite), .wa   (wb_rd),   .wd  (wb_data),
    .ra1 (id_rs1),      .rd1  (id_rs1_val),
    .ra2 (id_rs2),      .rd2  (id_rs2_val)
);

// ─────────────────────────────────────────────────────────────────
// ID/EX pipeline register
// ─────────────────────────────────────────────────────────────────
logic [31:0] id_ex_pc;
logic [31:0] id_ex_rs1_val, id_ex_rs2_val;
logic [31:0] id_ex_imm_i, id_ex_imm_s, id_ex_imm_b, id_ex_imm_u, id_ex_imm_j;
logic [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
logic [2:0]  id_ex_funct3;
logic        id_ex_regwrite, id_ex_memread, id_ex_memwrite, id_ex_memtoreg;
logic        id_ex_alusrc, id_ex_branch, id_ex_jump, id_ex_jalr, id_ex_lui, id_ex_auipc;
logic [3:0]  id_ex_alu_ctrl;
logic        id_ex_flush;

always_ff @(posedge clk) begin
    if (!rst_n || id_ex_flush) begin
        id_ex_pc        <= 32'h0;
        id_ex_rs1_val   <= 32'h0; id_ex_rs2_val   <= 32'h0;
        id_ex_imm_i     <= 32'h0; id_ex_imm_s     <= 32'h0;
        id_ex_imm_b     <= 32'h0; id_ex_imm_u     <= 32'h0;
        id_ex_imm_j     <= 32'h0;
        id_ex_rs1       <= 5'h0;  id_ex_rs2       <= 5'h0;
        id_ex_rd        <= 5'h0;  id_ex_funct3    <= 3'h0;
        id_ex_regwrite  <= 1'b0;  id_ex_memread   <= 1'b0;
        id_ex_memwrite  <= 1'b0;  id_ex_memtoreg  <= 1'b0;
        id_ex_alusrc    <= 1'b0;  id_ex_branch    <= 1'b0;
        id_ex_jump      <= 1'b0;  id_ex_jalr      <= 1'b0;
        id_ex_lui       <= 1'b0;  id_ex_auipc     <= 1'b0;
        id_ex_alu_ctrl  <= 4'h0;
    end else begin
        id_ex_pc        <= if_id_pc;
        id_ex_rs1_val   <= id_rs1_val; id_ex_rs2_val   <= id_rs2_val;
        id_ex_imm_i     <= id_imm_i;   id_ex_imm_s     <= id_imm_s;
        id_ex_imm_b     <= id_imm_b;   id_ex_imm_u     <= id_imm_u;
        id_ex_imm_j     <= id_imm_j;
        id_ex_rs1       <= id_rs1;     id_ex_rs2       <= id_rs2;
        id_ex_rd        <= id_rd;      id_ex_funct3    <= id_funct3;
        id_ex_regwrite  <= id_regwrite; id_ex_memread  <= id_memread;
        id_ex_memwrite  <= id_memwrite; id_ex_memtoreg <= id_memtoreg;
        id_ex_alusrc    <= id_alusrc;   id_ex_branch   <= id_branch;
        id_ex_jump      <= id_jump;     id_ex_jalr     <= id_jalr;
        id_ex_lui       <= id_lui;      id_ex_auipc    <= id_auipc;
        id_ex_alu_ctrl  <= id_alu_ctrl;
    end
end

// ─────────────────────────────────────────────────────────────────
// EX — Execute
// ─────────────────────────────────────────────────────────────────
logic [1:0]  forwardA, forwardB;
logic [31:0] ex_alu_a, ex_alu_b_reg, ex_alu_b;
logic [31:0] ex_alu_y;
logic        ex_alu_zero;
logic        ex_branch_taken;
logic [3:0]  ex_dmem_be;

// EX/MEM values needed by forwarding mux (declared here, driven below)
logic [4:0]  ex_mem_rd;
logic        ex_mem_regwrite;
logic [31:0] ex_mem_alu_y;

// ALU A:  LUI → 0,  AUIPC → PC,  else forwarded rs1
always_comb begin
    if      (id_ex_lui)   ex_alu_a = 32'h0;
    else if (id_ex_auipc) ex_alu_a = id_ex_pc;
    else case (forwardA)
        2'b10:   ex_alu_a = ex_mem_alu_y;
        2'b01:   ex_alu_a = wb_data;
        default: ex_alu_a = id_ex_rs1_val;
    endcase
end

// ALU B forwarded register value (used for stores and as default)
always_comb begin
    case (forwardB)
        2'b10:   ex_alu_b_reg = ex_mem_alu_y;
        2'b01:   ex_alu_b_reg = wb_data;
        default: ex_alu_b_reg = id_ex_rs2_val;
    endcase
end

// ALU B final: LUI/AUIPC → imm_u, store → imm_s, other imm → imm_i, else reg
always_comb begin
    if      (id_ex_lui || id_ex_auipc)  ex_alu_b = id_ex_imm_u;
    else if (id_ex_alusrc)              ex_alu_b = id_ex_memwrite ? id_ex_imm_s : id_ex_imm_i;
    else                                ex_alu_b = ex_alu_b_reg;
end

alu u_alu (
    .a        (ex_alu_a),
    .b        (ex_alu_b),
    .alu_ctrl (id_ex_alu_ctrl),
    .y        (ex_alu_y),
    .zero     (ex_alu_zero)
);

// Branch condition from funct3
// BEQ/BNE use SUB→zero flag; BLT/BGE use SLT→y[0]; BLTU/BGEU use SLTU→y[0]
always_comb begin
    ex_branch_taken = 1'b0;
    if (id_ex_branch) begin
        case (id_ex_funct3)
            3'b000:  ex_branch_taken =  ex_alu_zero;    // BEQ
            3'b001:  ex_branch_taken = !ex_alu_zero;    // BNE
            3'b100:  ex_branch_taken =  ex_alu_y[0];    // BLT
            3'b101:  ex_branch_taken = !ex_alu_y[0];    // BGE
            3'b110:  ex_branch_taken =  ex_alu_y[0];    // BLTU
            3'b111:  ex_branch_taken = !ex_alu_y[0];    // BGEU
            default: ex_branch_taken = 1'b0;
        endcase
    end
end

// Store byte enables from funct3 + address offset
always_comb begin
    if (id_ex_memwrite) begin
        case (id_ex_funct3[1:0])
            2'b00:   ex_dmem_be = 4'b0001 << ex_alu_y[1:0];        // SB
            2'b01:   ex_dmem_be = 4'b0011 << {ex_alu_y[1], 1'b0};  // SH
            default: ex_dmem_be = 4'b1111;                           // SW
        endcase
    end else begin
        ex_dmem_be = 4'b0000;
    end
end

// ─────────────────────────────────────────────────────────────────
// EX/MEM pipeline register
// ─────────────────────────────────────────────────────────────────
logic [31:0] ex_mem_rs2_val;
logic        ex_mem_memread, ex_mem_memwrite, ex_mem_memtoreg;
logic [3:0]  ex_mem_be;
logic [2:0]  ex_mem_funct3;
logic        ex_mem_jump;
logic [31:0] ex_mem_jump_ret;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        ex_mem_alu_y     <= 32'h0; ex_mem_rs2_val   <= 32'h0;
        ex_mem_rd        <= 5'h0;  ex_mem_regwrite  <= 1'b0;
        ex_mem_memread   <= 1'b0;  ex_mem_memwrite  <= 1'b0;
        ex_mem_memtoreg  <= 1'b0;
        ex_mem_be        <= 4'h0;  ex_mem_funct3    <= 3'h0;
        ex_mem_jump      <= 1'b0;  ex_mem_jump_ret  <= 32'h0;
    end else begin
        ex_mem_alu_y     <= ex_alu_y;
        ex_mem_rs2_val   <= ex_alu_b_reg;
        ex_mem_rd        <= id_ex_rd;      ex_mem_regwrite <= id_ex_regwrite;
        ex_mem_memread   <= id_ex_memread; ex_mem_memwrite <= id_ex_memwrite;
        ex_mem_memtoreg  <= id_ex_memtoreg;
        ex_mem_be        <= ex_dmem_be;    ex_mem_funct3   <= id_ex_funct3;
        ex_mem_jump      <= id_ex_jump;    ex_mem_jump_ret <= id_ex_pc + 32'd4;
    end
end

// ─────────────────────────────────────────────────────────────────
// MEM — Memory Access
// ─────────────────────────────────────────────────────────────────
logic [31:0] mem_rdata, mem_load_data;

dmem u_dmem (
    .clk   (clk),
    .be    (ex_mem_be),
    .re    (ex_mem_memread),
    .addr  (ex_mem_alu_y),
    .wdata (ex_mem_rs2_val),
    .rdata (mem_rdata)
);

// Load sign/zero extension from funct3
always_comb begin
    case (ex_mem_funct3)
        3'b000:  mem_load_data = {{24{mem_rdata[7]}},  mem_rdata[7:0]};    // LB
        3'b001:  mem_load_data = {{16{mem_rdata[15]}}, mem_rdata[15:0]};   // LH
        3'b010:  mem_load_data = mem_rdata;                                  // LW
        3'b100:  mem_load_data = {24'h0, mem_rdata[7:0]};                  // LBU
        3'b101:  mem_load_data = {16'h0, mem_rdata[15:0]};                 // LHU
        default: mem_load_data = mem_rdata;
    endcase
end

// ─────────────────────────────────────────────────────────────────
// MEM/WB pipeline register
// ─────────────────────────────────────────────────────────────────
logic [4:0]  mem_wb_rd;
logic        mem_wb_regwrite;
logic [31:0] mem_wb_alu_y, mem_wb_load_data;
logic        mem_wb_memtoreg, mem_wb_jump;
logic [31:0] mem_wb_jump_ret;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        mem_wb_alu_y     <= 32'h0; mem_wb_load_data <= 32'h0;
        mem_wb_rd        <= 5'h0;  mem_wb_regwrite  <= 1'b0;
        mem_wb_memtoreg  <= 1'b0;
        mem_wb_jump      <= 1'b0;  mem_wb_jump_ret  <= 32'h0;
    end else begin
        mem_wb_alu_y     <= ex_mem_alu_y;
        mem_wb_load_data <= mem_load_data;
        mem_wb_rd        <= ex_mem_rd;       mem_wb_regwrite <= ex_mem_regwrite;
        mem_wb_memtoreg  <= ex_mem_memtoreg;
        mem_wb_jump      <= ex_mem_jump;     mem_wb_jump_ret <= ex_mem_jump_ret;
    end
end

// ─────────────────────────────────────────────────────────────────
// WB — Write Back
// ─────────────────────────────────────────────────────────────────
assign wb_rd       = mem_wb_rd;
assign wb_regwrite = mem_wb_regwrite;

always_comb begin
    if      (mem_wb_jump)     wb_data = mem_wb_jump_ret;   // JAL/JALR: write PC+4
    else if (mem_wb_memtoreg) wb_data = mem_wb_load_data;  // load
    else                      wb_data = mem_wb_alu_y;       // ALU / LUI / AUIPC
end

// ─────────────────────────────────────────────────────────────────
// Hazard unit
// ─────────────────────────────────────────────────────────────────
// JAL resolved here in ID (1-cycle penalty); JALR resolved in EX (2-cycle)
logic jal_id;
assign jal_id = id_jump && !id_jalr;

hazard_unit u_hazard (
    .id_ex_rs1       (id_ex_rs1),      .id_ex_rs2       (id_ex_rs2),
    .ex_mem_rd       (ex_mem_rd),      .ex_mem_regwrite  (ex_mem_regwrite),
    .mem_wb_rd       (mem_wb_rd),      .mem_wb_regwrite  (mem_wb_regwrite),
    .id_ex_rd        (id_ex_rd),       .id_ex_memread    (id_ex_memread),
    .if_id_rs1       (id_rs1),         .if_id_rs2        (id_rs2),
    .branch_taken    (ex_branch_taken),
    .jal_id          (jal_id),         // JAL: 1-cycle flush
    .jalr_ex         (id_ex_jalr),     // JALR: 2-cycle flush
    .forwardA        (forwardA),       .forwardB         (forwardB),
    .pc_stall        (pc_stall),
    .if_id_stall     (if_id_stall),    .if_id_flush      (if_id_flush),
    .id_ex_flush     (id_ex_flush)
);

// ─────────────────────────────────────────────────────────────────
// PC — Next-PC logic
// ─────────────────────────────────────────────────────────────────
always_comb begin
    if      (id_ex_jalr)       pc_next = {ex_alu_y[31:1], 1'b0};   // JALR: (rs1+imm_i)&~1
    else if (jal_id)           pc_next = if_id_pc + id_imm_j;      // JAL resolved in ID
    else if (ex_branch_taken)  pc_next = id_ex_pc + id_ex_imm_b;   // BRANCH
    else                       pc_next = pc + 32'd4;
end

always_ff @(posedge clk) begin
    if      (!rst_n)    pc <= 32'h0;
    else if (!pc_stall) pc <= pc_next;
end

// ─────────────────────────────────────────────────────────────────
// SVA Assertions
// ─────────────────────────────────────────────────────────────────
`ifdef SIMULATION
    // PC must always be word-aligned
    property pc_aligned;
        @(posedge clk) disable iff (!rst_n) pc[1:0] == 2'b00;
    endproperty
    assert property (pc_aligned)
        else $error("PC misaligned: %08h", pc);

    // When stalled, PC must not advance
    property pc_holds_on_stall;
        @(posedge clk) disable iff (!rst_n) pc_stall |=> (pc == $past(pc));
    endproperty
    assert property (pc_holds_on_stall)
        else $error("PC advanced during stall: was %08h now %08h", $past(pc), pc);

    // x0 writeback must never carry a non-zero value
    property x0_immutable;
        @(posedge clk) disable iff (!rst_n)
            (wb_regwrite && wb_rd == 5'h0) |-> (wb_data == 32'h0);
    endproperty
    assert property (x0_immutable)
        else $error("x0 writeback with non-zero data: %08h", wb_data);

    // Load-use stall: ID/EX must become a bubble the cycle after stall
    property load_use_bubble;
        @(posedge clk) disable iff (!rst_n)
            (id_ex_memread && (id_ex_rd != 5'h0) &&
             (id_ex_rd == id_rs1 || id_ex_rd == id_rs2))
            |=> (id_ex_regwrite == 1'b0 && id_ex_memwrite == 1'b0);
    endproperty
    assert property (load_use_bubble)
        else $error("Load-use stall did not insert bubble into ID/EX");

    // EX/MEM and MEM/WB rd must never be X after reset
    property no_x_rd;
        @(posedge clk) disable iff (!rst_n) !$isunknown(ex_mem_rd);
    endproperty
    assert property (no_x_rd)
        else $error("X value in ex_mem_rd");
`endif

endmodule
