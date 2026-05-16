// FPGA implementation wrapper for core_pipeline.
//
// core_pipeline is a simulation-friendly CPU top with only clk/rst_n ports.
// This wrapper exposes internal state so synthesis cannot optimize the whole
// core away as an empty design.

module fpga_top (
    input         clk,
    input         rst_n,
    output        pass,
    output        fail,
    output [7:0]  debug_led
);

    core_pipeline u_core (
        .clk   (clk),
        .rst_n (rst_n)
    );

    (* mark_debug = "true" *) wire [31:0] pc;
    (* mark_debug = "true" *) wire [31:0] instruction;
    (* mark_debug = "true" *) wire        reg_write_enable;
    (* mark_debug = "true" *) wire [4:0]  reg_write_addr;
    (* mark_debug = "true" *) wire [31:0] reg_write_data;
    (* mark_debug = "true" *) wire        mem_write_enable;
    (* mark_debug = "true" *) wire [31:0] mem_addr;
    (* mark_debug = "true" *) wire [31:0] mem_write_data;
    (* mark_debug = "true" *) reg         done_flag;

    (* mark_debug = "true" *) wire [31:0] if_id_pc;
    (* mark_debug = "true" *) wire [4:0]  id_ex_rs1;
    (* mark_debug = "true" *) wire [4:0]  id_ex_rs2;
    (* mark_debug = "true" *) wire [31:0] ex_mem_alu_result;
    (* mark_debug = "true" *) wire [31:0] mem_wb_write_data;
    (* mark_debug = "true" *) wire        stall;
    (* mark_debug = "true" *) wire        flush;
    (* mark_debug = "true" *) wire [1:0]  forward_a;
    (* mark_debug = "true" *) wire [1:0]  forward_b;
    (* mark_debug = "true" *) wire        branch_taken;

    assign pc                = u_core.pc;
    assign instruction       = u_core.if_instr;
    assign reg_write_enable  = u_core.wb_regwrite;
    assign reg_write_addr    = u_core.wb_rd;
    assign reg_write_data    = u_core.wb_data;
    assign mem_write_enable  = |u_core.ex_mem_be;
    assign mem_addr          = u_core.ex_mem_alu_y;
    assign mem_write_data    = u_core.ex_mem_rs2_val;

    assign if_id_pc          = u_core.if_id_pc;
    assign id_ex_rs1         = u_core.id_ex_rs1;
    assign id_ex_rs2         = u_core.id_ex_rs2;
    assign ex_mem_alu_result = u_core.ex_mem_alu_y;
    assign mem_wb_write_data = u_core.wb_data;
    assign stall             = u_core.pc_stall;
    assign flush             = u_core.if_id_flush;
    assign forward_a         = u_core.forwardA;
    assign forward_b         = u_core.forwardB;
    assign branch_taken      = u_core.ex_branch_taken;

    always @(posedge clk) begin
        if (!rst_n) begin
            done_flag <= 1'b0;
        end else if (mem_write_enable && mem_addr == 32'h0 && mem_write_data == 32'd12) begin
            done_flag <= 1'b1;
        end
    end

    assign pass = done_flag;
    assign fail = 1'b0;

    assign debug_led = {
        pc[4],
        pc[3],
        pc[2],
        fail,
        pass,
        mem_write_data[2:0]
    };

endmodule
