# Synchronous FIFO — Verilog RTL Design

A parameterised, single-clock (synchronous) First-In-First-Out (FIFO) buffer written in Verilog, with a complete self-checking testbench.

---

## Block Diagram

```
          ┌─────────────────────────────────┐
  wr_en ──►                                 ├──► full
data_in ──►        sync_fifo                ├──► empty
  rd_en ──►     (mem, wr_ptr, rd_ptr,       ├──► data_out
    clk ──►      count)                     ├──► fifo_count
    rst ──►                                 │
          └─────────────────────────────────┘
```

---

## Parameters

| Parameter    | Default | Description                              |
|:-------------|:-------:|:-----------------------------------------|
| `DATA_WIDTH` | 8       | Bit-width of each data word              |
| `FIFO_DEPTH` | 8       | Number of storage locations              |
| `ADDR_WIDTH` | 3       | `ceil(log2(FIFO_DEPTH))`                 |

---

## Port List

| Port         | Dir    | Width            | Description              |
|:-------------|:-------|:-----------------|:-------------------------|
| `clk`        | input  | 1                | System clock             |
| `rst`        | input  | 1                | Synchronous active-high reset |
| `wr_en`      | input  | 1                | Write enable             |
| `rd_en`      | input  | 1                | Read enable              |
| `data_in`    | input  | `DATA_WIDTH`     | Write data               |
| `data_out`   | output | `DATA_WIDTH`     | Read data (registered)   |
| `full`       | output | 1                | FIFO full flag           |
| `empty`      | output | 1                | FIFO empty flag          |
| `fifo_count` | output | `ADDR_WIDTH+1`   | Number of valid entries  |

---

## Features

- **Parameterised** — change width and depth without editing RTL logic.
- **Safe simultaneous R/W** — when both `wr_en` and `rd_en` are asserted together the FIFO accepts one entry and releases one entry in the same cycle; the count stays constant.
- **Overflow / Underflow protection** — hardware ignores writes when `full`, ignores reads when `empty`.
- **Explicit pointer wrap-around** — works correctly for any `FIFO_DEPTH`, not just powers of two.

---

## Testbench Coverage

| Test Case                     | What it verifies                          |
|:------------------------------|:------------------------------------------|
| Reset                         | All pointers and count cleared to zero    |
| Sequential write × 5         | Data stored in order; count increments    |
| Sequential read × 5          | Data returned in FIFO order; count decrements |
| Simultaneous Read & Write     | Count unchanged; correct data transfer    |
| Overflow attempt              | Write ignored when `full = 1`             |
| Underflow attempt             | Read ignored when `empty = 1`             |

---

## Simulation

### Using Icarus Verilog (iverilog) — recommended for Mac/Linux

```bash
# Compile
iverilog -o fifo_sim sync_fifo.v tb_sync_fifo.v

# Run simulation (prints $monitor output to terminal)
vvp fifo_sim

# Open waveform (requires GTKWave)
gtkwave fifo_wave.vcd
```

### Using EDA Playground (browser — no install required)

1. Go to [https://www.edaplayground.com](https://www.edaplayground.com)
2. Paste `sync_fifo.v` into the **Design** pane.
3. Paste `testbench_sync_fifo.v` into the **Testbench** pane.
4. Select **Icarus Verilog 12** as the simulator.
5. Click **Run**.

---

## File Structure

```
sync_fifo/
├── sync_fifo.v       # RTL design
├── tb_sync_fifo.v    # Testbench
└── README.md
```

---

## Author

**SIDDHANT SRIVASTAVA** — B.Tech ECE, KNIT Sultanpur (2022–2026)
