// Smoke/stress test for load-use stalls and forwarding using os/load_use_test.hex.

module tb_load_use;
    localparam int TIMEOUT_CYCLES = 120;

    logic clk;
    logic rst_n;
    int   cycle;
    int   errors;
    bit   verbose;
    logic [31:0] rf_x2;
    logic [31:0] rf_x3;
    logic [31:0] rf_x4;
    logic [31:0] rf_x5;
    logic [31:0] rf_x6;
    logic [31:0] dmem_65;

    core_pipeline #(
        .IMEM_FILE("os/load_use_test.hex"),
        .DMEM_FILE("os/load_use_test.hex")
    ) dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    assign rf_x2   = dut.u_rf.regs[2];
    assign rf_x3   = dut.u_rf.regs[3];
    assign rf_x4   = dut.u_rf.regs[4];
    assign rf_x5   = dut.u_rf.regs[5];
    assign rf_x6   = dut.u_rf.regs[6];
    assign dmem_65 = {dut.u_dmem.mem[263], dut.u_dmem.mem[262],
                      dut.u_dmem.mem[261], dut.u_dmem.mem[260]};

    task automatic check32(input string name, input logic [31:0] got, input logic [31:0] exp);
        if (got !== exp) begin
            $display("[FAIL] %s: got %08h expected %08h", name, got, exp);
            errors++;
        end else begin
            $display("[ OK ] %s = %08h", name, got);
        end
    endtask

    initial begin
        rst_n = 1'b0;
        cycle = 0;
        errors = 0;
        verbose = $test$plusargs("verbose");

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            cycle++;

            if (verbose) begin
                $display("cycle=%0d pc=%08h instr=%08h x2=%08h x3=%08h x4=%08h dmem[65]=%08h",
                    cycle,
                    dut.pc,
                    dut.if_instr,
                    rf_x2,
                    rf_x3,
                    rf_x4,
                    dmem_65);
            end

            if (dmem_65 == 32'd21) begin
                check32("x2 loaded value", rf_x2, 32'd7);
                check32("x3 load-use result", rf_x3, 32'd14);
                check32("x4 forwarded result", rf_x4, 32'd21);
                check32("x5 forwarded result", rf_x5, 32'd35);
                check32("x6 forwarded result", rf_x6, 32'd56);
                check32("dmem[65] pass sentinel", dmem_65, 32'd21);

                if (errors == 0) begin
                    $display("[PASS] load-use stress test completed");
                    $finish;
                end else begin
                    $display("[FAIL] load-use stress test completed with %0d error(s)", errors);
                    $fatal(1);
                end
            end

            if (cycle == TIMEOUT_CYCLES) begin
                $display("[FAIL] load-use stress test timed out");
                $fatal(1);
            end
        end
    end

    initial begin
        $dumpfile("tb_load_use.vcd");
        $dumpvars(0, clk);
        $dumpvars(0, rst_n);
        $dumpvars(0, cycle);
        $dumpvars(0, dut.pc);
        $dumpvars(0, dut.if_instr);
        $dumpvars(0, dut.pc_stall);
        $dumpvars(0, dut.if_id_stall);
        $dumpvars(0, dut.id_ex_flush);
        $dumpvars(0, dut.forwardA);
        $dumpvars(0, dut.forwardB);
        $dumpvars(0, rf_x2);
        $dumpvars(0, rf_x3);
        $dumpvars(0, rf_x4);
        $dumpvars(0, rf_x5);
        $dumpvars(0, rf_x6);
        $dumpvars(0, dmem_65);
    end
endmodule
