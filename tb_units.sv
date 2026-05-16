// Self-checking unit testbench for the RV32I building blocks.

module tb_units;
    int errors;

    logic [31:0] alu_a, alu_b, alu_y;
    logic [3:0]  alu_ctrl;
    logic        alu_zero;

    logic [31:0] instr;
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

    logic        dec_regwrite, dec_memread, dec_memwrite, dec_memtoreg;
    logic        dec_alusrc, dec_branch, dec_jump, dec_jalr, dec_lui, dec_auipc;
    logic [3:0]  dec_alu_ctrl;

    logic        clk, rst, rf_we;
    logic [4:0]  rf_ra1, rf_ra2, rf_wa;
    logic [31:0] rf_wd, rf_rd1, rf_rd2;

    logic [3:0]  dmem_be;
    logic        dmem_re;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;

    logic [4:0]  hz_id_ex_rs1, hz_id_ex_rs2, hz_ex_mem_rd, hz_mem_wb_rd;
    logic [4:0]  hz_id_ex_rd, hz_if_id_rs1, hz_if_id_rs2;
    logic        hz_ex_mem_regwrite, hz_mem_wb_regwrite, hz_id_ex_memread;
    logic        hz_branch_taken, hz_jal_id, hz_jalr_ex;
    logic [1:0]  hz_forwardA, hz_forwardB;
    logic        hz_pc_stall, hz_if_id_stall, hz_if_id_flush, hz_id_ex_flush;

    alu u_alu (
        .a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl),
        .y(alu_y), .zero(alu_zero)
    );

    imm_gen u_imm (
        .instr(instr),
        .imm_i(imm_i), .imm_s(imm_s), .imm_b(imm_b),
        .imm_u(imm_u), .imm_j(imm_j)
    );

    decoder u_dec (
        .instr(instr),
        .regwrite(dec_regwrite), .memread(dec_memread),
        .memwrite(dec_memwrite), .memtoreg(dec_memtoreg),
        .alusrc(dec_alusrc), .branch(dec_branch),
        .jump(dec_jump), .jalr(dec_jalr),
        .lui(dec_lui), .auipc(dec_auipc),
        .alu_ctrl(dec_alu_ctrl)
    );

    regfile u_rf (
        .clk(clk), .rst(rst), .we(rf_we),
        .ra1(rf_ra1), .ra2(rf_ra2), .wa(rf_wa), .wd(rf_wd),
        .rd1(rf_rd1), .rd2(rf_rd2)
    );

    dmem #(.WORDS(4)) u_dmem (
        .clk(clk), .be(dmem_be), .re(dmem_re),
        .addr(dmem_addr), .wdata(dmem_wdata), .rdata(dmem_rdata)
    );

    hazard_unit u_hazard (
        .id_ex_rs1(hz_id_ex_rs1), .id_ex_rs2(hz_id_ex_rs2),
        .ex_mem_rd(hz_ex_mem_rd), .ex_mem_regwrite(hz_ex_mem_regwrite),
        .mem_wb_rd(hz_mem_wb_rd), .mem_wb_regwrite(hz_mem_wb_regwrite),
        .id_ex_rd(hz_id_ex_rd), .id_ex_memread(hz_id_ex_memread),
        .if_id_rs1(hz_if_id_rs1), .if_id_rs2(hz_if_id_rs2),
        .branch_taken(hz_branch_taken), .jal_id(hz_jal_id), .jalr_ex(hz_jalr_ex),
        .forwardA(hz_forwardA), .forwardB(hz_forwardB),
        .pc_stall(hz_pc_stall), .if_id_stall(hz_if_id_stall),
        .if_id_flush(hz_if_id_flush), .id_ex_flush(hz_id_ex_flush)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    function automatic [31:0] enc_i(
        input logic [11:0] imm,
        input logic [4:0]  rs1,
        input logic [2:0]  funct3,
        input logic [4:0]  rd,
        input logic [6:0]  opcode
    );
        enc_i = {imm, rs1, funct3, rd, opcode};
    endfunction

    function automatic [31:0] enc_s(
        input logic [11:0] imm,
        input logic [4:0]  rs2,
        input logic [4:0]  rs1,
        input logic [2:0]  funct3,
        input logic [6:0]  opcode
    );
        enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction

    function automatic [31:0] enc_b(
        input logic [12:0] imm,
        input logic [4:0]  rs2,
        input logic [4:0]  rs1,
        input logic [2:0]  funct3,
        input logic [6:0]  opcode
    );
        enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction

    function automatic [31:0] enc_u(
        input logic [31:12] imm,
        input logic [4:0]   rd,
        input logic [6:0]   opcode
    );
        enc_u = {imm, rd, opcode};
    endfunction

    function automatic [31:0] enc_j(
        input logic [20:0] imm,
        input logic [4:0]  rd,
        input logic [6:0]  opcode
    );
        enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    task automatic check32(input string name, input logic [31:0] got, input logic [31:0] exp);
        if (got !== exp) begin
            $display("[FAIL] %s: got %08h expected %08h", name, got, exp);
            errors++;
        end else begin
            $display("[ OK ] %s", name);
        end
    endtask

    task automatic check1(input string name, input logic got, input logic exp);
        if (got !== exp) begin
            $display("[FAIL] %s: got %0b expected %0b", name, got, exp);
            errors++;
        end else begin
            $display("[ OK ] %s", name);
        end
    endtask

    task automatic check2(input string name, input logic [1:0] got, input logic [1:0] exp);
        if (got !== exp) begin
            $display("[FAIL] %s: got %0b expected %0b", name, got, exp);
            errors++;
        end else begin
            $display("[ OK ] %s", name);
        end
    endtask

    task automatic run_alu_tests;
        $display("\n-- ALU --");

        alu_a = 32'h0000_0007; alu_b = 32'h0000_0005; alu_ctrl = 4'b0000; #1;
        check32("ADD", alu_y, 32'h0000_000c);

        alu_ctrl = 4'b0001; #1;
        check32("SUB", alu_y, 32'h0000_0002);

        alu_a = 32'hf0f0_55aa; alu_b = 32'h0ff0_0f0f; alu_ctrl = 4'b0010; #1;
        check32("AND", alu_y, 32'h00f0_050a);

        alu_ctrl = 4'b0011; #1;
        check32("OR", alu_y, 32'hfff0_5faf);

        alu_ctrl = 4'b0100; #1;
        check32("XOR", alu_y, 32'hff00_5aa5);

        alu_a = 32'h0000_0001; alu_b = 32'h0000_0028; alu_ctrl = 4'b0101; #1;
        check32("SLL uses b[4:0]", alu_y, 32'h0000_0100);

        alu_a = 32'h8000_0000; alu_b = 32'h0000_0004; alu_ctrl = 4'b0110; #1;
        check32("SRL", alu_y, 32'h0800_0000);

        alu_ctrl = 4'b0111; #1;
        check32("SRA", alu_y, 32'hf800_0000);

        alu_a = 32'hffff_ffff; alu_b = 32'h0000_0001; alu_ctrl = 4'b1000; #1;
        check32("SLT signed", alu_y, 32'h0000_0001);

        alu_ctrl = 4'b1001; #1;
        check32("SLTU unsigned", alu_y, 32'h0000_0000);

        alu_a = 32'h1234_5678; alu_b = 32'h1234_5678; alu_ctrl = 4'b0001; #1;
        check1("zero flag", alu_zero, 1'b1);
    endtask

    task automatic run_imm_tests;
        $display("\n-- Immediate Generator --");

        instr = enc_i(12'hfff, 5'd6, 3'b000, 5'd5, 7'b0010011); #1;
        check32("I imm sign extend", imm_i, 32'hffff_ffff);

        instr = enc_s(12'hfe0, 5'd7, 5'd6, 3'b010, 7'b0100011); #1;
        check32("S imm sign extend", imm_s, 32'hffff_ffe0);

        instr = enc_b(13'h010, 5'd2, 5'd1, 3'b000, 7'b1100011); #1;
        check32("B imm positive", imm_b, 32'h0000_0010);

        instr = enc_b(13'h1ffc, 5'd2, 5'd1, 3'b000, 7'b1100011); #1;
        check32("B imm negative", imm_b, 32'hffff_fffc);

        instr = enc_u(20'habcde, 5'd3, 7'b0110111); #1;
        check32("U imm", imm_u, 32'habcde_000);

        instr = enc_j(21'h000800, 5'd1, 7'b1101111); #1;
        check32("J imm positive", imm_j, 32'h0000_0800);

        instr = enc_j(21'h1ff800, 5'd1, 7'b1101111); #1;
        check32("J imm negative", imm_j, 32'hffff_f800);
    endtask

    task automatic run_decoder_tests;
        $display("\n-- Decoder --");

        instr = enc_i(12'd1, 5'd2, 3'b000, 5'd3, 7'b0010011); #1;
        check1("ADDI regwrite", dec_regwrite, 1'b1);
        check1("ADDI alusrc", dec_alusrc, 1'b1);
        check32("ADDI alu_ctrl", {28'h0, dec_alu_ctrl}, 32'h0);

        instr = {7'b0100000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011}; #1;
        check32("SUB alu_ctrl", {28'h0, dec_alu_ctrl}, 32'h1);

        instr = enc_i(12'd0, 5'd1, 3'b010, 5'd3, 7'b0000011); #1;
        check1("LW memread", dec_memread, 1'b1);
        check1("LW memtoreg", dec_memtoreg, 1'b1);

        instr = enc_s(12'd4, 5'd3, 5'd1, 3'b010, 7'b0100011); #1;
        check1("SW memwrite", dec_memwrite, 1'b1);
        check1("SW regwrite clear", dec_regwrite, 1'b0);

        instr = enc_b(13'd8, 5'd2, 5'd1, 3'b100, 7'b1100011); #1;
        check1("BLT branch", dec_branch, 1'b1);
        check32("BLT alu_ctrl", {28'h0, dec_alu_ctrl}, 32'h8);

        instr = enc_i(12'd0, 5'd1, 3'b000, 5'd3, 7'b1100111); #1;
        check1("JALR jump", dec_jump, 1'b1);
        check1("JALR jalr", dec_jalr, 1'b1);

        instr = enc_u(20'h12345, 5'd3, 7'b0110111); #1;
        check1("LUI flag", dec_lui, 1'b1);

        instr = enc_u(20'h12345, 5'd3, 7'b0010111); #1;
        check1("AUIPC flag", dec_auipc, 1'b1);
    endtask

    task automatic run_regfile_tests;
        $display("\n-- Regfile --");

        rst = 1'b1; rf_we = 1'b0; rf_ra1 = 5'd5; rf_ra2 = 5'd0; rf_wa = 5'd0; rf_wd = 32'h0;
        @(posedge clk); #1;
        rst = 1'b0; #1;
        check32("reset clears x5", rf_rd1, 32'h0);
        check32("x0 reads zero", rf_rd2, 32'h0);

        rf_we = 1'b1; rf_wa = 5'd5; rf_wd = 32'hcafe_babe;
        @(posedge clk); #1;
        check32("write/read x5", rf_rd1, 32'hcafe_babe);

        rf_wa = 5'd0; rf_wd = 32'hffff_ffff; rf_ra2 = 5'd0;
        @(posedge clk); #1;
        check32("ignore writes to x0", rf_rd2, 32'h0);
    endtask

    task automatic run_dmem_tests;
        $display("\n-- Data Memory --");

        u_dmem.mem[0] = 32'h1122_3344;
        dmem_re = 1'b1; dmem_be = 4'b0000; dmem_addr = 32'h0; dmem_wdata = 32'h0; #1;
        check32("read enabled", dmem_rdata, 32'h1122_3344);

        dmem_re = 1'b0; #1;
        check32("read disabled returns zero", dmem_rdata, 32'h0);

        dmem_be = 4'b0100; dmem_addr = 32'h0; dmem_wdata = 32'h00aa_0000;
        @(posedge clk); #1;
        dmem_re = 1'b1; dmem_be = 4'b0000; #1;
        check32("byte write lane 2", dmem_rdata, 32'h11aa_3344);

        dmem_be = 4'b0011; dmem_addr = 32'h0; dmem_wdata = 32'h0000_beef;
        @(posedge clk); #1;
        dmem_be = 4'b0000; #1;
        check32("halfword write low lanes", dmem_rdata, 32'h11aa_beef);

        dmem_be = 4'b1111; dmem_addr = 32'h4; dmem_wdata = 32'hdead_beef;
        @(posedge clk); #1;
        dmem_be = 4'b0000; dmem_addr = 32'h4; #1;
        check32("word write", dmem_rdata, 32'hdead_beef);
    endtask

    task automatic clear_hazard_inputs;
        hz_id_ex_rs1 = 5'd0; hz_id_ex_rs2 = 5'd0;
        hz_ex_mem_rd = 5'd0; hz_mem_wb_rd = 5'd0;
        hz_ex_mem_regwrite = 1'b0; hz_mem_wb_regwrite = 1'b0;
        hz_id_ex_rd = 5'd0; hz_id_ex_memread = 1'b0;
        hz_if_id_rs1 = 5'd0; hz_if_id_rs2 = 5'd0;
        hz_branch_taken = 1'b0; hz_jal_id = 1'b0; hz_jalr_ex = 1'b0;
    endtask

    task automatic run_hazard_tests;
        $display("\n-- Hazard Unit --");

        clear_hazard_inputs();
        hz_id_ex_rs1 = 5'd3; hz_id_ex_rs2 = 5'd4;
        hz_ex_mem_rd = 5'd3; hz_ex_mem_regwrite = 1'b1;
        hz_mem_wb_rd = 5'd3; hz_mem_wb_regwrite = 1'b1; #1;
        check2("EX/MEM forwarding priority A", hz_forwardA, 2'b10);
        check2("no forwarding B", hz_forwardB, 2'b00);

        clear_hazard_inputs();
        hz_id_ex_rs2 = 5'd8; hz_mem_wb_rd = 5'd8; hz_mem_wb_regwrite = 1'b1; #1;
        check2("MEM/WB forwarding B", hz_forwardB, 2'b01);

        clear_hazard_inputs();
        hz_id_ex_rs1 = 5'd9; hz_ex_mem_rd = 5'd0; hz_ex_mem_regwrite = 1'b1; #1;
        check2("x0 does not forward", hz_forwardA, 2'b00);

        clear_hazard_inputs();
        hz_id_ex_rd = 5'd10; hz_id_ex_memread = 1'b1;
        hz_if_id_rs1 = 5'd10; hz_if_id_rs2 = 5'd11; #1;
        check1("load-use pc stall", hz_pc_stall, 1'b1);
        check1("load-use IF/ID stall", hz_if_id_stall, 1'b1);
        check1("load-use ID/EX flush", hz_id_ex_flush, 1'b1);

        hz_branch_taken = 1'b1; #1;
        check1("flush suppresses pc stall", hz_pc_stall, 1'b0);
        check1("branch flushes IF/ID", hz_if_id_flush, 1'b1);
        check1("branch flushes ID/EX", hz_id_ex_flush, 1'b1);

        // JAL resolved in ID: 1-cycle penalty — only IF/ID flushed, not ID/EX
        clear_hazard_inputs();
        hz_jal_id = 1'b1; #1;
        check1("JAL if_id_flush",  hz_if_id_flush,  1'b1);
        check1("JAL id_ex_flush no flush", hz_id_ex_flush, 1'b0);
        check1("JAL no pc stall",  hz_pc_stall,     1'b0);

        // JALR resolved in EX: 2-cycle penalty — both flushed
        clear_hazard_inputs();
        hz_jalr_ex = 1'b1; #1;
        check1("JALR if_id_flush", hz_if_id_flush,  1'b1);
        check1("JALR id_ex_flush", hz_id_ex_flush,  1'b1);
    endtask

    initial begin
        errors = 0;
        rst = 1'b0;
        rf_we = 1'b0;
        dmem_be = 4'b0000;
        dmem_re = 1'b0;
        clear_hazard_inputs();

        run_alu_tests();
        run_imm_tests();
        run_decoder_tests();
        run_regfile_tests();
        run_dmem_tests();
        run_hazard_tests();

        if (errors == 0) begin
            $display("\n[PASS] tb_units completed with no errors");
            $finish;
        end else begin
            $display("\n[FAIL] tb_units completed with %0d error(s)", errors);
            $fatal(1);
        end
    end
endmodule
