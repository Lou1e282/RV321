/// regfile ////

module regfile (
    input logic         clk,
    input logic         rst,
    input logic         we,
    input logic [4:0]   ra1,
    input logic [4:0]   ra2,
    input logic [4:0]   wa,
    input logic [31:0]  wd,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);

    logic [31:0] regs [31:0];

///comb read
always_comb begin
        if (ra1 == 0) rd1 = 32'h0;
        else if (we && (wa == ra1)) rd1 = wd;
        else rd1 = regs[ra1];

        if (ra2 == 0) rd2 = 32'h0;
        else if (we && (wa == ra2)) rd2 = wd;
        else rd2 = regs[ra2];
end

// synched write
always_ff @(posedge clk) begin
    if (rst) begin
        regs <= '{default: 32'h0};
    end else begin
        if (we && (wa != 0)) regs[wa] <= wd;
    end
end

endmodule
