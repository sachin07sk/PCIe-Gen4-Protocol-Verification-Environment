`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_config_monitor extends uvm_monitor;
  `uvm_component_utils(pcie_config_monitor)
  virtual pcie_if vif;
  pcie_config_agent_config agt_cnfg;
  uvm_analysis_port#(pcie_config_seq_item) mon_port;

  `define CMON_IF vif.CONFIG_MONITOR_MODPORT.config_monitor_cb

  function new(string name = "pcie_config_monitor", uvm_component parent);
    super.new(name, parent);
    mon_port = new("mon_port", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_config_agent_config)::get(this, "", "agt_cnfg", agt_cnfg))
      `uvm_fatal(get_full_name(), "config monitor config not found")
  endfunction
  function void connect_phase(uvm_phase phase);
    vif = agt_cnfg.vif;
  endfunction

  extern task run_phase(uvm_phase phase);
  extern task collect_data();
endclass

task pcie_config_monitor::run_phase(uvm_phase phase);
  forever collect_data();
endtask

task pcie_config_monitor::collect_data();
  pcie_config_seq_item item;
  @(`CMON_IF);
  if (`CMON_IF.cfg_wr_done || `CMON_IF.cfg_rd_done) begin
    item = pcie_config_seq_item::type_id::create("item");
    item.is_write = `CMON_IF.cfg_wr_done;
    item.addr     = `CMON_IF.cfg_addr;
    item.wdata    = `CMON_IF.cfg_wdata;
    item.rdata    = `CMON_IF.cfg_rdata;
    mon_port.write(item);
  end
endtask
