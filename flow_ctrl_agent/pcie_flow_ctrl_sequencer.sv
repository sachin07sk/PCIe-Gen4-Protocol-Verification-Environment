`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_flow_ctrl_sequencer extends uvm_sequencer #(pcie_flow_ctrl_seq_item);
  `uvm_component_utils(pcie_flow_ctrl_sequencer)
  function new(string name = "pcie_flow_ctrl_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
