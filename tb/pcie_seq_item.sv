`ifndef PCIE_SEQ_ITEM_SV
`define PCIE_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_seq_item extends uvm_sequence_item;
    `uvm_object_utils(pcie_seq_item)

    // Operation type
    typedef enum {
        OP_MEMWR,
        OP_MEMRD,
        OP_CFGRD0,
        OP_CFGWR0,
        OP_POISONED
    } op_type_e;

    rand op_type_e   op_type;
    rand logic [2:0] fmt;
    rand logic [4:0] tlp_type;
    rand logic [9:0] length;
    rand logic [31:0] address;
    rand logic [31:0] data [];
    rand logic [7:0]  tag;
    rand logic [2:0]  tc;
    rand logic        poisoned;

    // Response
    logic [31:0] cpl_data [];
    logic [2:0]  cpl_status;

    // Constraints — simple, no if-begin-end inside constraint
    constraint c_addr_align  { address[1:0] == 2'b00; }
    constraint c_addr_range  { address <= 32'h000003FF; }
    constraint c_length      { length inside {[10'd1:10'd8]}; }
    constraint c_data_size   { data.size() == length; }
    constraint c_tc          { tc == 3'b000; }
    constraint c_poison_dist { poisoned dist {0 := 90, 1 := 10}; }

    // fmt constraint — separate per op_type
    constraint c_fmt_memwr  {
        (op_type == OP_MEMWR)    -> (fmt == 3'b010 && tlp_type == 5'b00000);
    }
    constraint c_fmt_memrd  {
        (op_type == OP_MEMRD)    -> (fmt == 3'b000 && tlp_type == 5'b00000);
    }
    constraint c_fmt_cfgrd  {
        (op_type == OP_CFGRD0)   -> (fmt == 3'b000 && tlp_type == 5'b00100);
    }
    constraint c_fmt_cfgwr  {
        (op_type == OP_CFGWR0)   -> (fmt == 3'b010 && tlp_type == 5'b00100);
    }
    constraint c_fmt_poison {
        (op_type == OP_POISONED) -> (fmt == 3'b010 && tlp_type == 5'b00000 && poisoned == 1'b1);
    }
    constraint c_no_poison  {
        (op_type != OP_POISONED) -> (poisoned == 1'b0);
    }

    function new(string name = "pcie_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        string s;
        s = $sformatf("OP=%s ADDR=0x%08h LEN=%0d TAG=%0d",
            op_type.name(), address, length, tag);
        if (poisoned)
            s = {s, " ***POISONED***"};
        return s;
    endfunction

endclass

`endif
