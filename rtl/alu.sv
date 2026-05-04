// ALU
// alu_ctrl encoding:
// 0000 ADD   0001 SUB   0010 AND   0011 OR    0100 XOR
// 0101 SLL   0110 SRL   0111 SRA   1000 SLT   1001 SLTU

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_ctrl,
    output logic [31:0] y,
    output logic        zero
);

always_comb begin
    case (alu_ctrl)
        4'b0000: y = a + b;
        4'b0001: y = a - b;
        4'b0010: y = a & b;
        4'b0011: y = a | b;
        4'b0100: y = a ^ b;
        4'b0101: y = a << b[4:0];
        4'b0110: y = a >> b[4:0];
        4'b0111: y = $signed(a) >>> b[4:0];
        4'b1000: y = {31'h0, $signed(a) < $signed(b)};
        4'b1001: y = {31'h0, a < b};
        default: y = 32'h0;
    endcase
end

assign zero = (y == 32'h0);

endmodule
