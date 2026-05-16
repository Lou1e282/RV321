// Synthesizable FPGA bring-up top for ILA.
//
// This top does not modify or parameterize core_pipeline. It implements a tiny
// single-cycle RV32I subset with a hardcoded ROM so Vivado can synthesize it
// cleanly and ILA can observe the essential datapath signals.
//
// Program:
//   addi x1, x0, 5
//   addi x2, x0, 7
//   add  x3, x1, x2
//   sw   x3, 0(x0)
//
// Expected ILA event:
//   mem_write_enable = 1
//   mem_addr         = 0
//   mem_write_data   = 12

module fpga_bringup_top (
    input         clk,
    input         rst_n,
    output        pass,
    output        fail,
    output [7:0]  debug_led
);

    (* mark_debug = "true" *) reg  [31:0] pc;
    (* mark_debug = "true" *) reg  [31:0] instruction;
    (* mark_debug = "true" *) wire        reg_write_enable;
    (* mark_debug = "true" *) wire [4:0]  reg_write_addr;
    (* mark_debug = "true" *) wire [31:0] reg_write_data;
    (* mark_debug = "true" *) wire        mem_write_enable;
    (* mark_debug = "true" *) wire [31:0] mem_addr;
    (* mark_debug = "true" *) wire [31:0] mem_write_data;
    (* mark_debug = "true" *) reg         done_flag;

    (* mark_debug = "true" *) wire [31:0] rs1_data;
    (* mark_debug = "true" *) wire [31:0] rs2_data;
    (* mark_debug = "true" *) wire [31:0] alu_b;
    (* mark_debug = "true" *) wire [31:0] alu_result;

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [4:0] rd     = instruction[11:7];
    wire [31:0] imm_i = {{20{instruction[31]}}, instruction[31:20]};
    wire [31:0] imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

    reg [31:0] regs [0:31];
    reg [31:0] dmem0;

    always @* begin
        case (pc[5:2])
            4'd0: instruction = 32'h0050_0093; // addi x1, x0, 5
            4'd1: instruction = 32'h0070_0113; // addi x2, x0, 7
            4'd2: instruction = 32'h0020_81b3; // add  x3, x1, x2
            4'd3: instruction = 32'h0030_2023; // sw   x3, 0(x0)
            default: instruction = 32'h0000_0013; // nop
        endcase
    end

    assign rs1_data = (rs1 == 5'd0) ? 32'h0 : regs[rs1];
    assign rs2_data = (rs2 == 5'd0) ? 32'h0 : regs[rs2];

    assign alu_b = (opcode == 7'b0010011) ? imm_i :
                   (opcode == 7'b0100011) ? imm_s :
                                            rs2_data;

    assign alu_result = rs1_data + alu_b;

    assign reg_write_enable = (opcode == 7'b0010011) ||
                              (opcode == 7'b0110011);
    assign reg_write_addr   = rd;
    assign reg_write_data   = alu_result;

    assign mem_write_enable = (opcode == 7'b0100011) && (funct3 == 3'b010);
    assign mem_addr         = alu_result;
    assign mem_write_data   = rs2_data;

    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            pc <= 32'h0;
            dmem0 <= 32'h0;
            done_flag <= 1'b0;
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'h0;
            end
        end else begin
            pc <= pc + 32'd4;

            if (reg_write_enable && reg_write_addr != 5'd0) begin
                regs[reg_write_addr] <= reg_write_data;
            end

            if (mem_write_enable && mem_addr == 32'h0) begin
                dmem0 <= mem_write_data;
            end

            if (mem_write_enable && mem_addr == 32'h0 && mem_write_data == 32'd12) begin
                done_flag <= 1'b1;
            end
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
        dmem0[2:0]
    };

endmodule
