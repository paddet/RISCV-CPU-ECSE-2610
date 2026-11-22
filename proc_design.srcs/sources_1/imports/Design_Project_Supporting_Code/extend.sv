`timescale 1ns / 1ps
// extend.sv - immediate extension for both processors of the design project.
// Starter to complete in Part B: write the S-, B-, and J-type cases from Table 3.
// The instruction's opcode bits [6:0] carry no immediate, so only bits [31:7] come in.

module extend (
    input  logic [31:7] instr,
    input  logic [1:0]  immsrc,
    output logic [31:0] immext
);

    always_comb
        case (immsrc)
            2'b00:   immext = {{20{instr[31]}}, instr[31:20]};                                  // I-type
            2'b01:   immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};                     // S-type
            2'b10:   immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};     // B-type
            2'b11:   immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};   // J-type
            default: immext = 32'bx;
        endcase

endmodule
