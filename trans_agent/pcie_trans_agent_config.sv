`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_trans_agent_config extends uvm_object;
  `uvm_object_utils(pcie_trans_agent_config)

  virtual pcie_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  function new(string name = "pcie_trans_agent_config");
    super.new(name);
  endfunction
endclass
