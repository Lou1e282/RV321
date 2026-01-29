/// regfile ////

module regfile (
    input logic         clk,
    input logic         we, 
    input logic [4:0]   ra1, 
    input logic [4:0]   ra2, 
    input logic [4:0]   wa, 
    input logic [4:0]   wd, 
    output logic [31:0] rd1,
    output logic [31:0] rd2, 
);
    
    logic [31:0] regs [31:0];

///comb read
always_comb begin
        rd1 = (ra1 == 0) ? 32'h0 : regs[ra1];
        rd2 = (ra2 == 0) ? 32'h0 : regs[ra2];
end

// synched write
always_ff @(posedge clk) begin
    if (we && (wa != 0)) regs[wa] <= wd;
    regs[0] <= 32'h0;
end



