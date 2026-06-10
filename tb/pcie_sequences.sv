// ============================================
// PCIe Sequences — Transaction Generation
// Contains: MemWr, MemRd, CfgRd, CfgWr, Burst, WrRd, and Regression
// Author: Saravana Kumar T J A
// ============================================
`ifndef PCIE_SEQUENCES_SV
`define PCIE_SEQUENCES_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// ── Memory Write Sequence ──────────────────────────────
class pcie_memwr_seq extends uvm_sequence #(pcie_seq_item);
    `uvm_object_utils(pcie_memwr_seq)

    function new(string name = "pcie_memwr_seq");
        super.new(name);
    endfunction

    task body();
        pcie_seq_item item;
        item = pcie_seq_item::type_id::create("item");
        
        start_item(item);
        // Pre-initialize all non-random fields to clear out 'X' states
        item.op_type  = pcie_seq_item::OP_MEMWR;
        item.fmt      = 3'b010;
        item.tlp_type = 5'b00000;
        item.length   = 10'd1;
        item.poisoned = 1'b0;
        item.tc       = 3'b000;
        item.data     = new[1];
        item.data[0]  = $urandom();

        if (!item.randomize(address, tag))
            `uvm_fatal("SEQ", "MemWr randomization failed")
            
        `uvm_info("MEMWR", item.convert2string(), UVM_MEDIUM)
        finish_item(item);
    endtask
endclass

// ── Memory Read Sequence ───────────────────────────────
class pcie_memrd_seq extends uvm_sequence #(pcie_seq_item);
    `uvm_object_utils(pcie_memrd_seq)

    function new(string name = "pcie_memrd_seq");
        super.new(name);
    endfunction

    task body();
        pcie_seq_item item;
        item = pcie_seq_item::type_id::create("item");
        
        start_item(item);
        item.op_type  = pcie_seq_item::OP_MEMRD;
        item.fmt      = 3'b000;
        item.tlp_type = 5'b00000; 
        item.length   = 10'd1;
        item.poisoned = 1'b0;
        item.tc       = 3'b000;
        item.data     = new[1];
        item.data[0]  = 32'd0;

        if (!item.randomize(address, tag))
            `uvm_fatal("SEQ", "MemRd randomization failed")
            
        `uvm_info("MEMRD", item.convert2string(), UVM_MEDIUM)
        finish_item(item);
    endtask
endclass

// ── Config Read Type 0 Sequence (FIXED) ────────────────
class pcie_cfgrd_seq extends uvm_sequence #(pcie_seq_item);
    `uvm_object_utils(pcie_cfgrd_seq)

    function new(string name = "pcie_cfgrd_seq");
        super.new(name);
    endfunction

    task body();
        pcie_seq_item item;
        item = pcie_seq_item::type_id::create("item");
        
        start_item(item);
        // FIXED: Fully defined state variables to prevent c_no_poison and c_tc expression collapse
        item.op_type  = pcie_seq_item::OP_CFGRD0;
        item.fmt      = 3'b000;
        item.tlp_type = 5'b00100;
        item.address  = 32'h00000000;
        item.length   = 10'd1;
        item.poisoned = 1'b0;
        item.tc       = 3'b000;
        item.data     = new[1];
        item.data[0]  = 32'd0;

        if (!item.randomize(tag))
            `uvm_fatal("SEQ", "CfgRd randomization failed")
            
        `uvm_info("CFGRD", item.convert2string(), UVM_MEDIUM)
        finish_item(item);
    endtask
endclass

// ── Config Write Type 0 Sequence (FIXED) ────────────────
class pcie_cfgwr_seq extends uvm_sequence #(pcie_seq_item);
    `uvm_object_utils(pcie_cfgwr_seq)

    function new(string name = "pcie_cfgwr_seq");
        super.new(name);
    endfunction

    task body();
        pcie_seq_item item;
        item = pcie_seq_item::type_id::create("item");
        
        start_item(item);
        // FIXED: Initialized state logic elements completely
        item.op_type  = pcie_seq_item::OP_CFGWR0;
        item.fmt      = 3'b010;
        item.tlp_type = 5'b00100;
        item.address  = 32'h00000010;
        item.length   = 10'd1;
        item.poisoned = 1'b0;
        item.tc       = 3'b000;
        item.data     = new[1];
        item.data[0]  = 32'hBEEF0000;

        if (!item.randomize(tag))
            `uvm_fatal("SEQ", "CfgWr randomization failed")
            
        `uvm_info("CFGWR", item.convert2string(), UVM_MEDIUM)
        finish_item(item);
    endtask
endclass

// ── Burst Write 4 Beats Sequence ───────────────────────
class pcie_burst_wr_seq extends uvm_sequence #(pcie_seq_item);
    `uvm_object_utils(pcie_burst_wr_seq)

    function new(string name = "pcie_burst_wr_seq");
        super.new(name);
    endfunction

    task body();
        pcie_seq_item item;
        for (int i = 0; i < 4; i++) begin
            item = pcie_seq_item::type_id::create("item");
            
            start_item(item);
            item.op_type  = pcie_seq_item::OP_MEMWR;
            item.fmt      = 3'b010;
            item.tlp_type = 5'b00000;
            item.length   = 10'd1;
            item.poisoned = 1'b0;
            item.tc       = 3'b000;
            item.data     = new[1];
            item.data[0]  = $urandom();

            if (!item.randomize(address, tag))
                `uvm_fatal("SEQ", "Burst randomization failed")
                
            finish_item(item);
        end
    endtask
endclass

// ── Write Then Read Back Sequence ──────────────────────
class pcie_wr_rd_seq extends uvm_sequence #(pcie_seq_item);
    `uvm_object_utils(pcie_wr_rd_seq)

    function new(string name = "pcie_wr_rd_seq");
        super.new(name);
    endfunction

    task body();
        pcie_seq_item wr, rd;
        logic [31:0] saved_addr;

        // Phase 1: Write Transaction
        wr = pcie_seq_item::type_id::create("wr");
        start_item(wr);
        wr.op_type  = pcie_seq_item::OP_MEMWR;
        wr.fmt      = 3'b010;
        wr.tlp_type = 5'b00000;
        wr.length   = 10'd1;
        wr.poisoned = 1'b0;
        wr.tc       = 3'b000;
        wr.data     = new[1];
        wr.data[0]  = $urandom();

        if (!wr.randomize(address, tag))
            `uvm_fatal("SEQ", "WrRd write randomization failed")
        saved_addr = wr.address;
        finish_item(wr);

        // Phase 2: Read Back Transaction
        rd = pcie_seq_item::type_id::create("rd");
        start_item(rd);
        rd.op_type  = pcie_seq_item::OP_MEMRD;
        rd.fmt      = 3'b000;
        rd.tlp_type = 5'b00000;
        rd.address  = saved_addr;
        rd.length   = 10'd1;
        rd.poisoned = 1'b0;
        rd.tc       = 3'b000;
        rd.data     = new[1];
        rd.data[0]  = 32'd0;

        if (!rd.randomize(tag))
            `uvm_fatal("SEQ", "WrRd read randomization failed")
        finish_item(rd);
    endtask
endclass

// ── Poisoned TLP Sequence ──────────────────────────────
class pcie_poison_seq extends uvm_sequence #(pcie_seq_item);
    `uvm_object_utils(pcie_poison_seq)

    function new(string name = "pcie_poison_seq");
        super.new(name);
    endfunction

    task body();
        pcie_seq_item item;
        item = pcie_seq_item::type_id::create("item");
        
        start_item(item);
        item.op_type  = pcie_seq_item::OP_POISONED;
        item.fmt      = 3'b010;
        item.tlp_type = 5'b00000;
        item.length   = 10'd1;
        item.poisoned = 1'b1;
        item.tc       = 3'b000;
        item.data     = new[1];
        item.data[0]  = 32'hDEADDEAD;

        if (!item.randomize(address, tag))
            `uvm_fatal("SEQ", "Poison randomization failed")
            
        `uvm_info("POISON", "Injecting POISONED TLP", UVM_LOW)
        finish_item(item);
    endtask
endclass

// ── Full Regression Master Sequence ───────────────────────────
class pcie_regression_seq extends uvm_sequence #(pcie_seq_item);
    `uvm_object_utils(pcie_regression_seq)

    function new(string name = "pcie_regression_seq");
        super.new(name);
    endfunction

    task body();
        pcie_memwr_seq    wr_seq;
        pcie_memrd_seq    rd_seq;
        pcie_cfgrd_seq    cfgrd_seq;
        pcie_cfgwr_seq    cfgwr_seq;
        pcie_burst_wr_seq burst_seq;
        pcie_wr_rd_seq    wrrd_seq;
        pcie_poison_seq   poison_seq;

        `uvm_info("REGR", "=== PCIe Regression Start ===", UVM_NONE)

        wr_seq     = pcie_memwr_seq::type_id::create("wr_seq");
        rd_seq     = pcie_memrd_seq::type_id::create("rd_seq");
        cfgrd_seq  = pcie_cfgrd_seq::type_id::create("cfgrd");
        cfgwr_seq  = pcie_cfgwr_seq::type_id::create("cfgwr");
        burst_seq  = pcie_burst_wr_seq::type_id::create("burst");
        wrrd_seq   = pcie_wr_rd_seq::type_id::create("wrrd");
        poison_seq = pcie_poison_seq::type_id::create("poison");

        for (int i = 0; i < 5; i++) begin
            wr_seq.start(m_sequencer);
            rd_seq.start(m_sequencer);
        end
        
        cfgrd_seq.start(m_sequencer);
        cfgwr_seq.start(m_sequencer);
        burst_seq.start(m_sequencer);
        
        repeat(3) begin
            wrrd_seq.start(m_sequencer);
        end
        
        poison_seq.start(m_sequencer);
        
        `uvm_info("REGR", "=== PCIe Regression Done ===", UVM_NONE)
    endtask
endclass

`endif
