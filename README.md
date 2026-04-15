# Logic Warriors

Logic Warriors is an FPGA-based turn-based battle game implemented in Verilog for the **Digilent Basys3** board.

## Overview

- Top-level module: `top`
- Platform clock: 100 MHz (`clk`)
- Inputs: center/up/left/right/down buttons + 16 switches
- Outputs: 16 LEDs + 4-digit seven-segment display
- Soft reset: `sw[15]`

Each side starts with 9 HP. The player and CPU each pick an action per round, gains/losses are applied, and the game ends when either side's HP reaches 0.

## Player Controls

- **BTN C**: Start / pause / resume game, and restart after game over
- **BTN L**: Action **A** (Attack)
- **BTN R**: Action **B** (Block)
- **BTN U**: Action **H** (Heal)
- **BTN D**: Action **I** (Idle)
- **SW15**: Reset

## Display/LED Behavior

Seven-segment display modes:

1. `GO` (ready)
2. Action view: `PlayerHP PlayerAction CPUAction CPUHP`
3. Result view: signed gain for player and CPU
4. Game over: win/lose indicator

LED mapping:

- `led[3:0]`: Player HP
- `led[7:4]`: CPU HP
- `led[8]`: Running state
- `led[9]`: Winner flag

## Key Source Files

- `logic_warriors.srcs/sources_1/imports/game_v33.srcs/sources_1/new/top.v`
- `logic_warriors.srcs/sources_1/imports/game_v33.srcs/sources_1/new/fsm_blocks.v`
- `logic_warriors.srcs/sources_1/imports/game_v33.srcs/sources_1/new/cpu_ai_rules.v`
- `logic_warriors.srcs/sources_1/imports/game_v33.srcs/sources_1/new/gain_table.v`
- `logic_warriors.srcs/sources_1/imports/game_v33.srcs/sources_1/new/display_mux.v`
- `logic_warriors.srcs/constrs_1/imports/new/logic_warriors_basys3.xdc`
- `logic_warriors.xpr` (Vivado project)

## Build / Program (Vivado)

1. Open `logic_warriors.xpr` in Vivado.
2. Run **Synthesis**.
3. Run **Implementation**.
4. Generate bitstream.
5. Program Basys3 device.

## Simulation

Testbench file:

- `logic_warriors.srcs/sources_1/imports/game_v33.srcs/sources_1/new/tb_game_cu_fsm.v`

Example with Icarus Verilog:

```bash
iverilog -g2012 -o tb.out \
  $(find logic_warriors.srcs/sources_1/imports/game_v33.srcs/sources_1/new -name '*.v' ! -name 'tb_*') \
  logic_warriors.srcs/sources_1/imports/game_v33.srcs/sources_1/new/tb_game_cu_fsm.v
vvp tb.out
```

> Note: Vivado/Icarus tools were not available in this execution environment, so commands above are provided for local use.
