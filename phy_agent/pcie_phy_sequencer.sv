`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_phy_sequencer extends uvm_sequencer#(pcie_phy_seq_item);
  `uvm_component_utils(pcie_phy_sequencer)
  function new(string name = "pcie_phy_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
