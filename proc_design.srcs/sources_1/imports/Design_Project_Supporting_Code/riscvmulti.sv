`timescale 1ns / 1ps
// riscvmulti.sv - multicycle RISC-V processor (design project, Part E).
// Starter to complete. Figure 7 is the datapath, and Figure 1 shows how a processor connects to
// its memories. The module headers below are a suggested hierarchy:
//
//   top          processor + one memory for instructions and data     write the body
//   riscvmulti   your Part D controller + the datapath                write the body
//   datapath     Figure 7                                              write the body
//
// Keep the ports of top as they are: riscv_tb.sv and board_top.sv use them. You may change the
// ports of riscvmulti and datapath if your hierarchy diagram calls for it.
//
// Also needed: controller.sv from Part D; alu.sv, extend.sv, mux2.sv, mux3.sv from Part B;
// mem.sv (provided); register.sv from Lab 6; regfile.sv from Lab 8.
//
// Instructions: lw, sw, add, sub, and, or, slt, addi, andi, ori, slti, beq, jal.

module top (
    input  logic        clk, reset,
    output logic [31:0] WriteData, DataAdr,         // memory interface, tapped out for testing
    output logic        MemWrite,
    output logic [31:0] PC                          // tapped out for the board display in Part F
);

    logic [31:0] ReadData;

    // TODO: processor. Instantiate riscvmulti. Its memory address is DataAdr.

    // TODO: memory. Instantiate mem with 64 words and FILE = "riscvtest.hex".
    //       The one memory holds the program and the data.

endmodule

module riscvmulti (
    input  logic        clk, reset,
    output logic        MemWrite,
    output logic [31:0] Adr, WriteData,
    input  logic [31:0] ReadData,
    output logic [31:0] PC
);

    // TODO: declare the signals that run between the controller and the datapath.
    //       Instantiate your controller from Part D. Its op, funct3, and funct7b5 inputs are fields of Instr.
    //       Instantiate the datapath.

endmodule

module datapath (
    input  logic        clk, reset,
    input  logic [1:0]  ImmSrc,
    input  logic [1:0]  ALUSrcA, ALUSrcB,
    input  logic [1:0]  ResultSrc,
    input  logic        AdrSrc,
    input  logic [2:0]  ALUControl,
    input  logic        IRWrite, PCWrite,
    input  logic        RegWrite,
    output logic        Zero,
    output logic [31:0] Instr,          // to the controller
    output logic [31:0] Adr,            // memory address
    output logic [31:0] WriteData,      // memory write data
    input  logic [31:0] ReadData,       // memory read data
    output logic [31:0] PC
);

    // TODO: declare the internal 32-bit signals of Figure 7, such as OldPC, Data, A, ImmExt, SrcA,
    //       SrcB, ALUResult, ALUOut, and Result.
    //       Then build Figure 7 from left to right with register, mux2, mux3, regfile, extend, and alu:
    //       the PC register, enabled by PCWrite, and the address multiplexer
    //       the instruction register and the OldPC register, both enabled by IRWrite
    //       the Data register
    //       the register file, with registers A and WriteData on its two read outputs
    //       the immediate extension
    //       the SrcA and SrcB multiplexers, the ALU, and the ALUOut register
    //       the Result multiplexer

endmodule
