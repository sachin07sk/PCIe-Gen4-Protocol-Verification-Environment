// ============================================
// PCIe Driver
// Converts seq_items to DUT pin-level activity
// Author: Saravana Kumar T J A
// ============================================
`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_driver extends uvm_driver #(pcie_seq_item);
    `uvm_component_utils(pcie_driver)

    virtual interface pcie_if vif;
    int posted_credits;
    int nonpost_credits;

    function new(string name = "pcie_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual pcie_if)::get(this, "", "pcie_vif", vif))
            `uvm_fatal("CFG", "Cannot get pcie_vif")
        posted_credits  = 64;
        nonpost_credits = 32;
    endfunction

    task run_phase(uvm_phase phase);
        vif.send_req       <= 0;
        vif.tlp_fmt_in     <= 0;
        vif.tlp_type_in    <= 0;
        vif.tlp_length_in  <= 0;
        vif.tlp_addr_in    <= 0;
        vif.tlp_data_in    <= 0;
        vif.tlp_tag_in     <= 0;

        @(posedge vif.link_up);
        `uvm_info("DRV", "Link UP — starting TLP transactions", UVM_LOW)
        @(posedge vif.clk);

        forever begin
            pcie_seq_item item;
            seq_item_port.get_next_item(item);
            
            posted_credits  = vif.posted_credits;
            nonpost_credits = vif.nonpost_credits;

            `uvm_info("DRV", $sformatf("Driving %s TLP addr=0x%08h", item.op_type.name(), item.address), UVM_MEDIUM)

            drive_tlp(item);
            seq_item_port.item_done();
        end
    endtask

    task drive_tlp(pcie_seq_item item);
        @(posedge vif.clk);
        vif.send_req      <= 1;
        vif.tlp_fmt_in    <= item.fmt;
        vif.tlp_type_in   <= item.tlp_type;
        vif.tlp_length_in <= item.length;
        vif.tlp_addr_in   <= item.address;
        vif.tlp_tag_in    <= item.tag;
        
        if (item.data.size() > 0)
            vif.tlp_data_in <= item.data[0];
        else
            vif.tlp_data_in <= 32'd0;

        @(posedge vif.clk);
        vif.send_req <= 0;

        while (!vif.send_ack)
            @(posedge vif.clk);
            
        `uvm_info("DRV", $sformatf("TLP sent — tag=%0d", item.tag), UVM_LOW)
    endtask
endclass
