`timescale 1ns / 1ps
// board_top.sv - Basys 3 wrapper for the processors of the design project (Part F).
// Provided complete. It works with either processor, because both have the same top interface.
//
// What it does:
//   - synchronizes reset, and synchronizes and debounces the step button
//   - lets clock pulses through to the processor one at a time: one per press of the step
//     button, or one per tick of a slow tick generator when run is 1
//   - watches the memory interface the way riscv_tb.sv does and lights pass or fail
//   - counts the processor's clock cycles up to the passing write
//   - shows one of four 16-bit views on the seven-segment display
//
// Dependencies: top (your processor); sync2 and debounce (Lab 7); tick_gen (Lab 6);
//               display_mux with its character converter and package chars (Lab 6);
//               BUFGCE, a Xilinx clock buffer with an enable, which needs no source file.
// Check the names and ports of your own display modules before building.

module board_top #(
    parameter int          STABLE    = 1_000_000,       // debounce time: 10 ms at 100 MHz
    parameter int          DWELL     = 17,              // display refresh: 2**17 clocks per digit
    parameter int          TICK_1HZ  = 100_000_000,     // board-clock cycles in one second
    parameter logic [31:0] PASS_ADDR = 32'd100,         // the same settings as riscv_tb.sv
    parameter logic [31:0] PASS_DATA = 32'd25,
    parameter logic [31:0] OK_ADDR   = 32'd96,
    parameter logic [31:0] OK_DATA   = 32'd7
) (
    input  logic       clk,         // 100 MHz oscillator
    input  logic       rst,         // btnC: reset the processor and the wrapper
    input  logic       step,        // btnR: one processor clock cycle per press, when run = 0
    input  logic       run,         // sw[0]: 1 = run from the tick generator
    input  logic [1:0] speed,       // sw[2:1]: 1, 4, 16, or 64 processor clock cycles per second
    input  logic [1:0] view,        // sw[15:14]: what the display shows
    output logic       mem_write,   // led[15]: MemWrite in the current cycle
    output logic       pass,        // led[14]: both writes have happened, in order
    output logic       fail,        // led[13]: an unexpected write has happened
    output logic       beat,        // led[0]: toggles on every processor clock cycle
    output logic [6:0] seg,         // 7-segment cathodes, active low
    output logic [3:0] an           // 7-segment anodes, active low
);

    // ---------------- internal signals ----------------
    logic        sys_rst, sys_rst_d;        // synchronized reset, and the same one cycle later
    logic        cpu_rst;                   // reset seen by the processor
    logic        step_sync, step_level;     // step button after the synchronizer and debouncer
    logic        step_pulse;                // one board-clock pulse per clean press
    logic        run_sync;
    logic [1:0]  speed_sync, speed_active;
    logic [26:0] period;                    // tick_gen terminal count
    logic        tick;                      // one board-clock pulse per processor cycle in run mode
    logic        ce;                        // clock enable: lets one pulse through per high cycle
    logic        cpu_clk;                   // the processor's clock: selected pulses of clk
    logic [31:0] WriteData, DataAdr, PC;    // from the processor
    logic        MemWrite;
    logic [31:0] last_adr, last_wd;         // address and data of the most recent write
    logic        ok_seen;                   // the first write, OK_DATA to OK_ADDR, has happened
    logic [15:0] cycles;                    // processor clock cycles up to the passing write
    logic [15:0] shown;                     // four hexadecimal digits on the display

    // ---------------- synchronizers and debouncer, on the board clock ----------------
    sync2 u_sync_rst  (.clk(clk), .d(rst),      .q(sys_rst));
    sync2 u_sync_step (.clk(clk), .d(step),     .q(step_sync));
    sync2 u_sync_run  (.clk(clk), .d(run),      .q(run_sync));
    sync2 u_sync_sp0  (.clk(clk), .d(speed[0]), .q(speed_sync[0]));
    sync2 u_sync_sp1  (.clk(clk), .d(speed[1]), .q(speed_sync[1]));

    debounce #(.STABLE(STABLE)) u_db (
        .clk     (clk),
        .rst     (sys_rst),
        .in      (step_sync),
        .level   (step_level),
        .pressed (step_pulse)
    );

    // ---------------- tick generator for run mode ----------------
    // A new speed is accepted only when a tick restarts the count.
    always_ff @(posedge clk)
        if (sys_rst || tick) speed_active <= speed_sync;

    always_comb
        case (speed_active)
            2'b00:   period = 27'(TICK_1HZ      - 1);   //  1 cycle per second
            2'b01:   period = 27'(TICK_1HZ / 4  - 1);   //  4
            2'b10:   period = 27'(TICK_1HZ / 16 - 1);   // 16
            default: period = 27'(TICK_1HZ / 64 - 1);   // 64
        endcase

    tick_gen #(.W(27)) u_tick (
        .clk    (clk),
        .rst    (sys_rst),
        .period (period),
        .tick   (tick)
    );

    // ---------------- processor reset and clock enable ----------------
    // While reset is held, every clock pulse reaches the processor, so that its synchronous
    // reset takes effect. The processor's reset is released one cycle after its clock has
    // stopped, so no register sees reset change at a clock edge.
    always_ff @(posedge clk) sys_rst_d <= sys_rst;

    assign cpu_rst = sys_rst | sys_rst_d;
    assign ce      = sys_rst | (~cpu_rst & (run_sync ? tick : step_pulse));

    // BUFGCE passes whole pulses of clk while CE is 1 and holds its output low otherwise.
    BUFGCE u_cpu_clk (
        .I  (clk),
        .CE (ce),
        .O  (cpu_clk)
    );

    // ---------------- the processor ----------------
    top u_top (
        .clk       (cpu_clk),
        .reset     (cpu_rst),
        .WriteData (WriteData),
        .DataAdr   (DataAdr),
        .MemWrite  (MemWrite),
        .PC        (PC)
    );

    // ---------------- observers, clocked like the processor ----------------
    // The same success test as riscv_tb.sv, built in hardware.
    always_ff @(posedge cpu_clk)
        if (cpu_rst) begin
            cycles   <= '0;
            pass     <= 1'b0;
            fail     <= 1'b0;
            ok_seen  <= 1'b0;
            beat     <= 1'b0;
            last_adr <= '0;
            last_wd  <= '0;
        end
        else begin
            beat <= ~beat;
            if (!pass && !fail) cycles <= cycles + 1'b1;
            if (MemWrite) begin
                last_adr <= DataAdr;
                last_wd  <= WriteData;
                if (!pass && !fail) begin
                    if (DataAdr == PASS_ADDR && WriteData == PASS_DATA) begin
                        if (ok_seen) pass <= 1'b1;                          // both writes, in order
                        else         fail <= 1'b1;                          // the first write is missing
                    end
                    else if (DataAdr == OK_ADDR && WriteData == OK_DATA)  ok_seen <= 1'b1;
                    else                                                  fail    <= 1'b1;
                end
            end
        end

    assign mem_write = MemWrite;

    // ---------------- display ----------------
    always_comb
        case (view)
            2'b00:   shown = {PC[7:0],       DataAdr[7:0]};     // where the program is
            2'b01:   shown = {DataAdr[7:0],  WriteData[7:0]};   // the memory interface now
            2'b10:   shown = {last_adr[7:0], last_wd[7:0]};     // the most recent write
            default: shown = cycles;                            // clock cycles used
        endcase

    // Four 5-bit character codes, left to right. Codes 0 to 15 are the hexadecimal digits.
    display_mux #(.DWELL(DWELL)) u_disp (
        .clk   (clk),
        .value ({1'b0, shown[15:12], 1'b0, shown[11:8], 1'b0, shown[7:4], 1'b0, shown[3:0]}),
        .seg   (seg),
        .an    (an)
    );

endmodule
