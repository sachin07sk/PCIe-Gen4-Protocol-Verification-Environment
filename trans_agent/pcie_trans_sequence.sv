/ base sequence + narrow scenario subclasses (matches lightweight/full-tier
// "uvm_do_with per scenario" convention)
`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_trans_base_seq extends uvm_sequence#(pcie_trans_seq_item);
  `uvm_object_utils(pcie_trans_base_seq)
  function new(string name = "pcie_trans_base_seq");
    super.new(name);
  endfunction
endclass

// seq_1: single memory write followed by a read to the same address
class pcie_trans_wr_rd_seq extends pcie_trans_base_seq;
  `uvm_object_utils(pcie_trans_wr_rd_seq)
  rand bit [31:0] addr;
  rand bit [31:0] wdata;
  function new(string name = "pcie_trans_wr_rd_seq");
    super.new(name);
  endfunction
  task body();
    pcie_trans_seq_item item;
    `uvm_do_with(item, { tlp_type == `TLP_MWR; local::addr == addr; wdata == local::wdata; })
    `uvm_do_with(item, { tlp_type == `TLP_MRD; local::addr == addr; })
  endtask
endclass

// seq_2: back-to-back posted writes, no idle cycles (stresses replay buffer depth)
class pcie_trans_burst_wr_seq extends pcie_trans_base_seq;
  `uvm_object_utils(pcie_trans_burst_wr_seq)
  rand int unsigned burst_len;
  constraint c_len { burst_len inside {[4:32]}; }
  function new(string name = "pcie_trans_burst_wr_seq");
    super.new(name);
  endfunction
  task body();
    pcie_trans_seq_item item;
    repeat (burst_len)
      `uvm_do_with(item, { tlp_type == `TLP_MWR; })
  endtask
endclass

// seq_3: config read/write to exercise the config_agent-adjacent path via TL
class pcie_trans_cfg_access_seq extends pcie_trans_base_seq;
  `uvm_object_utils(pcie_trans_cfg_access_seq)
  function new(string name = "pcie_trans_cfg_access_seq");
    super.new(name);
  endfunction
  task body();
    pcie_trans_seq_item item;
    `uvm_do_with(item, { tlp_type == `TLP_CFG_WR0; })
    `uvm_do_with(item, { tlp_type == `TLP_CFG_RD0; })
  endtask
endclass
