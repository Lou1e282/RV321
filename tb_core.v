//// testbench for RTL core Jan 27. 2026 Vivado
//// RV32I instruction encoding. 


module tb_core;
  logic clk, rst_n;

  core_singlecycle dut(.clk(clk), .rst_n(rst_n));

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  // .mem added as Simulation Sources
  initial begin
    $readmemh("imem.mem", dut.u_imem.mem);
    $readmemh("dmem.mem", dut.u_dmem.mem);
  end

  initial begin
    int cyc = 0;
    wait(rst_n);
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
    $display("[TIMEOUT]");
    $finish;
  end
endmodule
