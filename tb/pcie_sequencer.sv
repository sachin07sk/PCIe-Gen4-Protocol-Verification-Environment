`ifndef PCIE_SEQUENCER_SV
`define PCIE_SEQUENCER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "../tb/pcie_seq_item.sv"

class pcie_sequencer extends uvm_sequencer #(pcie_seq_item);
    `uvm_component_utils(pcie_sequencer)

    function new(string name = "pcie_sequencer",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("SEQR","PCIe Sequencer built", UVM_LOW)
    endfunction

endclass

`endif
