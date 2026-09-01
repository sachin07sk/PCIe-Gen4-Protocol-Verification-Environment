`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_flow_ctrl_base_seq extends uvm_sequence#(pcie_flow_ctrl_seq_item);
  `uvm_object_utils(pcie_flow_ctrl_base_seq)
  function new(string name = "pcie_flow_ctrl_base_seq");
    super.new(name);
  endfunction
endclass

// seq_1: default FC-INIT advertisement (generous credits, non-blocking case)
class pcie_flow_ctrl_init_seq extends pcie_flow_ctrl_base_seq;
  `uvm_object_utils(pcie_flow_ctrl_init_seq)
  function new(string name = "pcie_flow_ctrl_init_seq");
    super.new(name);
  endfunction
  task body();
    pcie_flow_ctrl_seq_item item;
    `uvm_do_with(item, { is_init == 1'b1; ph == 8'd32; pd == 8'd64;
                          nph == 8'd16; npd == 8'd16; cplh == 8'd32; cpld == 8'd64; })
  endtask
endclass

// seq_2: starved credits -- FC-INIT with minimal (near-zero) credits, to drive
// the tx_grant-withheld corner case in pcie_flow_ctrl.v
class pcie_flow_ctrl_starved_seq extends pcie_flow_ctrl_base_seq;
  `uvm_object_utils(pcie_flow_ctrl_starved_seq)
  function new(string name = "pcie_flow_ctrl_starved_seq");
    super.new(name);
  endfunction
  task body();
    pcie_flow_ctrl_seq_item item;
    `uvm_do_with(item, { is_init == 1'b1; ph == 8'd1; pd == 8'd1;
                          nph == 8'd1; npd == 8'd1; cplh == 8'd1; cpld == 8'd1; })
  endtask
endclass
