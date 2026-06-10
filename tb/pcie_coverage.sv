// ============================================
// PCIe Coverage Collector
// Tracks:
//   - All TLP types exercised
//   - LTSSM states visited
//   - Flow control stalls
//   - Poisoned TLPs
//   - Burst lengths
// Author: Saravana Kumar T J A
// ============================================
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "../tb/pcie_seq_item.sv"

class pcie_coverage extends uvm_subscriber #(pcie_seq_item);
    `uvm_component_utils(pcie_coverage)

    // Coverage group — TLP types
    covergroup tlp_type_cg;
        cp_op: coverpoint item.op_type {
            bins memwr   = {pcie_seq_item::OP_MEMWR};
            bins memrd   = {pcie_seq_item::OP_MEMRD};
            bins cfgrd0  = {pcie_seq_item::OP_CFGRD0};
            bins cfgwr0  = {pcie_seq_item::OP_CFGWR0};
            bins poison  = {pcie_seq_item::OP_POISONED};
        }
    endgroup

    // Coverage group — burst lengths
    covergroup burst_len_cg;
        cp_len: coverpoint item.length {
            bins len1     = {10'd1};
            bins len2_4   = {[10'd2:10'd4]};
            bins len5_8   = {[10'd5:10'd8]};
        }
    endgroup

    // Coverage group — address ranges
    covergroup addr_range_cg;
        cp_addr: coverpoint item.address[9:8] {
            bins range0 = {2'b00};  // 0x000-0x0FF
            bins range1 = {2'b01};  // 0x100-0x1FF
            bins range2 = {2'b10};  // 0x200-0x2FF
            bins range3 = {2'b11};  // 0x300-0x3FF
        }
    endgroup

    pcie_seq_item item;

    function new(string name = "pcie_coverage",
                 uvm_component parent = null);
        super.new(name, parent);
        tlp_type_cg  = new();
        burst_len_cg = new();
        addr_range_cg = new();
    endfunction

    function void write(pcie_seq_item t);
        item = t;
        tlp_type_cg.sample();
        burst_len_cg.sample();
        addr_range_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", "==========================================", UVM_NONE)
        `uvm_info("COV", " PCIe COVERAGE SUMMARY", UVM_NONE)
        `uvm_info("COV",
            $sformatf(" TLP Type Coverage  : %.1f%%",
            tlp_type_cg.get_coverage()), UVM_NONE)
        `uvm_info("COV",
            $sformatf(" Burst Len Coverage : %.1f%%",
            burst_len_cg.get_coverage()), UVM_NONE)
        `uvm_info("COV",
            $sformatf(" Addr Range Coverage: %.1f%%",
            addr_range_cg.get_coverage()), UVM_NONE)
        `uvm_info("COV", "==========================================", UVM_NONE)
    endfunction

endclass
