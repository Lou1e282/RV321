//// instruction memort generation

module imm_gen (
  input  logic [31:0] instr,
  output logic [31:0] imm_i,
  output logic [31:0] imm_s,
  output logic [31:0] imm_b,
  output logic [31:0] imm_u,
  output logic [31:0] imm_j
);
  // I-type: [31:20]
  always_comb imm_i = {{20{instr[31]}}, instr[31:20]};

  // S-type: [31:25|11:7]
  always_comb imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};

  // B-type: [31|7|30:25|11:8|0]
  always_comb imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

  // U-type: [31:12] << 12
  always_comb imm_u = {instr[31:12], 12'h000};

  // J-type: [31|19:12|20|30:21|0]
  always_comb imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
endmodule
