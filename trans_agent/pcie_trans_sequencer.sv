`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_trans_sequencer extends uvm_sequencer#(pcie_trans_seq_item);
  `uvm_component_utils(pcie_trans_sequencer)
  function new(string name = "pcie_trans_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
