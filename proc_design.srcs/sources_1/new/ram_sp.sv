`timescale 1ns / 1ps

module ram_sp #(
    parameter int AW = 4,   // address width: 2**AW words
    parameter int DW = 8    // data width
) (
    input  logic          clk,
    input  logic          we,
    input  logic [AW-1:0] addr,
    input  logic [DW-1:0] wd,
    output logic [DW-1:0] rd
);
 
    logic [DW-1:0] mem [0:2**AW-1];
 
    always_ff @(posedge clk)
        if (we) mem[addr] <= wd;
 
    assign rd = mem[addr];
 
endmodule
