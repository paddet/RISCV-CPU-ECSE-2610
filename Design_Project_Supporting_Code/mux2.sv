`timescale 1ns / 1ps
// mux2.sv - two-input multiplexer. Provided complete.
module mux2 #(
    parameter int WIDTH = 32
) (
    input  logic [WIDTH-1:0] d0, d1,
    input  logic             s,
    output logic [WIDTH-1:0] y
);

    assign y = s ? d1 : d0;

endmodule
