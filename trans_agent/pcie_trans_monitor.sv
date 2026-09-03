`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_trans_monitor extends uvm_monitor;
  `uvm_component_utils(pcie_trans_monitor)

  virtual pcie_if vif;
  pcie_trans_agent_config agt_cnfg;
  uvm_analysis_port#(pcie_trans_seq_item) mon_port;

  `define TMON_IF vif.TRANS_MONITOR_MODPORT.trans_monitor_cb

  function new(string name = "pcie_trans_monitor", uvm_component parent);
    super.new(name, parent);
    mon_port = new("mon_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_trans_agent_config)::get(this, "", "agt_cnfg", agt_cnfg))
      `uvm_fatal(get_full_name(), "trans monitor config not found")
  endfunction

  function void connect_phase(uvm_phase phase);
    vif = agt_cnfg.vif;
  endfunction

  extern task run_phase(uvm_phase phase);
  extern task collect_data();
endclass

task pcie_trans_monitor::run_phase(uvm_phase phase);
  forever collect_data();
endtask

task pcie_trans_monitor::collect_data();
  pcie_trans_seq_item item;
  @(`TMON_IF);
  if (`TMON_IF.tl_req_valid && `TMON_IF.tl_req_ready) begin
    item = pcie_trans_seq_item::type_id::create("item");
    item.tlp_type = `TMON_IF.tl_req_type;
    item.addr     = `TMON_IF.tl_req_addr;
    item.wdata    = `TMON_IF.tl_req_wdata;
    item.tag      = `TMON_IF.tl_req_tag;
    mon_port.write(item);
  end
endtask
