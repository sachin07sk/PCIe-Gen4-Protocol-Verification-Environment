// ============================================
// PCIe Interface
// Connects TLP layer DUT to testbench
// Author: Saravana Kumar T J A
// ============================================
interface pcie_if (input logic clk, input logic rst_n);

    // ── Send interface (TB → DUT) ─────────────
    logic        send_req;
    logic        send_ack;
    logic [2:0]  tlp_fmt_in;
    logic [4:0]  tlp_type_in;
    logic [9:0]  tlp_length_in;
    logic [31:0] tlp_addr_in;
    logic [31:0] tlp_data_in;
    logic [7:0]  tlp_tag_in;

    // ── TLP to endpoint ───────────────────────
    logic        tlp_valid;
    logic [95:0] tlp_hdr;
    logic [31:0] tlp_data_out;
    logic        tlp_data_valid;
    logic        ep_ready;

    // ── Completion from endpoint ──────────────
    logic        cpl_valid;
    logic [95:0] cpl_hdr;
    logic [31:0] cpl_data_out;
    logic        cpl_ack;

    // ── Flow control ──────────────────────────
    logic [7:0]  posted_credits;
    logic [7:0]  nonpost_credits;
    logic [7:0]  cpl_credits;

    // ── Status signals ────────────────────────
    logic        link_up;
    logic [3:0]  ltssm_state;
    logic [15:0] tlp_sent_count;
    logic [15:0] fc_stall_count;
    logic        poisoned_detected;

    // ── Driver clocking block ─────────────────
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output send_req, tlp_fmt_in, tlp_type_in;
        output tlp_length_in, tlp_addr_in;
        output tlp_data_in, tlp_tag_in;
        input  send_ack, link_up;
        input  posted_credits, nonpost_credits;
    endclocking

    // ── Monitor clocking block ────────────────
    clocking monitor_cb @(posedge clk);
        default input #1;
        input send_req, send_ack;
        input tlp_valid, tlp_hdr, tlp_data_out, tlp_data_valid;
        input cpl_valid, cpl_data_out;
        input link_up, ltssm_state;
        input tlp_sent_count, fc_stall_count;
        input poisoned_detected;
        input posted_credits, nonpost_credits;
    endclocking

    modport DRIVER  (clocking driver_cb,  input clk, rst_n);
    modport MONITOR (clocking monitor_cb, input clk, rst_n);

endinterface
