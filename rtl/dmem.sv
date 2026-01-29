// data memory
module dmem #(
  parameter int WORDS = 256
)(
  input  logic        clk,
  input  logic        we,
  input  logic        re,
  input  logic [31:0] addr,
  input  logic [31:0] wdata,
  output logic [31:0] rdata
);
  logic [31:0] mem [0:WORDS-1];

  // always read
  always_comb begin
    if (re) rdata = mem[addr[31:2]];
    else    rdata = 32'h0;
  end

  // synchronized write 
  always_ff @(posedge clk) begin
    if (we) mem[addr[31:2]] <= wdata;
  end
endmodule
