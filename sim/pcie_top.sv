// ============================================
// PCIe Simulation Top
// Connects DUT + Interface + UVM TB
// Author: Saravana Kumar T J A
// ============================================
`include "uvm_macros.svh"
import uvm_pkg::*;

// 1. Compile static configurations and data types first
`include "../tb/pcie_pkg.sv"
`include "../tb/pcie_seq_item.sv"

// 2. Compile active verification infrastructure
`include "../tb/pcie_sequencer.sv"
`include "../tb/pcie_sequences.sv"
`include "../tb/pcie_driver.sv"
`include "../tb/pcie_monitor.sv"
`include "../tb/pcie_scoreboard.sv"
`include "../tb/pcie_coverage.sv"

// 3. Compile structural environment containers last
`include "../tb/pcie_agent.sv"
`include "../tb/pcie_env.sv"
`include "../tb/pcie_test.sv"

module pcie_top;
    // Clock and Reset
    logic clk;
    logic rst_n;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
        $display("[TOP] Reset released at t=%0t", $time);
    end

    // Interface instance
    pcie_if pcie_vif (.clk(clk), .rst_n(rst_n));

    // TLP Layer DUT
    pcie_tlp_layer u_tlp (
        .clk             (clk),
        .rst_n           (rst_n),
        .send_req        (pcie_vif.send_req),
        .tlp_fmt_in      (pcie_vif.tlp_fmt_in),
        .tlp_type_in     (pcie_vif.tlp_type_in),
        .tlp_length_in   (pcie_vif.tlp_length_in),
        .tlp_addr_in     (pcie_vif.tlp_addr_in),
        .tlp_data_in     (pcie_vif.tlp_data_in),
        .tlp_tag_in      (pcie_vif.tlp_tag_in),
        .send_ack        (pcie_vif.send_ack),
        .tlp_valid       (pcie_vif.tlp_valid),
        .tlp_hdr         (pcie_vif.tlp_hdr),
        .tlp_data        (pcie_vif.tlp_data_out),
        .tlp_data_valid  (pcie_vif.tlp_data_valid),
        .ep_ready        (pcie_vif.ep_ready),
        .cpl_valid       (pcie_vif.cpl_valid),
        .cpl_hdr         (pcie_vif.cpl_hdr),
        .cpl_data        (pcie_vif.cpl_data_out),
        .cpl_ack         (pcie_vif.cpl_ack),
        .posted_credits  (pcie_vif.posted_credits),
        .nonpost_credits (pcie_vif.nonpost_credits),
        .tlp_sent_count  (pcie_vif.tlp_sent_count),
        .cpl_recv_count  (),
        .fc_stall_count  (pcie_vif.fc_stall_count),
        .poisoned_detected(pcie_vif.poisoned_detected)
    );

    // PCIe Endpoint Memory DUT
    pcie_ep_memory u_ep (
        .clk             (clk),
        .rst_n           (rst_n),
        .tlp_valid_in    (pcie_vif.tlp_valid),
        .tlp_hdr_in      (pcie_vif.tlp_hdr),
        .tlp_data_in     (pcie_vif.tlp_data_out),
        .tlp_data_valid  (pcie_vif.tlp_data_valid),
        .tlp_ready       (pcie_vif.ep_ready),
        .tlp_valid_out   (pcie_vif.cpl_valid),
        .tlp_hdr_out     (pcie_vif.cpl_hdr),
        .tlp_data_out    (pcie_vif.cpl_data_out),
        .tlp_last_out    (),
        .tlp_ack_in      (pcie_vif.cpl_ack),
        .posted_hdr_credits (pcie_vif.posted_credits),
        .nonpost_hdr_credits(pcie_vif.nonpost_credits),
        .cpl_hdr_credits (pcie_vif.cpl_credits),
        .link_up         (pcie_vif.link_up),
        .ltssm_state     (pcie_vif.ltssm_state)
    );

    // UVM Setup
    initial begin
        uvm_config_db #(virtual pcie_if)::set(
            null, "uvm_test_top.*", "pcie_vif", pcie_vif);
        run_test("pcie_test");
    end

    // Timeout
    initial begin
        #2_000_000;
        $display("TIMEOUT at t=%0t", $time);
        $finish;
    end
endmodule
