`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_phy_driver extends uvm_driver#(pcie_phy_seq_item);
  `uvm_component_utils(pcie_phy_driver)
  virtual pcie_if vif;
  pcie_phy_agent_config agt_cnfg;

  `define PDRIV_IF vif.PHY_DRIVER_MODPORT.phy_driver_cb

  function new(string name = "pcie_phy_driver", uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_phy_agent_config)::get(this, "", "agt_cnfg", agt_cnfg))
      `uvm_fatal(get_full_name(), "phy driver config not found")
  endfunction
  function void connect_phase(uvm_phase phase);
    vif = agt_cnfg.vif;
  endfunction

  extern task drive_reset();
  extern task run_phase(uvm_phase phase);
  extern task drive(pcie_phy_seq_item req);
endclass

task pcie_phy_driver::drive_reset();
  `PDRIV_IF.rx_electrical_idle <= 1'b1; // Detect state expects electrical idle deasserted to proceed
endtask

task pcie_phy_driver::run_phase(uvm_phase phase);
  drive_reset();
  forever begin
    seq_item_port.get_next_item(req);
    drive(req);
    seq_item_port.item_done();
  end
endtask

// drives the PIPE-level ordered-set detect pulses that walk the partner LTSSM
// through Detect -> Polling -> Configuration -> L0 (see pcie_ltssm.v)
task pcie_phy_driver::drive(pcie_phy_seq_item req);
  @(`PDRIV_IF);
  `PDRIV_IF.rx_electrical_idle <= req.rx_electrical_idle;
  `PDRIV_IF.rx_ts1_detect      <= req.rx_ts1_detect;
  `PDRIV_IF.rx_ts2_detect      <= req.rx_ts2_detect;
  `PDRIV_IF.recovery_req       <= req.recovery_req;
  `PDRIV_IF.enter_l0s_req      <= req.enter_l0s_req;
  `PDRIV_IF.enter_l1_req       <= req.enter_l1_req;
  `PDRIV_IF.exit_lowpower      <= req.exit_lowpower;
  `uvm_info("PHY_DRV", $sformatf("drove %s", req.convert2string()), UVM_LOW)
endtask
