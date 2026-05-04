// Hazard detection and forwarding unit

module hazard_unit (
    // Forwarding: what's in EX stage reading
    input  logic [4:0] id_ex_rs1,
    input  logic [4:0] id_ex_rs2,
    // Forwarding: what's in MEM stage (EX-EX path)
    input  logic [4:0] ex_mem_rd,
    input  logic       ex_mem_regwrite,
    // Forwarding: what's in WB stage (MEM-EX path)
    input  logic [4:0] mem_wb_rd,
    input  logic       mem_wb_regwrite,

    // Load-use stall: load is in EX, dependent instr is in ID
    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_memread,
    input  logic [4:0] if_id_rs1,
    input  logic [4:0] if_id_rs2,

    // Flush: branch resolved combinatorially in EX; jump in ID/EX
    input  logic       branch_taken,
    input  logic       jump_ex,

    // Forwarding mux selects (EX stage ALU inputs)
    // 2'b00 = regfile, 2'b01 = MEM/WB wb_data, 2'b10 = EX/MEM alu_y
    output logic [1:0] forwardA,
    output logic [1:0] forwardB,

    // Stall/flush controls
    output logic       pc_stall,
    output logic       if_id_stall,
    output logic       if_id_flush,
    output logic       id_ex_flush
);

    logic load_use_stall;
    logic flush;

    // Load-use: load in EX, consumer in ID — stall 1 cycle
    assign load_use_stall = id_ex_memread
                         && (id_ex_rd != 5'h0)
                         && ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

    assign flush = branch_taken || jump_ex;

    assign pc_stall    =  load_use_stall && !flush;
    assign if_id_stall =  load_use_stall && !flush;
    assign if_id_flush =  flush;
    assign id_ex_flush =  flush || load_use_stall;

    // EX-EX forwarding takes priority over MEM-EX
    always_comb begin
        if      (ex_mem_regwrite && ex_mem_rd != 5'h0 && ex_mem_rd == id_ex_rs1)
            forwardA = 2'b10;
        else if (mem_wb_regwrite && mem_wb_rd != 5'h0 && mem_wb_rd == id_ex_rs1)
            forwardA = 2'b01;
        else
            forwardA = 2'b00;

        if      (ex_mem_regwrite && ex_mem_rd != 5'h0 && ex_mem_rd == id_ex_rs2)
            forwardB = 2'b10;
        else if (mem_wb_regwrite && mem_wb_rd != 5'h0 && mem_wb_rd == id_ex_rs2)
            forwardB = 2'b01;
        else
            forwardB = 2'b00;
    end

endmodule
