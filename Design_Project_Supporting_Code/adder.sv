`timescale 1ns / 1ps
// adder.sv - 32-bit adder for the next-PC logic of the single-cycle processor. Provided complete.
module adder (
    input  logic [31:0] a, b,
    output logic [31:0] y
);

    assign y = a + b;

endmodule
