`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_trans_agent extends uvm_agent;
  `uvm_component_utils(pcie_trans_agent)

  pcie_trans_agent_config agt_cnfg;
  pcie_trans_driver        driv;
  pcie_trans_monitor       mon;
  pcie_trans_sequencer     seqr;

  function new(string name = "pcie_trans_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = pcie_trans_monitor::type_id::create("mon", this);
    if (!uvm_config_db#(pcie_trans_agent_config)::get(this, "", "agt_cnfg", agt_cnfg))
      `uvm_fatal(get_full_name(), "trans agent config not found")
    if (agt_cnfg.is_active == UVM_ACTIVE) begin
      seqr = pcie_trans_sequencer::type_id::create("seqr", this);
      driv = pcie_trans_driver::type_id::create("driv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (agt_cnfg.is_active == UVM_ACTIVE)
      driv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
