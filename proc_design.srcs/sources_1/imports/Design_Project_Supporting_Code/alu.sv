`timescale 1ns / 1ps
// alu.sv - 32-bit arithmetic logic unit for both processors of the design project.
// Starter to complete in Part B. It is your Lab 5 ALU widened to 32 bits, with one new
// operation, set less than.
//
//   alucontrol   operation        result                                   (Table 2)
//   000          add              a + b
//   001          subtract         a - b
//   010          and              a & b
//   011          or               a | b
//   101          set less than    1 if a < b as signed numbers, otherwise 0
//
// One adder serves add, subtract, and set less than (Figure 4).

module alu (
    input  logic [31:0] a, b,
    input  logic [2:0]  alucontrol,
    output logic [31:0] result,
    output logic        zero            // 1 when result is all zeros
);

    logic [31:0] condinvb;              // b, or ~b when the adder subtracts
    logic [31:0] sum;                   // adder output
    logic        overflow;              // signed overflow of the adder

    assign condinvb = (alucontrol[0] == 1) ? (~b + 1) : b;
    assign sum      = a + condinvb;
    assign overflow = (~alucontrol[1]) & (~(alucontrol[0] | b[31] | a[31])) & (a[31] | sum[31]);

    always_comb
        case (alucontrol)
            3'b000:  result = sum;                              // add
            3'b001:  result = sum;                              // subtract
            3'b010:  result = a & b;                            // and
            3'b011:  result = a | b;                            // or
            3'b101:  result = (overflow ^ sum[31]);               // set less than
            default: result = 32'bx;                            // codes that are not used
        endcase

    assign zero = (result == '0) ? 1 : 0;

endmodule
