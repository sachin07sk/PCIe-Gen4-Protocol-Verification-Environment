`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_phy_monitor extends uvm_monitor;
  `uvm_component_utils(pcie_phy_monitor)
  virtual pcie_if vif;
  pcie_phy_agent_config agt_cnfg;
  uvm_analysis_port#(pcie_phy_seq_item) mon_port;

  `define PMON_IF vif.PHY_MONITOR_MODPORT.phy_monitor_cb

  function new(string name = "pcie_phy_monitor", uvm_component parent);
    super.new(name, parent);
    mon_port = new("mon_port", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_phy_agent_config)::get(this, "", "agt_cnfg", agt_cnfg))
      `uvm_fatal(get_full_name(), "phy monitor config not found")
  endfunction
  function void connect_phase(uvm_phase phase);
    vif = agt_cnfg.vif;
  endfunction

  extern task run_phase(uvm_phase phase);
  extern task collect_data();
endclass

task pcie_phy_monitor::run_phase(uvm_phase phase);
  forever collect_data();
endtask

// samples LTSSM state transitions -- used by the scoreboard/coverage to check
// link training reaches L0 within a bounded number of cycles
task pcie_phy_monitor::collect_data();
  pcie_phy_seq_item item;
  @(`PMON_IF);
  item = pcie_phy_seq_item::type_id::create("item");
  item.rx_ts1_detect      = `PMON_IF.rx_ts1_detect;
  item.rx_ts2_detect      = `PMON_IF.rx_ts2_detect;
  item.rx_electrical_idle = 1'b0;
  mon_port.write(item);
endtask
