// Testbench for core_pipeline (5-stage)
// Pass/fail sentinel: dmem[0]==1 → PASS, dmem[0]==deadbeef → FAIL

module tb_pipeline;
    logic clk, rst_n;

    core_pipeline dut (.clk(clk), .rst_n(rst_n));

    initial clk = 0;
    always #5 clk = ~clk;

    // Reset for 5 cycles
    initial begin
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
    end

    // Load memories
    initial begin
        $readmemh("mem/imem.mem", dut.u_imem.mem);
        $readmemh("mem/dmem.mem", dut.u_dmem.mem);
    end

    // Monitor pipeline stage PCs each cycle
    initial begin
        $display("cyc | IF_PC   | ID_PC   | EX_PC   | stall | flush");
        $display("----+---------+---------+---------+-------+------");
    end

    always @(posedge clk) begin
        if (rst_n)
            $display("%3d | %08h | %08h | %08h |   %0b   |  %0b",
                $time/10,
                dut.pc,
                dut.if_id_pc,
                dut.id_ex_pc,
                dut.pc_stall,
                dut.if_id_flush);
    end

    // Pass/fail check
    initial begin
        int cyc = 0;
        wait (rst_n);
        while (cyc < 500) begin
            @(posedge clk);
            cyc++;

            if (dut.u_dmem.mem[0] == 32'h1) begin
                $display("[PASS] dmem[0]=1 at cycle %0d", cyc);
                $finish;
            end
            if (dut.u_dmem.mem[0] == 32'hdeadbeef) begin
                $display("[FAIL] dmem[0]=deadbeef at cycle %0d", cyc);
                $finish;
            end
        end
        $display("[TIMEOUT] 500 cycles elapsed");
        $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("tb_pipeline.vcd");
        $dumpvars(0, tb_pipeline);
    end
endmodule
