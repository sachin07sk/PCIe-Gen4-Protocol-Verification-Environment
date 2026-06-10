// ============================================
// PCIe Test — Top of UVM hierarchy
// Runs full regression sequence
// Author: Saravana Kumar T J A
// ============================================
`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_test extends uvm_test;
    `uvm_component_utils(pcie_test)

    pcie_env env;

    function new(string name = "pcie_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = pcie_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        pcie_regression_seq seq;
        phase.raise_objection(this);
        `uvm_info("TEST", "===== PCIe Gen4 Verification Start =====", UVM_NONE)

        seq = pcie_regression_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);

        `uvm_info("TEST", "===== PCIe Gen4 Verification Done  =====", UVM_NONE)
        phase.drop_objection(this);
    endtask
endclass
