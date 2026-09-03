`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_trans_driver extends uvm_driver#(pcie_trans_seq_item);
  `uvm_component_utils(pcie_trans_driver)

  virtual pcie_if vif;
  pcie_trans_agent_config agt_cnfg;

  `define TDRIV_IF vif.TRANS_DRIVER_MODPORT.trans_driver_cb

  function new(string name = "pcie_trans_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_trans_agent_config)::get(this, "", "agt_cnfg", agt_cnfg))
      `uvm_fatal(get_full_name(), "trans driver config not found")
  endfunction

  function void connect_phase(uvm_phase phase);
    vif = agt_cnfg.vif;
  endfunction

  extern task drive_reset();
  extern task run_phase(uvm_phase phase);
  extern task drive(pcie_trans_seq_item req);

endclass

task pcie_trans_driver::drive_reset();
  `TDRIV_IF.tl_req_valid <= 1'b0;
endtask

task pcie_trans_driver::run_phase(uvm_phase phase);
  drive_reset();
  forever begin
    seq_item_port.get_next_item(req);
    drive(req);
    seq_item_port.item_done();
  end
endtask

// per spec section: request/completion handshake -- assert req_valid+fields,
// wait for req_ready, then (for non-posted) wait for the matching completion
task pcie_trans_driver::drive(pcie_trans_seq_item req);
  @(`TDRIV_IF);
  `TDRIV_IF.tl_req_valid <= 1'b1;
  `TDRIV_IF.tl_req_type  <= req.tlp_type;
  `TDRIV_IF.tl_req_addr  <= req.addr;
  `TDRIV_IF.tl_req_wdata <= req.wdata;
  `TDRIV_IF.tl_req_tag   <= req.tag;
  do @(`TDRIV_IF); while (!`TDRIV_IF.tl_req_ready);
  `TDRIV_IF.tl_req_valid <= 1'b0;

  if (req.tlp_type inside {`TLP_MRD, `TLP_CFG_RD0, `TLP_CFG_RD1}) begin
    do @(`TDRIV_IF); while (!`TDRIV_IF.tl_cpl_valid || `TDRIV_IF.tl_cpl_tag !== req.tag);
    req.cpl_valid  = 1'b1;
    req.cpl_data   = `TDRIV_IF.tl_cpl_data;
    req.cpl_status = `TDRIV_IF.tl_cpl_status;
  end
  `uvm_info("TRANS_DRV", $sformatf("drove %s", req.convert2string()), UVM_LOW)
endtask
