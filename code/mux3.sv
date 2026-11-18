`timescale 1ns / 1ps
// mux3.sv - three-input multiplexer. Provided complete.
// s = 00 selects d0, 01 selects d1, 10 selects d2. The code 11 is not used.
module mux3 #(
    parameter int WIDTH = 32
) (
    input  logic [WIDTH-1:0] d0, d1, d2,
    input  logic [1:0]       s,
    output logic [WIDTH-1:0] y
);

    assign y = s[1] ? d2 : (s[0] ? d1 : d0);

endmodule
