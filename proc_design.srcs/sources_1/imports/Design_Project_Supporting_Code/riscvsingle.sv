`timescale 1ns / 1ps
// riscvsingle.sv - single-cycle RISC-V processor (design project, Parts B and C).
// Adapted for ECSE 2610 from Section 7.6 of Harris & Harris, Digital Design and Computer
// Architecture: RISC-V Edition. Module and signal names follow Figures 1 to 3 of the handout.
//
//   top           processor + instruction memory + data memory     complete the two memories
//   riscvsingle   controller + datapath                            provided
//   controller    main decoder + ALU decoder + PCSrc               provided
//   maindec       Table 1                                          complete four rows
//   aludec        Table 2                                          provided
//   datapath      Figure 2                                         provided
//
// Also needed: alu.sv and extend.sv (starters), mux2.sv, mux3.sv, adder.sv (provided),
// register.sv from Lab 6, and regfile.sv, rom_imem.sv, ram_sp.sv from Lab 8.
//
// Instructions: lw, sw, add, sub, and, or, slt, addi, andi, ori, slti, beq, jal.

module top (
    input  logic        clk, reset,
    output logic [31:0] WriteData, DataAdr,         // data-memory interface, tapped out for testing
    output logic        MemWrite,
    output logic [31:0] PC                          // tapped out for the board display in Part F
);

    logic [31:0] Instr, ReadData;

    // processor: controller and datapath
    riscvsingle rvsingle (
        .clk       (clk),
        .reset     (reset),
        .PC        (PC),
        .Instr     (Instr),
        .MemWrite  (MemWrite),
        .ALUResult (DataAdr),
        .WriteData (WriteData),
        .ReadData  (ReadData)
    );

    // TODO: instruction memory. Instantiate rom_imem from Lab 8 with 64 words and FILE = "riscvtest.hex".
    //       PC is its address and Instr is its read data.
    rom_imem imem #(FILE="riscvtest.hex") (
        .addr   (PC),
        .rd     (Instr)
    );

    // TODO: data memory. Instantiate ram_sp from Lab 8 as 64 words of 32 bits.
    //       DataAdr is a byte address and the memory needs a word index (Lab 8, Part B).
    //       It writes WriteData when MemWrite is 1, and its read data is ReadData.
    ram_sp ram (
        .clk    (clk),
        .we     (MemWrite),
        .addr   (DataAdr),
        .wd     (WriteData),
        .rd     (ReadData)
    );

endmodule

module riscvsingle (
    input  logic        clk, reset,
    output logic [31:0] PC,
    input  logic [31:0] Instr,
    output logic        MemWrite,
    output logic [31:0] ALUResult, WriteData,
    input  logic [31:0] ReadData
);

    logic       ALUSrc, RegWrite, Jump, Zero, PCSrc;
    logic [1:0] ResultSrc, ImmSrc;
    logic [2:0] ALUControl;

    controller c (
        .op         (Instr[6:0]),
        .funct3     (Instr[14:12]),
        .funct7b5   (Instr[30]),
        .Zero       (Zero),
        .ResultSrc  (ResultSrc),
        .MemWrite   (MemWrite),
        .PCSrc      (PCSrc),
        .ALUSrc     (ALUSrc),
        .RegWrite   (RegWrite),
        .Jump       (Jump),
        .ImmSrc     (ImmSrc),
        .ALUControl (ALUControl)
    );

    datapath dp (
        .clk        (clk),
        .reset      (reset),
        .ResultSrc  (ResultSrc),
        .PCSrc      (PCSrc),
        .ALUSrc     (ALUSrc),
        .RegWrite   (RegWrite),
        .ImmSrc     (ImmSrc),
        .ALUControl (ALUControl),
        .Zero       (Zero),
        .PC         (PC),
        .Instr      (Instr),
        .ALUResult  (ALUResult),
        .WriteData  (WriteData),
        .ReadData   (ReadData)
    );

endmodule

module controller (
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic       Zero,
    output logic [1:0] ResultSrc,
    output logic       MemWrite,
    output logic       PCSrc, ALUSrc,
    output logic       RegWrite, Jump,
    output logic [1:0] ImmSrc,
    output logic [2:0] ALUControl
);

    logic [1:0] ALUOp;
    logic       Branch;

    maindec md (
        .op        (op),
        .ResultSrc (ResultSrc),
        .MemWrite  (MemWrite),
        .Branch    (Branch),
        .ALUSrc    (ALUSrc),
        .RegWrite  (RegWrite),
        .Jump      (Jump),
        .ImmSrc    (ImmSrc),
        .ALUOp     (ALUOp)
    );

    aludec ad (
        .opb5       (op[5]),
        .funct3     (funct3),
        .funct7b5   (funct7b5),
        .ALUOp      (ALUOp),
        .ALUControl (ALUControl)
    );

    assign PCSrc = Branch & Zero | Jump;

endmodule

module maindec (
    input  logic [6:0] op,
    output logic [1:0] ResultSrc,
    output logic       MemWrite,
    output logic       Branch, ALUSrc,
    output logic       RegWrite, Jump,
    output logic [1:0] ImmSrc,
    output logic [1:0] ALUOp
);

    logic [10:0] controls;

    assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
            ResultSrc, Branch, ALUOp, Jump} = controls;

    // One row of Table 1 per opcode. Underscores only separate the fields.
    // A don't-care (x) in the table may be written as x or as 0.
    always_comb
        case (op)
            //                         RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
            7'b0000011: controls = 11'b1_00_1_0_01_0_00_0;              // lw
            7'b0100011: controls = 11'b0_01_1_1_xx_0_00_0;              // sw
            7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0;              // R-type
            7'b1100011: controls = 11'b0_10_0_0_xx_1_01_0;              // beq
            7'b0010011: controls = 11'b1_00_1_0_00_0_10_0;              // I-type ALU
            7'b1101111: controls = 11'b1_11_x_0_10_0_xx_1;              // jal
            default:    controls = 11'bx_xx_x_x_xx_x_xx_x;              // instruction not implemented
        endcase

endmodule

module aludec (
    input  logic       opb5,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic [1:0] ALUOp,
    output logic [2:0] ALUControl
);

    logic RtypeSub;

    assign RtypeSub = funct7b5 & opb5;      // true only for an R-type subtract

    always_comb
        case (ALUOp)
            2'b00:   ALUControl = 3'b000;                   // add: lw, sw
            2'b01:   ALUControl = 3'b001;                   // subtract: beq
            default: case (funct3)                          // R-type or I-type ALU
                         3'b000:  if (RtypeSub) ALUControl = 3'b001;    // sub
                                  else          ALUControl = 3'b000;    // add, addi
                         3'b010:  ALUControl = 3'b101;      // slt, slti
                         3'b110:  ALUControl = 3'b011;      // or, ori
                         3'b111:  ALUControl = 3'b010;      // and, andi
                         default: ALUControl = 3'bxxx;      // not implemented
                     endcase
        endcase

endmodule

module datapath (
    input  logic        clk, reset,
    input  logic [1:0]  ResultSrc,
    input  logic        PCSrc, ALUSrc,
    input  logic        RegWrite,
    input  logic [1:0]  ImmSrc,
    input  logic [2:0]  ALUControl,
    output logic        Zero,
    output logic [31:0] PC,
    input  logic [31:0] Instr,
    output logic [31:0] ALUResult, WriteData,
    input  logic [31:0] ReadData
);

    logic [31:0] PCNext, PCPlus4, PCTarget;
    logic [31:0] ImmExt;
    logic [31:0] SrcA, SrcB;
    logic [31:0] Result;

    // next-PC logic. The PC is your Lab 6 register, always enabled.
    register #(.W(32)) pcreg (
        .clk (clk),
        .rst (reset),
        .en  (1'b1),
        .d   (PCNext),
        .q   (PC)
    );
    adder      pcadd4      (.a(PC), .b(32'd4),  .y(PCPlus4));
    adder      pcaddbranch (.a(PC), .b(ImmExt), .y(PCTarget));
    mux2 #(32) pcmux       (.d0(PCPlus4), .d1(PCTarget), .s(PCSrc), .y(PCNext));

    // register file (Lab 8) and immediate extension
    regfile rf (
        .clk (clk),
        .we3 (RegWrite),
        .a1  (Instr[19:15]),
        .a2  (Instr[24:20]),
        .a3  (Instr[11:7]),
        .wd3 (Result),
        .rd1 (SrcA),
        .rd2 (WriteData)
    );
    extend ext (.instr(Instr[31:7]), .immsrc(ImmSrc), .immext(ImmExt));

    // ALU and result selection
    mux2 #(32) srcbmux (.d0(WriteData), .d1(ImmExt), .s(ALUSrc), .y(SrcB));
    alu        alu     (.a(SrcA), .b(SrcB), .alucontrol(ALUControl), .result(ALUResult), .zero(Zero));
    mux3 #(32) resultmux (.d0(ALUResult), .d1(ReadData), .d2(PCPlus4), .s(ResultSrc), .y(Result));

endmodule
