// ============================================
// PCIe Simulation Top
// Connects DUT + Interface + UVM TB
// ============================================
`include "uvm_macros.svh"
import uvm_pkg::*;

// 1. Compile the static types and configuration packages first
`include "../tb/pcie_pkg.sv"
`include "../tb/pcie_seq_item.sv"

// 2. Compile execution infrastructure
`include "../tb/pcie_sequencer.sv"
`include "../tb/pcie_sequences.sv"
`include "../tb/pcie_driver.sv"
`include "../tb/pcie_monitor.sv"
`include "../tb/pcie_scoreboard.sv"
`include "../tb/pcie_coverage.sv"

// 3. Compile structural hierarchy containers last
`include "../tb/pcie_agent.sv"
`include "../tb/pcie_env.sv"
`include "../tb/pcie_test.sv"

module pcie_top;
// ... (Your port assignments and module bindings stay exactly the same)
