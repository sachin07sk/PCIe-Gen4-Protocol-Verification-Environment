`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_config_base_seq extends uvm_sequence#(pcie_config_seq_item);
  `uvm_object_utils(pcie_config_base_seq)
  function new(string name = "pcie_config_base_seq");
    super.new(name);
  endfunction
endclass

// seq_1: read Vendor/Device ID (offset 0x00) -- baseline enumeration check
class pcie_config_read_vid_seq extends pcie_config_base_seq;
  `uvm_object_utils(pcie_config_read_vid_seq)
  function new(string name = "pcie_config_read_vid_seq");
    super.new(name);
  endfunction
  task body();
    pcie_config_seq_item item;
    `uvm_do_with(item, { is_write == 1'b0; addr == 12'h000; })
  endtask
endclass

// seq_2: BAR0 program then read-back
class pcie_config_bar_program_seq extends pcie_config_base_seq;
  `uvm_object_utils(pcie_config_bar_program_seq)
  rand bit [31:0] bar_val;
  function new(string name = "pcie_config_bar_program_seq");
    super.new(name);
  endfunction
  task body();
    pcie_config_seq_item item;
    `uvm_do_with(item, { is_write == 1'b1; addr == 12'h010; wdata == local::bar_val; })
    `uvm_do_with(item, { is_write == 1'b0; addr == 12'h010; })
  endtask
endclass
