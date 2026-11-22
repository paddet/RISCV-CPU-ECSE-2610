`timescale 1ns / 1ps

module regfile (
    input  logic        clk,
    input  logic        we3,            // write enable
    input  logic [4:0]  a1, a2,         // read addresses
    input  logic [4:0]  a3,             // write address
    input  logic [31:0] wd3,            // write data
    output logic [31:0] rd1, rd2        // read data, combinational
);
 
    logic [31:0] rf [0:31];
 
    always_ff @(posedge clk)
        if (we3) rf[a3] <= wd3;
 
    // register 0 is hardwired to zero: mask it at the read ports
    assign rd1 = (a1 != 5'd0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 5'd0) ? rf[a2] : 32'b0;
 
endmodule
