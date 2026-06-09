// ============================================
// PCIe TLP Layer — Transaction Layer
// Handles TLP encoding, decoding,
// flow control checking, tag management
// Author: Saravana Kumar T J A
// ============================================
module pcie_tlp_layer (
    input  wire        clk,
    input  wire        rst_n,

    // From testbench — raw TLP fields
    input  wire        send_req,        // TB wants to send TLP
    input  wire [2:0]  tlp_fmt_in,      // FMT field
    input  wire [4:0]  tlp_type_in,     // TYPE field
    input  wire [9:0]  tlp_length_in,   // payload DWORDs
    input  wire [31:0] tlp_addr_in,     // target address
    input  wire [31:0] tlp_data_in,     // write data
    input  wire [7:0]  tlp_tag_in,      // transaction tag
    output reg         send_ack,        // TLP accepted

    // To/from endpoint
    output reg         tlp_valid,
    output reg  [95:0] tlp_hdr,
    output reg  [31:0] tlp_data,
    output reg         tlp_data_valid,
    input  wire        ep_ready,

    // Completion from endpoint
    input  wire        cpl_valid,
    input  wire [95:0] cpl_hdr,
    input  wire [31:0] cpl_data,
    output reg         cpl_ack,

    // Flow control interface
    input  wire [7:0]  posted_credits,
    input  wire [7:0]  nonpost_credits,

    // TLP stats
    output reg [15:0]  tlp_sent_count,
    output reg [15:0]  cpl_recv_count,
    output reg [15:0]  fc_stall_count,   // times we stalled for credits
    output reg         poisoned_detected  // EP flag set on received TLP
);

    // ── State machine ─────────────────────────
    localparam S_IDLE     = 3'd0;
    localparam S_FC_CHECK = 3'd1;
    localparam S_SEND_HDR = 3'd2;
    localparam S_SEND_DATA= 3'd3;
    localparam S_WAIT_CPL = 3'd4;

    reg [2:0] state;

    // ── Tag management ────────────────────────
    reg [7:0] pending_tags [0:255];   // track outstanding reads
    reg [7:0] tag_valid    [0:255];

    // ── Registered inputs ─────────────────────
    reg [2:0]  fmt_r;
    reg [4:0]  type_r;
    reg [9:0]  len_r;
    reg [31:0] addr_r;
    reg [31:0] data_r;
    reg [7:0]  tag_r;

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            pending_tags[i] = 8'd0;
            tag_valid[i]    = 8'd0;
        end
    end

    // ── Main state machine ────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= S_IDLE;
            tlp_valid        <= 1'b0;
            tlp_hdr          <= 96'd0;
            tlp_data         <= 32'd0;
            tlp_data_valid   <= 1'b0;
            send_ack         <= 1'b0;
            cpl_ack          <= 1'b0;
            tlp_sent_count   <= 16'd0;
            cpl_recv_count   <= 16'd0;
            fc_stall_count   <= 16'd0;
            poisoned_detected<= 1'b0;
        end
        else begin
            send_ack       <= 1'b0;
            cpl_ack        <= 1'b0;
            tlp_data_valid <= 1'b0;

            case (state)

                S_IDLE: begin
                    tlp_valid <= 1'b0;
                    if (send_req) begin
                        fmt_r  <= tlp_fmt_in;
                        type_r <= tlp_type_in;
                        len_r  <= tlp_length_in;
                        addr_r <= tlp_addr_in;
                        data_r <= tlp_data_in;
                        tag_r  <= tlp_tag_in;
                        state  <= S_FC_CHECK;
                    end
                    // Handle incoming completion
                    if (cpl_valid) begin
                        cpl_recv_count <= cpl_recv_count + 1;
                        cpl_ack        <= 1'b1;
                        // Check for poisoned TLP (EP bit in header)
                        if (cpl_hdr[78]) begin
                            poisoned_detected <= 1'b1;
                            $display("[TLP] WARNING: Poisoned TLP received!");
                        end
                        $display("[TLP] CplD received: data=0x%08h tag=%0d",
                            cpl_data, cpl_hdr[15:8]);
                    end
                end

                S_FC_CHECK: begin
                    // Check flow control credits before sending
                    if (fmt_r[1]) begin
                        // Posted (write) — check posted credits
                        if (posted_credits > 8'd0)
                            state <= S_SEND_HDR;
                        else begin
                            fc_stall_count <= fc_stall_count + 1;
                            $display("[TLP] FC STALL: no posted credits");
                        end
                    end
                    else begin
                        // Non-posted (read) — check NP credits
                        if (nonpost_credits > 8'd0)
                            state <= S_SEND_HDR;
                        else begin
                            fc_stall_count <= fc_stall_count + 1;
                            $display("[TLP] FC STALL: no NP credits");
                        end
                    end
                end

                S_SEND_HDR: begin
                    if (ep_ready) begin
                        // Build 3-DWORD TLP header
                        tlp_hdr[95:88] <= {fmt_r, type_r};
                        tlp_hdr[87:80] <= 8'h00;
                        tlp_hdr[79:74] <= 6'h00;
                        tlp_hdr[73:64] <= len_r;
                        tlp_hdr[63:48] <= 16'hABCD; // Requester ID
                        tlp_hdr[47:40] <= tag_r;
                        tlp_hdr[39:32] <= 8'hFF;    // Byte enables
                        tlp_hdr[31:0]  <= addr_r;

                        tlp_valid <= 1'b1;

                        if (fmt_r[1]) begin
                            // Write — send data too
                            state <= S_SEND_DATA;
                        end
                        else begin
                            // Read — wait for completion
                            tag_valid[tag_r] <= 8'd1;
                            state <= S_WAIT_CPL;
                        end

                        tlp_sent_count <= tlp_sent_count + 1;
                        $display("[TLP] Sent: fmt=%0b type=%0b addr=0x%08h",
                            fmt_r, type_r, addr_r);
                    end
                end

                S_SEND_DATA: begin
                    tlp_data       <= data_r;
                    tlp_data_valid <= 1'b1;
                    tlp_valid      <= 1'b0;
                    send_ack       <= 1'b1;
                    state          <= S_IDLE;
                end

                S_WAIT_CPL: begin
                    tlp_valid <= 1'b0;
                    if (cpl_valid) begin
                        cpl_recv_count        <= cpl_recv_count + 1;
                        tag_valid[tag_r]      <= 8'd0;
                        cpl_ack               <= 1'b1;
                        send_ack              <= 1'b1;
                        state                 <= S_IDLE;
                        $display("[TLP] CplD tag=%0d data=0x%08h",
                            tag_r, cpl_data);
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
