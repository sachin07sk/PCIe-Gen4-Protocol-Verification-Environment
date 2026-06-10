// ============================================
// PCIe Monitor
// Observes TLP transactions on DUT interface
// Sends captured items to scoreboard
// Author: Saravana Kumar T J A
// ============================================
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "../tb/pcie_seq_item.sv"

class pcie_monitor extends uvm_monitor;
    `uvm_component_utils(pcie_monitor)

    virtual interface pcie_if vif;
    uvm_analysis_port #(pcie_seq_item) ap;

    // Statistics
    int tlp_count      = 0;
    int cpl_count      = 0;
    int poison_count   = 0;
    int fc_stall_count = 0;

    function new(string name = "pcie_monitor",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual pcie_if)::get(
                this, "", "pcie_vif", vif))
            `uvm_fatal("CFG", "Cannot get pcie_vif in monitor")
    endfunction

    task run_phase(uvm_phase phase);
        // Wait for link up
        @(posedge vif.link_up);
        `uvm_info("MON", "Link UP — monitoring TLPs", UVM_LOW)

        forever begin
            @(posedge vif.clk);

            // Monitor outgoing TLPs
            if (vif.tlp_valid && vif.ep_ready) begin
                pcie_seq_item item;
                item = pcie_seq_item::type_id::create("mon_item");

                item.fmt      = pcie_pkg::tlp_fmt_t'(vif.tlp_hdr[95:93]);
                item.tlp_type = pcie_pkg::tlp_type_t'(vif.tlp_hdr[92:88]);
                item.length   = vif.tlp_hdr[73:64];
                item.tag      = vif.tlp_hdr[47:40];
                item.address  = vif.tlp_hdr[31:0];

                // Collect data if write TLP
                if (vif.tlp_data_valid) begin
                    item.data    = new[1];
                    item.data[0] = vif.tlp_data_out;
                end

                // Check for poisoned TLP
                if (vif.poisoned_detected) begin
                    item.poisoned = 1;
                    poison_count++;
                    `uvm_warning("MON",
                        "POISONED TLP detected on bus!")
                end

                tlp_count++;
                `uvm_info("MON",
                    $sformatf("TLP #%0d: %s addr=0x%08h",
                    tlp_count,
                    pcie_pkg::get_tlp_name(item.fmt, item.tlp_type),
                    item.address),
                    UVM_LOW)

                ap.write(item);
            end

            // Monitor completions
            if (vif.cpl_valid) begin
                cpl_count++;
                `uvm_info("MON",
                    $sformatf("CplD #%0d: data=0x%08h",
                    cpl_count, vif.cpl_data_out),
                    UVM_LOW)
            end

            // Monitor FC stalls
            if (vif.fc_stall_count > fc_stall_count) begin
                fc_stall_count = vif.fc_stall_count;
                `uvm_info("MON",
                    "Flow Control stall detected", UVM_LOW)
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("MON", "==========================================", UVM_NONE)
        `uvm_info("MON", " PCIe MONITOR SUMMARY", UVM_NONE)
        `uvm_info("MON", $sformatf(" TLPs sent     : %0d", tlp_count), UVM_NONE)
        `uvm_info("MON", $sformatf(" Completions   : %0d", cpl_count), UVM_NONE)
        `uvm_info("MON", $sformatf(" Poisoned TLPs : %0d", poison_count), UVM_NONE)
        `uvm_info("MON", $sformatf(" FC Stalls     : %0d", fc_stall_count), UVM_NONE)
        `uvm_info("MON", "==========================================", UVM_NONE)
    endfunction

endclass
