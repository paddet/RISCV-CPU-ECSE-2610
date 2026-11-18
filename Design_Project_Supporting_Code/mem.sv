`timescale 1ns / 1ps
// mem.sv - one memory for both instructions and data, for the multicycle processor (Part E).
// Provided complete. It is Lab 8's rom_imem and ram_sp combined: the program is loaded from a
// file, the read is asynchronous, and the write is synchronous. Addresses are byte addresses;
// the two low address bits are ignored, so every access is word aligned.

module mem #(
    parameter int    WORDS = 64,
    parameter string FILE  = "riscvtest.hex"
) (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] a,              // byte address
    input  logic [31:0] wd,
    output logic [31:0] rd
);

    logic [31:0] RAM [0:WORDS-1];

    initial $readmemh(FILE, RAM);

    assign rd = RAM[a[$clog2(WORDS)+1 : 2]];            // asynchronous read

    always_ff @(posedge clk)
        if (we) RAM[a[$clog2(WORDS)+1 : 2]] <= wd;      // synchronous write

endmodule
