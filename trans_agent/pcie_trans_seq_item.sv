`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_trans_seq_item extends uvm_sequence_item;

  rand bit [7:0]  tlp_type;   // `TLP_MRD / `TLP_MWR / `TLP_CFG_* (see pcie_pkg.vh)
  rand bit [31:0] addr;
  rand bit [31:0] wdata;
  rand bit [3:0]  be;
  rand bit [9:0]  tag;
       bit        cpl_valid;
       bit [31:0] cpl_data;
       bit [1:0]  cpl_status;

  `uvm_object_utils_begin(pcie_trans_seq_item)
    `uvm_field_int(tlp_type,   UVM_ALL_ON)
    `uvm_field_int(addr,       UVM_ALL_ON)
    `uvm_field_int(wdata,      UVM_ALL_ON)
    `uvm_field_int(be,         UVM_ALL_ON)
    `uvm_field_int(tag,        UVM_ALL_ON)
    `uvm_field_int(cpl_valid,  UVM_ALL_ON)
    `uvm_field_int(cpl_data,   UVM_ALL_ON)
    `uvm_field_int(cpl_status, UVM_ALL_ON)
  `uvm_object_utils_end

  constraint c_valid_type {
    tlp_type inside {`TLP_MRD, `TLP_MWR, `TLP_CFG_RD0, `TLP_CFG_WR0,
                      `TLP_CFG_RD1, `TLP_CFG_WR1};
  }

  function new(string name = "pcie_trans_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("type=%0h addr=%0h wdata=%0h tag=%0h cpl=%0d/%0h/%0d",
                      tlp_type, addr, wdata, tag, cpl_valid, cpl_data, cpl_status);
  endfunction

endclass
