// Byte-addressed data memory with a simulation UART MMIO sink.

module dmem #(
  parameter int BYTES = 16 * 1024,
  parameter string MEMFILE = "os/kernel.hex",
  parameter logic [31:0] UART_ADDR = 32'h1000_0000
)(
  input  logic        clk,
  input  logic [3:0]  be,
  input  logic        re,
  input  logic [31:0] addr,
  input  logic [31:0] wdata,
  output logic [31:0] rdata
);
  logic [7:0] mem [0:BYTES-1];

  initial begin
    for (int i = 0; i < BYTES; i++) begin
      mem[i] = 8'h00;
    end
    $readmemh(MEMFILE, mem);
  end

  always_comb begin
    if (re && (addr + 32'd3 < BYTES)) begin
      rdata = {mem[{addr[31:2], 2'b00} + 32'd3],
               mem[{addr[31:2], 2'b00} + 32'd2],
               mem[{addr[31:2], 2'b00} + 32'd1],
               mem[{addr[31:2], 2'b00} + 32'd0]};
    end else begin
      rdata = 32'h0;
    end
  end

  always @(posedge clk) begin
    if (|be) begin
      if (addr == UART_ADDR) begin
`ifndef SYNTHESIS
        $write("%c", wdata[7:0]);
`endif
      end else if (addr < BYTES) begin
        unique case (be)
          4'b1111: begin
            if (addr + 32'd3 < BYTES) begin
              mem[addr + 32'd0] <= wdata[7:0];
              mem[addr + 32'd1] <= wdata[15:8];
              mem[addr + 32'd2] <= wdata[23:16];
              mem[addr + 32'd3] <= wdata[31:24];
            end
          end
          4'b0011, 4'b1100: begin
            if (addr + 32'd1 < BYTES) begin
              mem[addr + 32'd0] <= wdata[7:0];
              mem[addr + 32'd1] <= wdata[15:8];
            end
          end
          default: begin
            mem[addr] <= wdata[7:0];
          end
        endcase
      end
    end
  end
endmodule
