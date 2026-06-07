# PCIe Gen4 Protocol Verification Environment

**Author:** Saravana Kumar T J A
**Role:** Design & Verification Engineer — Semiconductor
**Tools:** SystemVerilog | UVM | QuestaSim 10.4e
**Protocol:** PCIe Gen4 — 16 GT/s | 128b/130b Encoding
**GitHub:** [PCIe-Gen4-Protocol-Verification-Environment](https://github.com/sachin07sk/PCIe-Gen4-Protocol-Verification-Environment)

---

## Overview

A comprehensive **UVM-based verification environment** for PCIe Gen4 (16 GT/s) Transaction Layer Protocol compliance. The environment verifies TLP (Transaction Layer Packet) generation, routing, flow control, completion handling, and error injection across a PCIe endpoint memory device.

The environment covers:
- LTSSM link training from Detect → L0 active state
- All major TLP types: MRd, MWr, CfgRd0, CfgWr0, CplD
- Credit-based flow control (Posted, Non-Posted, Completion)
- Poisoned TLP error injection and detection
- 100% TLP type functional coverage closure

---

## PCIe Protocol Overview

### PCIe Layer Stack

```
┌─────────────────────────────────────────────────────────┐
│  Transaction Layer                                       │
│  Creates/consumes TLPs                                   │
│  MRd, MWr, CfgRd, CfgWr, Cpl, CplD                    │
├─────────────────────────────────────────────────────────┤
│  Data Link Layer                                         │
│  Reliability — ACK/NAK, retry buffer, LCRC              │
│  Flow control credits — Posted, Non-Posted, Completion  │
├─────────────────────────────────────────────────────────┤
│  Physical Layer                                          │
│  128b/130b encoding, LTSSM link training                │
│  16 GT/s per lane (Gen4)                               │
└─────────────────────────────────────────────────────────┘
```

### PCIe Generation Comparison

| Generation | Speed      | Encoding  | BW/Lane  | x16 BW   |
|-----------|------------|-----------|----------|----------|
| Gen1      | 2.5 GT/s   | 8b/10b    | 0.25 GB/s| 4 GB/s   |
| Gen2      | 5.0 GT/s   | 8b/10b    | 0.50 GB/s| 8 GB/s   |
| Gen3      | 8.0 GT/s   | 128b/130b | 0.98 GB/s| 16 GB/s  |
| **Gen4**  | **16 GT/s**| 128b/130b | 1.97 GB/s| **32 GB/s** |
| Gen5      | 32 GT/s    | 128b/130b | 3.94 GB/s| 64 GB/s  |

---

## LTSSM — Link Training State Machine

```
Power On
   ↓
DETECT       ← Check if receiver is connected (50Ω termination)
   ↓
POLLING      ← Exchange TS1/TS2 training sequences, bit lock
   ↓
CONFIGURATION← Negotiate lane count and assign lane numbers
   ↓
L0           ← FULLY OPERATIONAL — TLPs flow freely ✓
  ↙   ↘
L0s   L1     ← Power saving states
        ↓
   RECOVERY  ← Re-train after error or speed change
        ↓
        L0
```

### LTSSM State Timing in This Environment

```
Cycle →    0    2    5    8    10
           │    │    │    │    │
DETECT ────┘    │    │    │    │
POLLING    ─────┘    │    │    │
CONFIG          ─────┘    │    │
L0                   ─────┘    │
link_up=1               ───────┘ TLPs start flowing
```

---

## TLP Types Verified

| TLP Type | FMT   | Description                     | Completion |
|---------|-------|---------------------------------|------------|
| MRd     | 3DW-ND| Memory Read Request             | CplD needed|
| MWr     | 3DW-D | Memory Write                    | None (posted)|
| CfgRd0  | 3DW-ND| Config Space Read Type 0        | CplD needed|
| CfgWr0  | 3DW-D | Config Space Write Type 0       | None       |
| CplD    | 3DW-D | Completion with Data            | Response   |
| Poisoned| 3DW-D | Error injection — EP bit set    | Detected   |

### TLP Header Format (3 DWORD)

```
DWORD 0:  [31:29]=FMT  [28:24]=Type  [9:0]=Length(DWORDs)
DWORD 1:  [31:16]=Requester ID  [15:8]=Tag  [7:0]=Byte Enable
DWORD 2:  [31:0]=Address (32-bit target)

FMT[1]=0 → no data payload (MRd, CfgRd)
FMT[1]=1 → has data payload (MWr, CfgWr, CplD)
```

---

## Flow Control — Credit Based

```
3 Credit Categories:
  Posted (P)      → MWr, Msg  (no completion)
  Non-Posted (NP) → MRd, CfgRd (completion required)
  Completion (C)  → CplD, Cpl

Before sending TLP:
  Sender checks: credits > 0
  If yes  → send TLP, decrement credits
  If no   → STALL (fc_stall_count incremented)

After EP processes TLP:
  EP sends UpdateFC → replenish sender credits

Initial credits in this environment:
  Posted header credits    = 64
  Non-Posted header credits= 32
  Completion header credits= 64
```

---

## UVM Testbench Architecture

```
┌─────────────────────────────────────────────────────────┐
│  pcie_test                                               │
│  ┌───────────────────────────────────────────────────┐  │
│  │  pcie_env                                         │  │
│  │  ┌──────────────────────┐  ┌──────────────────┐  │  │
│  │  │  pcie_agent          │  │  pcie_scoreboard  │  │  │
│  │  │  ┌────────────────┐  │  └──────────────────┘  │  │
│  │  │  │ pcie_sequencer │  │  ┌──────────────────┐  │  │
│  │  │  └───────┬────────┘  │  │  pcie_coverage    │  │  │
│  │  │          │            │  └──────────────────┘  │  │
│  │  │  ┌───────▼────────┐  │                         │  │
│  │  │  │  pcie_driver   │  │                         │  │
│  │  │  └────────────────┘  │                         │  │
│  │  │  ┌────────────────┐  │                         │  │
│  │  │  │  pcie_monitor  │──┼─► ap → scoreboard       │  │
│  │  │  └────────────────┘  │       → coverage        │  │
│  │  └──────────────────────┘                         │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
              │ pcie_if (virtual interface)
    ┌─────────┴──────────┐
    │  pcie_tlp_layer.v  │ ← DUT
    │  pcie_ep_memory.v  │ ← DUT
    └────────────────────┘
```

---

## Test Sequences

| Sequence               | Description                                 |
|-----------------------|---------------------------------------------|
| pcie_memwr_seq        | Single memory write TLP                     |
| pcie_memrd_seq        | Single memory read + CplD response          |
| pcie_cfgrd_seq        | Config space read — Vendor/Device ID        |
| pcie_cfgwr_seq        | Config space write — BAR0 programming       |
| pcie_burst_wr_seq     | 4 back-to-back memory writes                |
| pcie_wr_rd_seq        | Write then read back same address           |
| pcie_poison_seq       | Inject poisoned TLP — verify detection      |
| pcie_regression_seq   | Runs all above sequences end-to-end         |

---

## Scoreboard Checks

| Check              | Condition                                  | Result |
|-------------------|---------------------------------------------|--------|
| MemWr → MemRd     | Read data must match written data           | PASS/FAIL |
| CfgRd response    | Vendor/Device ID must not be X (unknown)    | PASS/FAIL |
| Poisoned TLP      | EP flag must be detected and flagged        | PASS/FAIL |
| CplD tag match    | Completion tag must match MRd request tag   | PASS/FAIL |

---

## Functional Coverage

| Covergroup       | Bins                                         | Target |
|-----------------|----------------------------------------------|--------|
| TLP Type        | MWr, MRd, CfgRd, CfgWr, Poisoned            | 100%   |
| Burst Length    | 1 beat, 2-4 beats, 5-8 beats                | 100%   |
| Address Range   | 0x000-0x0FF, 0x100-0x1FF, 0x200-0x3FF      | 100%   |

---

## File Structure

```
pcie_verification/
├── rtl/
│   ├── pcie_ep_memory.v      PCIe Endpoint memory DUT
│   │                          — LTSSM state machine (Detect→L0)
│   │                          — 1KB BAR0 memory space
│   │                          — Config space registers
│   │                          — Flow control credit management
│   │
│   └── pcie_tlp_layer.v      TLP Layer DUT
│                               — TLP encode/decode
│                               — Flow control credit checking
│                               — Tag management (outstanding reads)
│                               — Poisoned TLP detection
│
├── tb/
│   ├── pcie_if.sv            Interface — all PCIe signals
│   │                          — driver and monitor clocking blocks
│   ├── pcie_seq_item.sv      TLP transaction item
│   │                          — constrained-random fields
│   │                          — implication constraints
│   ├── pcie_sequencer.sv     UVM sequencer
│   ├── pcie_sequences.sv     8 test sequences
│   ├── pcie_driver.sv        Drives TLPs with FC check
│   ├── pcie_monitor.sv       Captures TLPs + completions
│   ├── pcie_scoreboard.sv    Checks data integrity
│   ├── pcie_coverage.sv      TLP type + burst + address coverage
│   ├── pcie_agent.sv         Agent — drv + mon + seqr
│   ├── pcie_env.sv           Env — agent + scoreboard + coverage
│   └── pcie_test.sv          Test — starts regression sequence
│
└── sim/
    ├── pcie_top.sv           Simulation top
    │                          — clock + reset generation
    │                          — DUT instantiation
    └──                        — UVM config_db setup
```

---

## Simulation Results

```
[TOP] Reset released at t=100ns

[EP]  LTSSM: DETECT  → t=20ns
[EP]  LTSSM: POLLING → t=50ns
[EP]  LTSSM: CONFIG  → t=80ns
[EP]  LTSSM: L0      → t=100ns  link_up=1

===== PCIe Gen4 Verification Start =====

[TLP]  Sent: MWr  addr=0x000001A0 data=0xA0000000
[EP]   MemWr: addr=0x000001A0 data=0xA0000000
[TLP]  Sent: MRd  addr=0x000001A0 tag=1
[EP]   CplD: tag=1 data=0xA0000000
[SB]   PASS: mem[0x000001A0] rd=0xA0000000 exp=0xA0000000

[TLP]  Sent: CfgRd0 offset=0x00 tag=2
[EP]   CplD: tag=2 data=0x0BAD_CAFE
[SB]   PASS: CfgRd Vendor:Device=0x0BADCAFE

[POISON] Injecting POISONED TLP
[EP]     WARNING: Poisoned TLP received!
[SB]     PASS: Poisoned TLP correctly flagged

===== PCIe Gen4 Verification Done  =====

==========================================
 PCIe SCOREBOARD RESULTS
 PASSED : 18
 FAILED : 0
 STATUS : ALL CHECKS PASSED ✓
==========================================

==========================================
 PCIe COVERAGE SUMMARY
 TLP Type Coverage  : 100.0%
 Burst Len Coverage : 100.0%
 Addr Range Coverage: 87.5%
==========================================

==========================================
 PCIe MONITOR SUMMARY
 TLPs sent     : 23
 Completions   : 13
 Poisoned TLPs : 1
 FC Stalls     : 0
==========================================
```

---

*Saravana Kumar T J A — Design & Verification Engineer*
*Email: sklearn2k22@gmail.com*
*LinkedIn: linkedin.com/in/sk-212010-tja*
*GitHub: github.com/sachin07sk*
