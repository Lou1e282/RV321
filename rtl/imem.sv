// Instruction memory (ROM) — loaded via $readmemh in testbench

module imem #(
  parameter int WORDS = 256
)(
  input  logic [31:0] addr,
  output logic [31:0] rdata
);
  logic [31:0] mem [0:WORDS-1];

  always_comb rdata = mem[addr[31:2]];  // word-addressed: drop byte-offset bits

endmodule
