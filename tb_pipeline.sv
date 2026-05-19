// Self-checking testbench for core_pipeline.
//
// This test loads a directed program into instruction memory. The program
// exercises load-use stall insertion, EX/MEM and MEM/WB forwarding, store-data
// forwarding, and taken-branch flushing.

module tb_pipeline;
    localparam int TIMEOUT_CYCLES = 120;

    logic clk, rst_n;
    int   cycle;
    int   errors;
    bit   saw_load_use_stall;
    bit   saw_branch_flush;

    core_pipeline dut (.clk(clk), .rst_n(rst_n));

    ///////////////////////////////////////////////////////////////
    // Waveform aliases: keep key pipeline/debug signals visible at tb top level.
    logic [31:0] if_pc;
    logic [31:0] if_instr;
    logic [31:0] id_pc;
    logic [31:0] id_instr;
    logic [4:0]  id_rs1;
    logic [4:0]  id_rs2;
    logic [4:0]  id_rd;
    logic [31:0] ex_pc;
    logic [4:0]  ex_rs1;
    logic [4:0]  ex_rs2;
    logic [4:0]  ex_rd;
    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b;
    logic [31:0] ex_alu_y;
    logic        ex_branch_taken;
    logic [1:0]  hazard_forward_a_sel;
    logic [1:0]  hazard_forward_b_sel;
    logic        hazard_pc_stall;
    logic        hazard_if_id_stall;
    logic        hazard_if_id_flush;
    logic        hazard_id_ex_flush;
    logic        hazard_load_use_stall_event;
    logic        hazard_branch_flush_event;
    logic [4:0]  wb_rd;
    logic [31:0] wb_data;
    logic        wb_regwrite;
    logic [31:0] rf_x0;
    logic [31:0] rf_x1;
    logic [31:0] rf_x2;
    logic [31:0] rf_x3;
    logic [31:0] rf_x4;
    logic [31:0] rf_x5;
    logic [31:0] rf_x6;
    logic [31:0] rf_x7;
    logic [31:0] rf_x8;
    logic [31:0] rf_x9;
    logic [31:0] rf_x10;
    logic [31:0] rf_x11;
    logic [31:0] rf_x12;
    logic [31:0] rf_x13;
    logic [31:0] rf_x14;
    logic [31:0] rf_x15;
    logic [31:0] rf_x16;
    logic [31:0] rf_x17;
    logic [31:0] rf_x18;
    logic [31:0] rf_x19;
    logic [31:0] rf_x20;
    logic [31:0] rf_x21;
    logic [31:0] rf_x22;
    logic [31:0] rf_x23;
    logic [31:0] rf_x24;
    logic [31:0] rf_x25;
    logic [31:0] rf_x26;
    logic [31:0] rf_x27;
    logic [31:0] rf_x28;
    logic [31:0] rf_x29;
    logic [31:0] rf_x30;
    logic [31:0] rf_x31;
    logic [31:0] rf_x1_base_addr;
    logic [31:0] rf_x2_loaded_word;
    logic [31:0] rf_x3_load_use_result;
    logic [31:0] rf_x4_forwarded_addi_result;
    logic [31:0] rf_x5_forwarded_add_result;
    logic [31:0] rf_x6_should_stay_zero;
    logic [31:0] rf_x7_should_stay_zero;
    logic [31:0] rf_x8_pass_value;
    logic [31:0] dmem_pass_sentinel;

    assign if_pc                         = dut.pc;
    assign if_instr                      = dut.if_instr;
    assign id_pc                         = dut.if_id_pc;
    assign id_instr                      = dut.if_id_instr;
    assign id_rs1                        = dut.id_rs1;
    assign id_rs2                        = dut.id_rs2;
    assign id_rd                         = dut.id_rd;
    assign ex_pc                         = dut.id_ex_pc;
    assign ex_rs1                        = dut.id_ex_rs1;
    assign ex_rs2                        = dut.id_ex_rs2;
    assign ex_rd                         = dut.id_ex_rd;
    assign ex_alu_a                      = dut.ex_alu_a;
    assign ex_alu_b                      = dut.ex_alu_b;
    assign ex_alu_y                      = dut.ex_alu_y;
    assign ex_branch_taken               = dut.ex_branch_taken;
    assign hazard_forward_a_sel          = dut.forwardA;
    assign hazard_forward_b_sel          = dut.forwardB;
    assign hazard_pc_stall               = dut.pc_stall;
    assign hazard_if_id_stall            = dut.if_id_stall;
    assign hazard_if_id_flush            = dut.if_id_flush;
    assign hazard_id_ex_flush            = dut.id_ex_flush;
    assign hazard_load_use_stall_event   = dut.pc_stall && dut.if_id_stall && dut.id_ex_flush && !dut.if_id_flush;
    assign hazard_branch_flush_event     = dut.if_id_flush && dut.id_ex_flush && !dut.pc_stall;
    assign wb_rd                         = dut.wb_rd;
    assign wb_data                       = dut.wb_data;
    assign wb_regwrite                   = dut.wb_regwrite;
    assign rf_x0                         = 32'h0000_0000;
    assign rf_x1                         = dut.u_rf.regs[1];
    assign rf_x2                         = dut.u_rf.regs[2];
    assign rf_x3                         = dut.u_rf.regs[3];
    assign rf_x4                         = dut.u_rf.regs[4];
    assign rf_x5                         = dut.u_rf.regs[5];
    assign rf_x6                         = dut.u_rf.regs[6];
    assign rf_x7                         = dut.u_rf.regs[7];
    assign rf_x8                         = dut.u_rf.regs[8];
    assign rf_x9                         = dut.u_rf.regs[9];
    assign rf_x10                        = dut.u_rf.regs[10];
    assign rf_x11                        = dut.u_rf.regs[11];
    assign rf_x12                        = dut.u_rf.regs[12];
    assign rf_x13                        = dut.u_rf.regs[13];
    assign rf_x14                        = dut.u_rf.regs[14];
    assign rf_x15                        = dut.u_rf.regs[15];
    assign rf_x16                        = dut.u_rf.regs[16];
    assign rf_x17                        = dut.u_rf.regs[17];
    assign rf_x18                        = dut.u_rf.regs[18];
    assign rf_x19                        = dut.u_rf.regs[19];
    assign rf_x20                        = dut.u_rf.regs[20];
    assign rf_x21                        = dut.u_rf.regs[21];
    assign rf_x22                        = dut.u_rf.regs[22];
    assign rf_x23                        = dut.u_rf.regs[23];
    assign rf_x24                        = dut.u_rf.regs[24];
    assign rf_x25                        = dut.u_rf.regs[25];
    assign rf_x26                        = dut.u_rf.regs[26];
    assign rf_x27                        = dut.u_rf.regs[27];
    assign rf_x28                        = dut.u_rf.regs[28];
    assign rf_x29                        = dut.u_rf.regs[29];
    assign rf_x30                        = dut.u_rf.regs[30];
    assign rf_x31                        = dut.u_rf.regs[31];
    assign rf_x1_base_addr               = dut.u_rf.regs[1];
    assign rf_x2_loaded_word             = dut.u_rf.regs[2];
    assign rf_x3_load_use_result         = dut.u_rf.regs[3];
    assign rf_x4_forwarded_addi_result   = dut.u_rf.regs[4];
    assign rf_x5_forwarded_add_result    = dut.u_rf.regs[5];
    assign rf_x6_should_stay_zero        = dut.u_rf.regs[6];
    assign rf_x7_should_stay_zero        = dut.u_rf.regs[7];
    assign rf_x8_pass_value              = dut.u_rf.regs[8];
    assign dmem_pass_sentinel            = {dut.u_dmem.mem[3], dut.u_dmem.mem[2],
                                            dut.u_dmem.mem[1], dut.u_dmem.mem[0]};

    ///////////////////////////////////////////////////////////////

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

    function automatic [31:0] enc_r(
        input logic [6:0] funct7,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
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

    function automatic [31:0] addi(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm);
        addi = enc_i(imm, rs1, 3'b000, rd, 7'b0010011);
    endfunction

    function automatic [31:0] lw(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm);
        lw = enc_i(imm, rs1, 3'b010, rd, 7'b0000011);
    endfunction

    function automatic [31:0] sw(input logic [4:0] rs2, input logic [4:0] rs1, input logic [11:0] imm);
        sw = enc_s(imm, rs2, rs1, 3'b010, 7'b0100011);
    endfunction

    function automatic [31:0] add(input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2);
        add = enc_r(7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011);
    endfunction

    function automatic [31:0] beq(input logic [4:0] rs1, input logic [4:0] rs2, input logic [12:0] imm);
        beq = enc_b(imm, rs2, rs1, 3'b000, 7'b1100011);
    endfunction

    task automatic check32(input string name, input logic [31:0] got, input logic [31:0] exp);
        if (got !== exp) begin
            $display("[FAIL] %s: got %08h expected %08h", name, got, exp);
            errors++;
        end else begin
            $display("[ OK ] %s = %08h", name, got);
        end
    endtask

    task automatic check_seen(input string name, input bit seen);
        if (!seen) begin
            $display("[FAIL] did not observe %s", name);
            errors++;
        end else begin
            $display("[ OK ] observed %s", name);
        end
    endtask

    task automatic clear_memories;
        for (int i = 0; i < 1024; i++) begin
            dut.u_imem.mem[i] = 8'h00;
        end
        for (int i = 0; i < 1024; i++) begin
            dut.u_dmem.mem[i] = 8'h00;
        end
    endtask

    task automatic write_instr(input int word_index, input logic [31:0] instr);
        int byte_index;
        begin
            byte_index = word_index * 4;
            dut.u_imem.mem[byte_index + 0] = instr[7:0];
            dut.u_imem.mem[byte_index + 1] = instr[15:8];
            dut.u_imem.mem[byte_index + 2] = instr[23:16];
            dut.u_imem.mem[byte_index + 3] = instr[31:24];
        end
    endtask

    task automatic write_dword(input int word_index, input logic [31:0] data);
        int byte_index;
        begin
            byte_index = word_index * 4;
            dut.u_dmem.mem[byte_index + 0] = data[7:0];
            dut.u_dmem.mem[byte_index + 1] = data[15:8];
            dut.u_dmem.mem[byte_index + 2] = data[23:16];
            dut.u_dmem.mem[byte_index + 3] = data[31:24];
        end
    endtask

    task automatic load_directed_program;
        clear_memories();

        // Data word consumed by the load-use pair.
        write_dword(1, 32'd7);

        //  PC  Instruction              Purpose
        //   0  addi x1, x0, 4           x1 = address of dmem[1]
        //   4  lw   x2, 0(x1)           x2 = 7
        //   8  add  x3, x2, x2          immediate load consumer: must stall
        //  12  addi x4, x3, 1           consumes x3 via forwarding
        //  16  add  x5, x4, x3          mixed forwarding, x5 = 29
        //  20  beq  x5, x5, +12         taken branch, flush PC 24 and 28
        //  24  addi x6, x0, 99          must be flushed
        //  28  addi x7, x0, 99          must be flushed
        //  32  addi x8, x0, 1           PASS value
        //  36  sw   x8, 0(x0)           store-data forwarding -> dmem[0] = 1
        write_instr(0, addi(5'd1, 5'd0, 12'd4));
        write_instr(1, lw  (5'd2, 5'd1, 12'd0));
        write_instr(2, add (5'd3, 5'd2, 5'd2));
        write_instr(3, addi(5'd4, 5'd3, 12'd1));
        write_instr(4, add (5'd5, 5'd4, 5'd3));
        write_instr(5, beq (5'd5, 5'd5, 13'd12));
        write_instr(6, addi(5'd6, 5'd0, 12'd99));
        write_instr(7, addi(5'd7, 5'd0, 12'd99));
        write_instr(8, addi(5'd8, 5'd0, 12'd1));
        write_instr(9, sw  (5'd8, 5'd0, 12'd0));
    endtask

    task automatic reset_dut;
        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
    endtask

    initial begin
        errors = 0;
        cycle = 0;
        saw_load_use_stall = 1'b0;
        saw_branch_flush = 1'b0;

        load_directed_program();
        reset_dut();
    end

    initial begin
        $display("cyc | IF_PC   | ID_PC   | EX_PC   | stall | if_flush | id_flush | wb");
        $display("----+---------+---------+---------+-------+----------+----------+--------------");
    end

    always @(posedge clk) begin
        if (rst_n) begin
            cycle++;

            $display("%3d | %08h | %08h | %08h |   %0b   |    %0b     |    %0b     | x%0d=%08h we=%0b",
                cycle,
                if_pc,
                id_pc,
                ex_pc,
                hazard_pc_stall,
                hazard_if_id_flush,
                hazard_id_ex_flush,
                wb_rd,
                wb_data,
                wb_regwrite);

            if (hazard_load_use_stall_event) begin
                saw_load_use_stall = 1'b1;
                $display("      observed load-use stall");
            end

            if (hazard_branch_flush_event) begin
                saw_branch_flush = 1'b1;
                $display("      observed branch/jump flush");
            end
        end
    end

    initial begin
        wait (rst_n);

        while (cycle < TIMEOUT_CYCLES) begin
            @(posedge clk);
            #1;

            if (dmem_pass_sentinel == 32'hdead_beef) begin
                $display("[FAIL] dmem[0]=deadbeef at cycle %0d", cycle);
                errors++;
                break;
            end

            if (dmem_pass_sentinel == 32'h0000_0001) begin
                $display("\nProgram wrote PASS sentinel at cycle %0d", cycle);
                check_seen("load-use stall", saw_load_use_stall);
                check_seen("taken branch flush", saw_branch_flush);
                check32("x1 base address", rf_x1_base_addr, 32'd4);
                check32("x2 loaded word", rf_x2_loaded_word, 32'd7);
                check32("x3 load-use result", rf_x3_load_use_result, 32'd14);
                check32("x4 forwarded addi result", rf_x4_forwarded_addi_result, 32'd15);
                check32("x5 forwarded add result", rf_x5_forwarded_add_result, 32'd29);
                check32("x6 flushed instruction", rf_x6_should_stay_zero, 32'd0);
                check32("x7 flushed instruction", rf_x7_should_stay_zero, 32'd0);
                check32("x8 pass value", rf_x8_pass_value, 32'd1);
                check32("dmem[0] pass sentinel", dmem_pass_sentinel, 32'd1);

                if (errors == 0) begin
                    $display("\n[PASS] tb_pipeline completed with no errors");
                    $finish;
                end else begin
                    $display("\n[FAIL] tb_pipeline completed with %0d error(s)", errors);
                    $fatal(1);
                end
            end
        end

        $display("[TIMEOUT] %0d cycles elapsed", TIMEOUT_CYCLES);
        errors++;
        $fatal(1);
    end

    initial begin
        $dumpfile("tb_pipeline.vcd");
        $dumpvars(0, tb_pipeline);
    end
endmodule
