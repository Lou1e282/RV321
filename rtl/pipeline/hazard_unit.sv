// Hazard detection and forwarding unit

module hazard_unit (
    // Forwarding: EX stage source registers
    input  logic [4:0] id_ex_rs1,
    input  logic [4:0] id_ex_rs2,
    // Forwarding: EX/MEM stage destination (EX-EX path)
    input  logic [4:0] ex_mem_rd,
    input  logic       ex_mem_regwrite,
    // Forwarding: MEM/WB stage destination (MEM-EX path)
    input  logic [4:0] mem_wb_rd,
    input  logic       mem_wb_regwrite,

    // Load-use stall: load in EX, consumer in ID
    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_memread,
    input  logic [4:0] if_id_rs1,
    input  logic [4:0] if_id_rs2,

    // JAL resolved in ID (1-cycle penalty: flush IF/ID only)
    input  logic       jal_id,
    // JALR resolved in EX (2-cycle penalty: flush IF/ID + ID/EX)
    input  logic       jalr_ex,
    // Branch resolved in EX (2-cycle penalty)
    input  logic       branch_taken,

    // Forwarding mux selects for EX stage ALU inputs
    // 2'b00 = regfile, 2'b01 = MEM/WB wb_data, 2'b10 = EX/MEM alu_y
    output logic [1:0] forwardA,
    output logic [1:0] forwardB,

    // Stall / flush controls
    output logic       pc_stall,
    output logic       if_id_stall,
    output logic       if_id_flush,
    output logic       id_ex_flush
);

    logic load_use_stall;
    logic flush_2cycle;   // branch or JALR: flush IF/ID and ID/EX
    logic flush_1cycle;   // JAL in ID: flush IF/ID only

    assign load_use_stall = id_ex_memread
                         && (id_ex_rd != 5'h0)
                         && ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

    assign flush_2cycle = branch_taken || jalr_ex;
    assign flush_1cycle = jal_id;

    assign pc_stall    =  load_use_stall && !flush_2cycle && !flush_1cycle;
    assign if_id_stall =  load_use_stall && !flush_2cycle && !flush_1cycle;
    assign if_id_flush =  flush_2cycle || flush_1cycle;
    assign id_ex_flush =  flush_2cycle || load_use_stall;

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
