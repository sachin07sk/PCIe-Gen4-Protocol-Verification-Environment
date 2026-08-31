`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_config_driver extends uvm_driver#(pcie_config_seq_item);
  `uvm_component_utils(pcie_config_driver)
  virtual pcie_if vif;
  pcie_config_agent_config agt_cnfg;

  `define CDRIV_IF vif.CONFIG_DRIVER_MODPORT.config_driver_cb

  function new(string name = "pcie_config_driver", uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_config_agent_config)::get(this, "", "agt_cnfg", agt_cnfg))
      `uvm_fatal(get_full_name(), "config driver config not found")
  endfunction
  function void connect_phase(uvm_phase phase);
    vif = agt_cnfg.vif;
  endfunction

  extern task drive_reset();
  extern task run_phase(uvm_phase phase);
  extern task drive(pcie_config_seq_item req);
endclass

task pcie_config_driver::drive_reset();
  `CDRIV_IF.cfg_wr_valid <= 1'b0;
  `CDRIV_IF.cfg_rd_valid <= 1'b0;
endtask

task pcie_config_driver::run_phase(uvm_phase phase);
  drive_reset();
  forever begin
    seq_item_port.get_next_item(req);
    drive(req);
    seq_item_port.item_done();
  end
endtask

task pcie_config_driver::drive(pcie_config_seq_item req);
  @(`CDRIV_IF);
  `CDRIV_IF.cfg_addr <= req.addr;
  if (req.is_write) begin
    `CDRIV_IF.cfg_wr_valid <= 1'b1;
    `CDRIV_IF.cfg_wdata    <= req.wdata;
    do @(`CDRIV_IF); while (!`CDRIV_IF.cfg_wr_done);
    `CDRIV_IF.cfg_wr_valid <= 1'b0;
  end else begin
    `CDRIV_IF.cfg_rd_valid <= 1'b1;
    do @(`CDRIV_IF); while (!`CDRIV_IF.cfg_rd_done);
    req.rdata = `CDRIV_IF.cfg_rdata;
    `CDRIV_IF.cfg_rd_valid <= 1'b0;
  end
  `uvm_info("CFG_DRV", $sformatf("drove %s", req.convert2string()), UVM_LOW)
endtask
