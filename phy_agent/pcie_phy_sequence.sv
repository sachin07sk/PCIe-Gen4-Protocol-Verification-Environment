`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_phy_base_seq extends uvm_sequence#(pcie_phy_seq_item);
  `uvm_object_utils(pcie_phy_base_seq)
  function new(string name = "pcie_phy_base_seq");
    super.new(name);
  endfunction
endclass

// seq_1: normal link-up -- deassert electrical idle, then pulse TS1/TS2 until
// the partner's LTSSM reaches L0 (see pcie_ltssm.v POLLING/CONFIG states)
class pcie_phy_linkup_seq extends pcie_phy_base_seq;
  `uvm_object_utils(pcie_phy_linkup_seq)
  function new(string name = "pcie_phy_linkup_seq");
    super.new(name);
  endfunction
  task body();
    pcie_phy_seq_item item;
    `uvm_do_with(item, { rx_electrical_idle == 1'b0; rx_ts1_detect == 1'b0; rx_ts2_detect == 1'b0; })
    repeat (20)
      `uvm_do_with(item, { rx_electrical_idle == 1'b0; rx_ts1_detect == 1'b1; rx_ts2_detect == 1'b0; })
    repeat (10)
      `uvm_do_with(item, { rx_electrical_idle == 1'b0; rx_ts1_detect == 1'b0; rx_ts2_detect == 1'b1; })
  endtask
endclass

// seq_2: forced recovery entry -- exercises LTSSM Recovery re-equalization path
class pcie_phy_recovery_seq extends pcie_phy_base_seq;
  `uvm_object_utils(pcie_phy_recovery_seq)
  function new(string name = "pcie_phy_recovery_seq");
    super.new(name);
  endfunction
  task body();
    pcie_phy_seq_item item;
    `uvm_do_with(item, { recovery_req == 1'b1; })
    `uvm_do_with(item, { recovery_req == 1'b0; rx_ts1_detect == 1'b1; })
  endtask
endclass
