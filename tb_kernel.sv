// Smoke test for the compiled OS image in os/kernel.hex.

module tb_kernel;
    localparam int TIMEOUT_CYCLES = 500;
    localparam logic [31:0] UART_ADDR = 32'h1000_0000;

    logic clk;
    logic rst_n;
    int   cycle;
    int   uart_count;
    int   errors;
    bit   verbose;
    logic [7:0] expected [0:11];

    core_pipeline dut (.clk(clk), .rst_n(rst_n));

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        expected[0]  = "H";
        expected[1]  = "e";
        expected[2]  = "l";
        expected[3]  = "l";
        expected[4]  = "o";
        expected[5]  = " ";
        expected[6]  = "R";
        expected[7]  = "V";
        expected[8]  = "3";
        expected[9]  = "2";
        expected[10] = "I";
        expected[11] = 8'h0a;

        rst_n = 1'b0;
        cycle = 0;
        uart_count = 0;
        errors = 0;
        verbose = $test$plusargs("verbose");

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            cycle++;

            if (verbose) begin
                $display("cycle=%0d pc=%08h instr=%08h sp=%08h",
                    cycle,
                    dut.pc,
                    dut.if_instr,
                    dut.u_rf.regs[2]);
            end

            // how many 
            if (dut.ex_mem_memwrite && dut.ex_mem_alu_y == UART_ADDR) begin
                if (uart_count < 12) begin
                    if (dut.ex_mem_rs2_val[7:0] !== expected[uart_count]) begin
                        $display("[FAIL] uart[%0d]: got %02h expected %02h",
                            uart_count,
                            dut.ex_mem_rs2_val[7:0],
                            expected[uart_count]);
                        errors++;
                    end
                end else begin
                    $display("[FAIL] unexpected extra UART byte %02h", dut.ex_mem_rs2_val[7:0]);
                    errors++;
                end

                uart_count++;
            end

            if (uart_count == 12) begin
                if (errors == 0) begin
                    $display("");
                    $display("[PASS] kernel UART output matched: Hello RV32I\\n");
                    $finish;
                end else begin
                    $display("[FAIL] kernel UART output had %0d error(s)", errors);
                    $fatal(1);
                end
            end

            if (cycle == TIMEOUT_CYCLES) begin
                $display("[FAIL] kernel UART output timed out after %0d byte(s)", uart_count);
                $fatal(1);
            end
        end
    end

    initial begin
        $dumpfile("tb_kernel.vcd");
        $dumpvars(0, clk);
        $dumpvars(0, rst_n);
        $dumpvars(0, cycle);
        $dumpvars(0, uart_count);
        $dumpvars(0, dut.pc);
        $dumpvars(0, dut.if_instr);
        $dumpvars(0, dut.ex_mem_memwrite);
        $dumpvars(0, dut.ex_mem_alu_y);
        $dumpvars(0, dut.ex_mem_rs2_val);
    end
endmodule
