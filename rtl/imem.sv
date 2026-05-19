// Instruction memory ROM. Loads byte-formatted objcopy -O verilog output.

module imem #(
  parameter int BYTES = 16 * 1024,
  parameter string MEMFILE = "os/kernel.hex"
)(
  input  logic [31:0] addr,
  output logic [31:0] rdata
);
  logic [7:0] mem [0:BYTES-1];

  initial begin
    for (int i = 0; i < BYTES; i += 4) begin
      mem[i + 0] = 8'h13;
      mem[i + 1] = 8'h00;
      mem[i + 2] = 8'h00;
      mem[i + 3] = 8'h00;
    end
    $readmemh(MEMFILE, mem);
  end

  always_comb begin
    // RISC-V is little-endian; addr is a byte address.
    rdata = {mem[addr + 32'd3], mem[addr + 32'd2], mem[addr + 32'd1], mem[addr]};
  end

endmodule
