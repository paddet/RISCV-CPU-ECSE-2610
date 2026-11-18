# Design Project supporting code

Starters, provided modules, testbenches, and data files for the design project. See the handout for
instructions, testing, and report requirements. A starter does not compile until every `TODO` is replaced.

| File | Used in | Purpose |
| --- | --- | --- |
| `riscvtest.s`, `riscvtest.hex` | Parts A, B, E, F | Test program and its memory image; provided data. |
| `riscvsingle.sv` | Parts B, C | Single-cycle processor; starter to complete (`maindec` rows and the memories in `top`). |
| `alu.sv` | Parts B to F | 32-bit ALU; starter to complete. |
| `extend.sv` | Parts B to F | Immediate extension; starter to complete. |
| `mux2.sv`, `mux3.sv`, `adder.sv` | Parts B to F | Multiplexers and adder; provided complete. |
| `riscv_tb.sv` | Parts B, C, E | Processor testbench for either processor; provided complete. |
| `controller.sv` | Parts D to F | Multicycle controller; starter to complete (`mainfsm` and `PCWrite`). |
| `controller_tb.sv`, `controller.tv` | Part D | Vector testbench and its 63 test vectors; provided complete. |
| `riscvmulti.sv` | Parts E, F | Multicycle processor; starter with module headers only. |
| `mem.sv` | Parts E, F | One memory for instructions and data; provided complete. |
| `board_top.sv` | Part F | Basys 3 wrapper for either processor; provided complete. |

Reused from earlier labs, not included here: `register.sv`, `tick_gen.sv`, and your display path (Lab 6);
`sync2.sv` and `debounce.sv` (Lab 7); `regfile.sv`, `rom_imem.sv`, and `ram_sp.sv` (Lab 8).

Use two Vivado projects, one for the single-cycle processor and one for the multicycle processor.
Both define modules named `top`, `controller`, `datapath`, and `aludec`.
