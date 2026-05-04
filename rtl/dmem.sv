// Data memory
// initial $readmemh("mem/dmem.mem", mem);

module dmem #(
  parameter int WORDS = 256
)(
  input  logic        clk,
  input  logic [3:0]  be,       // byte enables: replaces we; 4'b1111=sw, 4'b0011=sh, 4'b0001=sb
  input  logic        re,
  input  logic [31:0] addr,
  input  logic [31:0] wdata,
  output logic [31:0] rdata
);
  logic [31:0] mem [0:WORDS-1];

  // combinational read — always returns full word; core handles sign-ext / extraction
  always_comb begin
    if (re) rdata = mem[addr[31:2]];
    else    rdata = 32'h0;
  end

  // byte-lane write
  always_ff @(posedge clk) begin
    if (be[0]) mem[addr[31:2]][7:0]   <= wdata[7:0];
    if (be[1]) mem[addr[31:2]][15:8]  <= wdata[15:8];
    if (be[2]) mem[addr[31:2]][23:16] <= wdata[23:16];
    if (be[3]) mem[addr[31:2]][31:24] <= wdata[31:24];
  end
endmodule
