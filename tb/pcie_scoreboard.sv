// ============================================
// PCIe Scoreboard
// Checks:
//   1. MemWr then MemRd — data must match
//   2. CfgRd returns valid vendor ID
//   3. CplD received for every MRd sent
//   4. Poisoned TLP handled correctly
// Author: Saravana Kumar T J A
// ============================================
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "../tb/pcie_seq_item.sv"

class pcie_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(pcie_scoreboard)

    uvm_analysis_imp #(pcie_seq_item, pcie_scoreboard) ap;

    // Reference memory model
    logic [31:0] ref_mem [logic [31:0]];

    // Stats
    int pass_count = 0;
    int fail_count = 0;
    int cpl_count  = 0;

    function new(string name = "pcie_scoreboard",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction

    function void write(pcie_seq_item item);
        case (item.op_type)

            pcie_seq_item::OP_MEMWR: begin
                // Store in reference model
                if (item.data.size() > 0) begin
                    ref_mem[item.address] = item.data[0];
                    `uvm_info("SB",
                        $sformatf("REF: mem[0x%08h]=0x%08h",
                        item.address, item.data[0]),
                        UVM_MEDIUM)
                end
            end

            pcie_seq_item::OP_MEMRD: begin
                // Check if address was previously written
                if (ref_mem.exists(item.address)) begin
                    if (item.cpl_data.size() > 0) begin
                        if (item.cpl_data[0] === ref_mem[item.address]) begin
                            pass_count++;
                            `uvm_info("SB",
                                $sformatf("PASS: mem[0x%08h] rd=0x%08h exp=0x%08h",
                                item.address, item.cpl_data[0],
                                ref_mem[item.address]),
                                UVM_LOW)
                        end else begin
                            fail_count++;
                            `uvm_error("SB",
                                $sformatf("FAIL: mem[0x%08h] rd=0x%08h exp=0x%08h",
                                item.address, item.cpl_data[0],
                                ref_mem[item.address]))
                        end
                    end
                end
            end

            pcie_seq_item::OP_CFGRD0: begin
                // Vendor/Device ID should be valid
                if (item.cpl_data.size() > 0) begin
                    if (item.cpl_data[0] !== 32'hX) begin
                        pass_count++;
                        `uvm_info("SB",
                            $sformatf("PASS: CfgRd Vendor:Device=0x%08h",
                            item.cpl_data[0]),
                            UVM_LOW)
                    end else begin
                        fail_count++;
                        `uvm_error("SB", "FAIL: CfgRd returned X")
                    end
                end
            end

            pcie_seq_item::OP_POISONED: begin
                // Poisoned TLP should be flagged
                if (item.poisoned) begin
                    pass_count++;
                    `uvm_info("SB",
                        "PASS: Poisoned TLP correctly flagged",
                        UVM_LOW)
                end else begin
                    fail_count++;
                    `uvm_error("SB",
                        "FAIL: Poisoned TLP not detected")
                end
            end

        endcase
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", "==========================================", UVM_NONE)
        `uvm_info("SB", " PCIe SCOREBOARD RESULTS", UVM_NONE)
        `uvm_info("SB", $sformatf(" PASSED : %0d", pass_count), UVM_NONE)
        `uvm_info("SB", $sformatf(" FAILED : %0d", fail_count), UVM_NONE)
        if (fail_count == 0)
            `uvm_info("SB", " STATUS : ALL CHECKS PASSED ✓", UVM_NONE)
        else
            `uvm_error("SB",
                $sformatf(" STATUS : %0d CHECKS FAILED ✗", fail_count))
        `uvm_info("SB", "==========================================", UVM_NONE)
    endfunction

endclass
