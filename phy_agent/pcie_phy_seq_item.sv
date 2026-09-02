`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_phy_seq_item extends uvm_sequence_item;
  rand bit rx_ts1_detect, rx_ts2_detect, rx_electrical_idle, recovery_req;
  rand bit enter_l0s_req, enter_l1_req, exit_lowpower;

  `uvm_object_utils_begin(pcie_phy_seq_item)
    `uvm_field_int(rx_ts1_detect,       UVM_ALL_ON)
    `uvm_field_int(rx_ts2_detect,       UVM_ALL_ON)
    `uvm_field_int(rx_electrical_idle,  UVM_ALL_ON)
    `uvm_field_int(recovery_req,        UVM_ALL_ON)
    `uvm_field_int(enter_l0s_req,       UVM_ALL_ON)
    `uvm_field_int(enter_l1_req,        UVM_ALL_ON)
    `uvm_field_int(exit_lowpower,       UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pcie_phy_seq_item");
    super.new(name);
  endfunction
  function string convert2string();
    return $sformatf("ts1=%0d ts2=%0d eidle=%0d rec=%0d",
                      rx_ts1_detect, rx_ts2_detect, rx_electrical_idle, recovery_req);
  endfunction
endclass
