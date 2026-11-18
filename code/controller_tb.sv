`timescale 1ns / 1ps
// controller_tb.sv - vector testbench for the multicycle controller (design project, Part D).
// Provided complete. It reads controller.tv, which holds one test vector per clock cycle:
//
//   op[6:0]_funct3[2:0]_funct7b5_Zero__ImmSrc[1:0]_ALUSrcA[1:0]_ALUSrcB[1:0]_ResultSrc[1:0]_AdrSrc_
//                                      ALUControl[2:0]_IRWrite_PCWrite_RegWrite_MemWrite
//
// The four inputs of a vector are applied just after a rising clock edge and held for that
// cycle. The ten outputs are compared on the falling edge of the same cycle. An x in an
// expected output marks a don't-care, which is not compared.
// PASS requires all 63 supplied vectors and no mismatching outputs.
//
// If the log shows every expected value as x, the simulator did not find controller.tv.

module controller_tb;

    localparam int MAXVECTORS = 1000;
    localparam int EXPECTED_VECTORS = 63;

    // ---------------- signals ----------------
    logic        clk, reset;
    logic [6:0]  op;
    logic [2:0]  funct3;
    logic        funct7b5, Zero;
    logic [1:0]  ImmSrc, ALUSrcA, ALUSrcB, ResultSrc;
    logic        AdrSrc;
    logic [2:0]  ALUControl;
    logic        IRWrite, PCWrite, RegWrite, MemWrite;

    logic [27:0] testvectors [0:MAXVECTORS-1];
    logic [15:0] expected;
    int          vectornum = 0;
    int          errors    = 0;
    int          bad;                   // mismatching outputs in the current vector

    // ---------------- design under test ----------------
    controller dut (
        .clk        (clk),
        .reset      (reset),
        .op         (op),
        .funct3     (funct3),
        .funct7b5   (funct7b5),
        .Zero       (Zero),
        .ImmSrc     (ImmSrc),
        .ALUSrcA    (ALUSrcA),
        .ALUSrcB    (ALUSrcB),
        .ResultSrc  (ResultSrc),
        .AdrSrc     (AdrSrc),
        .ALUControl (ALUControl),
        .IRWrite    (IRWrite),
        .PCWrite    (PCWrite),
        .RegWrite   (RegWrite),
        .MemWrite   (MemWrite)
    );

    // ---------------- clock: 10 ns period, rising edges at 0, 10, 20, ... ns ----------------
    always begin
        clk = 1'b1; #5;
        clk = 1'b0; #5;
    end

    // ---------------- load the vectors and hold reset for two clock cycles ----------------
    initial begin
        $readmemb("controller.tv", testvectors);
        reset = 1'b1;
        #22;
        reset = 1'b0;
    end

    // ---------------- apply the inputs of the current vector after each rising edge ----------------
    always @(posedge clk) begin
        #1;
        {op, funct3, funct7b5, Zero, expected} = testvectors[vectornum];
    end

    // true when an output differs from its expected value; an expected x is not compared
    function automatic logic differs(input logic [2:0] got, input logic [2:0] want);
        differs = 1'b0;
        for (int i = 0; i < 3; i++)
            if (want[i] !== 1'bx && got[i] !== want[i]) differs = 1'b1;
    endfunction

    // ---------------- compare the outputs on each falling edge ----------------
    always @(negedge clk)
        if (!reset) begin
            bad = 0;
            if (differs({1'b0, ImmSrc}, {1'b0, expected[15:14]})) begin
                $display("  vector %0d: ImmSrc = %b, expected %b", vectornum, ImmSrc, expected[15:14]);
                bad++;
            end
            if (differs({1'b0, ALUSrcA}, {1'b0, expected[13:12]})) begin
                $display("  vector %0d: ALUSrcA = %b, expected %b", vectornum, ALUSrcA, expected[13:12]);
                bad++;
            end
            if (differs({1'b0, ALUSrcB}, {1'b0, expected[11:10]})) begin
                $display("  vector %0d: ALUSrcB = %b, expected %b", vectornum, ALUSrcB, expected[11:10]);
                bad++;
            end
            if (differs({1'b0, ResultSrc}, {1'b0, expected[9:8]})) begin
                $display("  vector %0d: ResultSrc = %b, expected %b", vectornum, ResultSrc, expected[9:8]);
                bad++;
            end
            if (differs({2'b0, AdrSrc}, {2'b0, expected[7]})) begin
                $display("  vector %0d: AdrSrc = %b, expected %b", vectornum, AdrSrc, expected[7]);
                bad++;
            end
            if (differs(ALUControl, expected[6:4])) begin
                $display("  vector %0d: ALUControl = %b, expected %b", vectornum, ALUControl, expected[6:4]);
                bad++;
            end
            if (differs({2'b0, IRWrite}, {2'b0, expected[3]})) begin
                $display("  vector %0d: IRWrite = %b, expected %b", vectornum, IRWrite, expected[3]);
                bad++;
            end
            if (differs({2'b0, PCWrite}, {2'b0, expected[2]})) begin
                $display("  vector %0d: PCWrite = %b, expected %b", vectornum, PCWrite, expected[2]);
                bad++;
            end
            if (differs({2'b0, RegWrite}, {2'b0, expected[1]})) begin
                $display("  vector %0d: RegWrite = %b, expected %b", vectornum, RegWrite, expected[1]);
                bad++;
            end
            if (differs({2'b0, MemWrite}, {2'b0, expected[0]})) begin
                $display("  vector %0d: MemWrite = %b, expected %b", vectornum, MemWrite, expected[0]);
                bad++;
            end

            if (bad != 0) begin
                $display("Error on vector %0d: op = %b, funct3 = %b, funct7b5 = %b, Zero = %b",
                         vectornum, op, funct3, funct7b5, Zero);
                errors++;
            end

            vectornum++;

            // an entry that was never loaded is all x: that is the end of the file
            if (vectornum == MAXVECTORS || testvectors[vectornum] === 28'bx) begin
                $display("%0d vectors completed with %0d errors.", vectornum, errors);
                if (vectornum < 2)    $display("FAIL: controller.tv was not found or is empty.");
                else if (vectornum != EXPECTED_VECTORS)
                    $display("FAIL: expected %0d vectors in controller.tv, completed %0d.",
                             EXPECTED_VECTORS, vectornum);
                else if (errors == 0) $display("PASS: the controller matches every test vector.");
                else                  $display("FAIL: start with the first error listed above.");
                $finish;
            end
        end

endmodule
