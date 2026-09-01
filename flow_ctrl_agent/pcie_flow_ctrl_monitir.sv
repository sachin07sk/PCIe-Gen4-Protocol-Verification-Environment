`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_flow_ctrl_monitor extends uvm_monitor;
  `uvm_component_utils(pcie_flow_ctrl_monitor)

  virtual pcie_if vif;
  pcie_flow_ctrl_agent_config agt_cnfg;
  uvm_analysis_port#(pcie_flow_ctrl_seq_item) mon_port;

  `define FCMON_IF vif.FLOW_CTRL_MONITOR_MODPORT.flow_ctrl_monitor_cb

  function new(string name = "pcie_flow_ctrl_monitor", uvm_component parent);
    super.new(name, parent);
    mon_port = new("mon_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_flow_ctrl_agent_config)::get(this, "", "agt_cnfg", agt_cnfg))
      `uvm_fatal(get_full_name(), "flow_ctrl monitor config not found")
  endfunction

  function void connect_phase(uvm_phase phase);
    vif = agt_cnfg.vif;
  endfunction

  extern task run_phase(uvm_phase phase);
  extern task collect_data();
endclass

task pcie_flow_ctrl_monitor::run_phase(uvm_phase phase);
  forever collect_data();
endtask

// AVOID hardcoded literals scattered through the task body -- credit field
// widths come from pcie_pkg.vh, not magic numbers
task pcie_flow_ctrl_monitor::collect_data();
  pcie_flow_ctrl_seq_item item;
  @(`FCMON_IF);
  if (`FCMON_IF.fc_init_valid) begin
    item = pcie_flow_ctrl_seq_item::type_id::create("item");
    item.is_init = 1'b1;
    item.ph   = `FCMON_IF.fc_ph;
    item.pd   = `FCMON_IF.fc_pd;
    item.nph  = `FCMON_IF.fc_nph;
    item.npd  = `FCMON_IF.fc_npd;
    item.cplh = `FCMON_IF.fc_cplh;
    item.cpld = `FCMON_IF.fc_cpld;
    mon_port.write(item);
  end
endtask
