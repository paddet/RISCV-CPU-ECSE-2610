`timescale 1ns / 1ps
// riscv_tb.sv - self-checking testbench for the processors of the design project.
// Provided complete. The same file tests the single-cycle and the multicycle processor,
// because both have the same top-level interface.
//
// How it decides: the test program reports success by writing OK_DATA to address OK_ADDR and
// then PASS_DATA to address PASS_ADDR. Any other write, a passing write that comes before the
// first one, an unknown (x) MemWrite, or running for MAX_CYCLES without the passing write is
// a failure.
//
// The memory image is named inside top, where the memory is instantiated. For your own test
// program in Part C, change that file name there, and change OK_DATA and PASS_DATA here.

module riscv_tb;

    // ---------------- settings ----------------
    localparam logic [31:0] PASS_ADDR  = 32'd100;           // address of the final write
    localparam logic [31:0] PASS_DATA  = 32'd25;            // value of the final write
    localparam logic [31:0] OK_ADDR    = 32'd96;            // address of the first write
    localparam logic [31:0] OK_DATA    = 32'd7;             // value of the first write
    localparam int          MAX_CYCLES = 1000;              // give up after this many cycles

    // ---------------- signals ----------------
    logic        clk, reset;
    logic [31:0] WriteData, DataAdr, PC;
    logic        MemWrite;
    int          cycles = 0;            // clock cycles since reset was released
    logic        ok_seen = 1'b0;        // OK_DATA has been written to OK_ADDR

    // ---------------- design under test ----------------
    top dut (
        .clk       (clk),
        .reset     (reset),
        .WriteData (WriteData),
        .DataAdr   (DataAdr),
        .MemWrite  (MemWrite),
        .PC        (PC)
    );

    // ---------------- reset: held for the first two clock cycles ----------------
    initial begin
        reset = 1'b1;
        #22;
        reset = 1'b0;
    end

    // ---------------- clock: 10 ns period, rising edges at 0, 10, 20, ... ns ----------------
    always begin
        clk = 1'b1; #5;
        clk = 1'b0; #5;
    end

    // ---------------- check on falling edges, after the cycle's values settle ----------------
    always @(negedge clk)
        if (!reset) begin
            cycles = cycles + 1;
            if (MemWrite === 1'b1) begin
                if (DataAdr === PASS_ADDR && WriteData === PASS_DATA) begin
                    if (ok_seen)
                        $display("PASS: Simulation succeeded. Wrote %0d to address %0d in clock cycle %0d.",
                                 WriteData, DataAdr, cycles);
                    else
                        $display("FAIL: wrote %0d to address %0d in clock cycle %0d, but %h was never written to address %0d.",
                                 WriteData, DataAdr, cycles, OK_DATA, OK_ADDR);
                    $finish;
                end
                else if (DataAdr === OK_ADDR && WriteData === OK_DATA)
                    ok_seen = 1'b1;
                else begin
                    $display("FAIL: Simulation failed. Wrote %h to address %h in clock cycle %0d (PC = %h).",
                             WriteData, DataAdr, cycles, PC);
                    $finish;
                end
            end
            else if (MemWrite !== 1'b0) begin
                $display("FAIL: MemWrite is unknown (x) in clock cycle %0d (PC = %h).", cycles, PC);
                $finish;
            end
            if (cycles >= MAX_CYCLES) begin
                $display("FAIL: no write of %0d to address %0d within %0d clock cycles (PC = %h).",
                         PASS_DATA, PASS_ADDR, MAX_CYCLES, PC);
                $finish;
            end
        end

endmodule
