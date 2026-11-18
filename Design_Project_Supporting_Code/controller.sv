`timescale 1ns / 1ps
// controller.sv - controller of the multicycle RISC-V processor (design project, Part D).
// Figure 5 shows the hierarchy and Figure 6 the state diagram.
//
//   controller   connects the three blocks and forms PCWrite       complete one line
//   mainfsm      Main FSM of Figure 6 in three-block form          complete next-state and output logic
//   aludec       Table 2, the same decoder as in Part B            provided
//   instrdec     Table 5                                           provided
//
// A don't-care output of the Main FSM is driven to 0, so that every output has a known value
// in every state and the test vectors can check it.

module controller (
    input  logic       clk, reset,
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic       Zero,
    output logic [1:0] ImmSrc,
    output logic [1:0] ALUSrcA, ALUSrcB,
    output logic [1:0] ResultSrc,
    output logic       AdrSrc,
    output logic [2:0] ALUControl,
    output logic       IRWrite, PCWrite,
    output logic       RegWrite, MemWrite
);

    logic [1:0] ALUOp;
    logic       Branch, PCUpdate;

    mainfsm fsm (
        .clk       (clk),
        .reset     (reset),
        .op        (op),
        .ALUSrcA   (ALUSrcA),
        .ALUSrcB   (ALUSrcB),
        .ResultSrc (ResultSrc),
        .AdrSrc    (AdrSrc),
        .IRWrite   (IRWrite),
        .PCUpdate  (PCUpdate),
        .RegWrite  (RegWrite),
        .MemWrite  (MemWrite),
        .ALUOp     (ALUOp),
        .Branch    (Branch)
    );

    aludec ad (
        .opb5       (op[5]),
        .funct3     (funct3),
        .funct7b5   (funct7b5),
        .ALUOp      (ALUOp),
        .ALUControl (ALUControl)
    );

    instrdec id (
        .op     (op),
        .ImmSrc (ImmSrc)
    );

    assign PCWrite = /* TODO */;            // the gates of Figure 5

endmodule

module mainfsm (
    input  logic       clk, reset,
    input  logic [6:0] op,
    output logic [1:0] ALUSrcA, ALUSrcB,
    output logic [1:0] ResultSrc,
    output logic       AdrSrc,
    output logic       IRWrite, PCUpdate,
    output logic       RegWrite, MemWrite,
    output logic [1:0] ALUOp,
    output logic       Branch
);

    // State names follow Figure 6. Each state's code is its number, S0 to S10.
    typedef enum logic [3:0] {
        FETCH    = 4'd0,
        DECODE   = 4'd1,
        MEMADR   = 4'd2,
        MEMREAD  = 4'd3,
        MEMWB    = 4'd4,
        MEMWRITE = 4'd5,
        EXECUTER = 4'd6,
        ALUWB    = 4'd7,
        EXECUTEI = 4'd8,
        JAL      = 4'd9,
        BEQ      = 4'd10
    } statetype;

    statetype state, nextstate;

    localparam logic [6:0] OP_LW    = 7'b0000011,
                           OP_SW    = 7'b0100011,
                           OP_RTYPE = 7'b0110011,
                           OP_ITYPE = 7'b0010011,     // I-type ALU: addi, andi, ori, slti
                           OP_JAL   = 7'b1101111,
                           OP_BEQ   = 7'b1100011;

    // ---------------- block 1: state register ----------------
    always_ff @(posedge clk)
        if (reset) state <= FETCH;
        else       state <= nextstate;

    // ---------------- block 2: next-state logic, the arrows of Figure 6 ----------------
    always_comb
        case (state)
            FETCH:    nextstate = DECODE;
            DECODE:   case (op)
                          OP_LW, OP_SW: nextstate = MEMADR;
                          // TODO: the other four arrows that leave Decode
                          default:      nextstate = FETCH;      // instruction not implemented
                      endcase
            // TODO: the next state of each of the other nine states
            default:  nextstate = FETCH;
        endcase

    // ---------------- block 3: output logic, the lists inside the bubbles of Figure 6 ----------------
    // Every output is first set to 0. Each state then lists only the outputs it needs.
    always_comb begin
        ALUSrcA   = 2'b00;
        ALUSrcB   = 2'b00;
        ResultSrc = 2'b00;
        AdrSrc    = 1'b0;
        IRWrite   = 1'b0;
        PCUpdate  = 1'b0;
        RegWrite  = 1'b0;
        MemWrite  = 1'b0;
        ALUOp     = 2'b00;
        Branch    = 1'b0;

        case (state)
            FETCH: begin
                IRWrite   = 1'b1;
                ALUSrcB   = 2'b10;
                ResultSrc = 2'b10;
                PCUpdate  = 1'b1;
            end
            DECODE: begin
                ALUSrcA   = 2'b01;
                ALUSrcB   = 2'b01;
            end
            // TODO: the outputs of the other nine states
            default: ;                  // keep the defaults
        endcase
    end

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
            2'b00:   ALUControl = 3'b000;                   // add
            2'b01:   ALUControl = 3'b001;                   // subtract
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

module instrdec (
    input  logic [6:0] op,
    output logic [1:0] ImmSrc
);

    always_comb
        case (op)
            7'b0110011: ImmSrc = 2'bxx;     // R-type: no immediate
            7'b0010011: ImmSrc = 2'b00;     // I-type ALU
            7'b0000011: ImmSrc = 2'b00;     // lw
            7'b0100011: ImmSrc = 2'b01;     // sw
            7'b1100011: ImmSrc = 2'b10;     // beq
            7'b1101111: ImmSrc = 2'b11;     // jal
            default:    ImmSrc = 2'bxx;     // instruction not implemented
        endcase

endmodule
