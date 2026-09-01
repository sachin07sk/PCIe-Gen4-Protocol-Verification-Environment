`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_flow_ctrl_driver extends uvm_driver#(pcie_flow_ctrl_seq_item);
  `uvm_component_utils(pcie_flow_ctrl_driver)

  virtual pcie_if vif;
  pcie_flow_ctrl_agent_config agt_cnfg;

  `define FCDRIV_IF vif.FLOW_CTRL_DRIVER_MODPORT.flow_ctrl_driver_cb

  function new(string name = "pcie_flow_ctrl_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_flow_ctrl_agent_config)::get(this, "", "agt_cnfg", agt_cnfg))
      `uvm_fatal(get_full_name(), "flow_ctrl driver config not found")
  endfunction

  function void connect_phase(uvm_phase phase);
    vif = agt_cnfg.vif;
  endfunction

  extern task drive_reset();
  extern task run_phase(uvm_phase phase);
  extern task drive(pcie_flow_ctrl_seq_item req);
endclass

task pcie_flow_ctrl_driver::drive_reset();
  `FCDRIV_IF.fc_init_valid   <= 1'b0;
  `FCDRIV_IF.fc_update_valid <= 1'b0;
endtask

task pcie_flow_ctrl_driver::run_phase(uvm_phase phase);
  drive_reset();
  forever begin
    seq_item_port.get_next_item(req);
    drive(req);
    seq_item_port.item_done();
  end
endtask

// per spec section: FC-INIT (credit advertisement) must complete before any
// TLP may be transmitted -- driven once per link-up here (see Known
// Limitations: multi-VC FC-INIT sequencing not modeled)
task pcie_flow_ctrl_driver::drive(pcie_flow_ctrl_seq_item req);
  @(`FCDRIV_IF);
  `FCDRIV_IF.fc_init_valid   <= req.is_init;
  `FCDRIV_IF.fc_update_valid <= !req.is_init;
  `FCDRIV_IF.fc_ph   <= req.ph;
  `FCDRIV_IF.fc_pd   <= req.pd;
  `FCDRIV_IF.fc_nph  <= req.nph;
  `FCDRIV_IF.fc_npd  <= req.npd;
  `FCDRIV_IF.fc_cplh <= req.cplh;
  `FCDRIV_IF.fc_cpld <= req.cpld;
  @(`FCDRIV_IF);
  `FCDRIV_IF.fc_init_valid   <= 1'b0;
  `FCDRIV_IF.fc_update_valid <= 1'b0;
  `uvm_info("FC_DRV", $sformatf("drove %s", req.convert2string()), UVM_LOW)
endtask
