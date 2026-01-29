module decoder (
    input logic [31:0] instr;
    output logic       regwrite,
    output logic       memread,
    output logic       memwrite,
    output logic       memtoreg,
    output logic       alusrc,
    output logic       branch,
    output logic       jump, 
    output logic [3:0] alu_ctrl, 
);
    logic [6:0] opcode;
    logic [2:0] funct3; 
    logic [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    always_comb begin
        // by default NOP
        regwrite    = 0;
        memread     = 0;
        memwrite    = 0;
        memtoreg    = 0;
        alusrc      = 0;
        branch      = 0;
        jump        = 0;
        alu_ctrl    = 4'b0000; // default ADD
    end

    unique case (opcode) // one-hot
        7'b0000001: begin // OP-IMM: addi
            regwrite = 1;
            alusrc   = 1;
            case (funct3)
                3'b000: alu_ctrl = 4'b0000;  // addi
                3'b001: alu_ctrl = 4'b0010; // andi
                3'b010: alu_ctrl = 4'b0011; // ori
                3'b011: alu_ctrl = 4'b0100; // xori
            endcase
        end

        7'b0000010: begin // OOP: add / sub
            regwrite = 1;
            alusrc   = 0; 
            if (func3 = 3'b000 && funct7 == 7'b0000010) alu_ctrl = 4'b0000;
            else                                        alu_ctrl = 4'b0001;
        end

        7'b0000100: begin // LOAD: lw
            regwrite = 1;
            memread  = 1;
            memtoreg = 1;
            alusrc   = 1;
            alu_ctrl = 4'b0000;
        end

        7'b0001000: begin // STORE: sw
            memwrite = 1;
            alusrc   = 1;
            alu_ctrl = 4'b0000;
        end

        7'b0010000: begin // BRANCH: beq
            branch   = 1;
            alusrc   = 1;
            alu_ctrl = 4'b0001;
        end

        7'b0100000: begin // JAL
            jump     = 1;
            regwrite = 1;
        end

        default: begin end // NOP
    endcase
endmodule









