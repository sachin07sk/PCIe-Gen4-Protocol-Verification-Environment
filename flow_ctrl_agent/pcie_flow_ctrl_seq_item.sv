`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_flow_ctrl_seq_item extends uvm_sequence_item;

  rand bit         is_init;      // 1 = FC-INIT advertisement, 0 = FC update
  rand bit [7:0]   ph, pd, nph, npd, cplh, cpld;

  `uvm_object_utils_begin(pcie_flow_ctrl_seq_item)
    `uvm_field_int(is_init, UVM_ALL_ON)
    `uvm_field_int(ph,      UVM_ALL_ON)
    `uvm_field_int(pd,      UVM_ALL_ON)
    `uvm_field_int(nph,     UVM_ALL_ON)
    `uvm_field_int(npd,     UVM_ALL_ON)
    `uvm_field_int(cplh,    UVM_ALL_ON)
    `uvm_field_int(cpld,    UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pcie_flow_ctrl_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("init=%0d ph=%0d pd=%0d nph=%0d npd=%0d cplh=%0d cpld=%0d",
                      is_init, ph, pd, nph, npd, cplh, cpld);
  endfunction
endclass
