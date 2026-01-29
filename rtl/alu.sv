//// ALU 

module alu (
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [3:0] alu_ctrl,
    output logic [31:0] y,
    output logic        zero
);

// alu_crl;
// 0000 ADD, 0001 SUB, 0010 AND, 0011 OR, 0100 XOR, 1000 SLT

always_comb begin
    unique case (alu_ctrl)
        4'b0000: y = a + b;
        4'b0001: y = a - b;
        4'b0010: y = a & b;
        4'b0011: y = a | b;
        4'b0100: y = a ^ b;
        4'b1000: y = ($signed(a) < $signed(b));
    endcase     
end

assign zero = (y == 32'h0);

endmodule


