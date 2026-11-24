`timescale 1ns / 1ps

module rom_imem #(
    parameter int    WORDS = 64,
    parameter string FILE  = "riscvtest.hex"
) (
    input  logic [31:0] addr,           // byte address, as a processor supplies it
    output logic [31:0] rd
);
 
    logic [31:0] mem [0:WORDS-1];
 
    initial $readmemh(FILE, mem);
 
    assign rd = mem[addr[$clog2(WORDS)+1 : 2]];    // word-aligned: drop the two low bits
 
endmodule
