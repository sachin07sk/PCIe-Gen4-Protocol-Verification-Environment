// ============================================
// PCIe Agent
// Contains: sequencer + driver + monitor
// Author: Saravana Kumar T J A
// ============================================
`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_agent extends uvm_agent;
    `uvm_component_utils(pcie_agent)

    pcie_sequencer sequencer;
    pcie_driver    driver;
    pcie_monitor   monitor;

    uvm_analysis_port #(pcie_seq_item) ap;

    function new(string name = "pcie_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        monitor = pcie_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = pcie_sequencer::type_id::create("sequencer", this);
            driver    = pcie_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.ap.connect(ap);
    endfunction
endclass
