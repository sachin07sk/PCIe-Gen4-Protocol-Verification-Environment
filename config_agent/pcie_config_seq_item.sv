`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_config_seq_item extends uvm_sequence_item;
  rand bit         is_write;
  rand bit [11:0]  addr;
  rand bit [31:0]  wdata;
       bit [31:0]  rdata;

  `uvm_object_utils_begin(pcie_config_seq_item)
    `uvm_field_int(is_write, UVM_ALL_ON)
    `uvm_field_int(addr,     UVM_ALL_ON)
    `uvm_field_int(wdata,    UVM_ALL_ON)
    `uvm_field_int(rdata,    UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pcie_config_seq_item");
    super.new(name);
  endfunction
  function string convert2string();
    return $sformatf("wr=%0d addr=%0h wdata=%0h rdata=%0h", is_write, addr, wdata, rdata);
  endfunction
endclass
