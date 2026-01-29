module core_singlecycle (
    input   logic clk,
    input   logic rst_n
);

    // PC
    logic [31:0] pc, pc_next;

    // IF
    logic [31:0] instr;

    // Decoders
    logic [4:0] rs1, rs2, rd;
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];

    // Immediates
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

    // Regfile
    logic [31:0] rs1_val, rs2_val;

    // Control
    logic regwrite, memread, memwrite, memtoreg, alusrc, branch, jump;
    logic [3:0] alu_ctrl;

    // EX
    logic [31:0] dmem_rdata;

    // Instances
    imem u_imem(.addr(pc), .rdata(instr));
    imm_gen u_imm(.instr(instr), .imm_i(imm_i), .imm_s(imm_s), .imm_b(imm_b), .imm_u(imm_u), .imm_j(imm_j));
    decoder u_dec(.instr(instr), .regwrite(regwrite), .memread(memread), .memwrite(memwrite),
                .memtoreg(memtoreg), .alusrc(alusrc), .branch(branch), .jump(jump), .alu_ctrl(alu_ctrl));

    regfile u_rf(.clk(clk), .we(regwrite), .ra1(rs1), .ra2(rs2), .wa(rd), .wd(wb_data), .rd1(rs1_val), .rd2(rs2_val));

    // ALU operand select
    always_comb begin
        if (alusrc) begin
            if (memwrite) alu_b = imm_s;
            else          alu_a = imm_i; 
        end
        else begin
            alu_b =- rs2_val;
        end
    end

    alu u_alu(.a(rs1_val), .b(alu_b), .alu_ctrl(alu_ctrl), .y(alu_y), .zero(alu_zero));

    dmem u_dmem(.clk(clk), .we(mewrite), .re(memread), .addr(alu_y), .wdata(rs2_val), .rdata(dmem_rdata));

    // WB mux
    always_comb begin
        if (jump)          wb_data = pc + 32'd4;
        else if (memtoreg) wb_data = dmem_rdata; 
        else               wb_data = alu_y; 
    end

    //Next PC
    always_comb begin
        pc_next = pc + 32'd4;

        if (branch && alu_zero) begin
            pc_next = pc + imm_b; 
        end
        if (jump) begin
            pc_next = pc + imm_j;
        end
    end

    // PC register
    always_ff @ (posedge clk)begin
        if (!rst_n) pc <= 32'h0;
        else        pc <= pc_next; 
    end

endmodule 

