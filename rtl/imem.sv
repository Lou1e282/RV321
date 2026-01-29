//// Input memory

module imem #(
  parameter int WORDS = 256
)(
  input  logic [31:0] addr,
  output logic [31:0] rdata
);
  logic [31:0] mem [0:WORDS-1];

  // word-addressed (pc[31:2]) factor of 4
  always_comb begin
    rdata = mem[addr[31:2]];
  end
endmodule
