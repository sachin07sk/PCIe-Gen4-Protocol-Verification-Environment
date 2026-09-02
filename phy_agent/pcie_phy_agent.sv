`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_phy_agent extends uvm_agent;
  `uvm_component_utils(pcie_phy_agent)
  pcie_phy_agent_config agt_cnfg;
  pcie_phy_driver        driv;
  pcie_phy_monitor       mon;
  pcie_phy_sequencer     seqr;

  function new(string name = "pcie_phy_agent", uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = pcie_phy_monitor::type_id::create("mon", this);
    if (!uvm_config_db#(pcie_phy_agent_config)::get(this, "", "agt_cnfg", agt_cnfg))
      `uvm_fatal(get_full_name(), "phy agent config not found")
    if (agt_cnfg.is_active == UVM_ACTIVE) begin
      seqr = pcie_phy_sequencer::type_id::create("seqr", this);
      driv = pcie_phy_driver::type_id::create("driv", this);
    end
  endfunction
  function void connect_phase(uvm_phase phase);
    if (agt_cnfg.is_active == UVM_ACTIVE)
      driv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
