// ============================================
// PCIe Endpoint Memory
// Simulates a simple PCIe endpoint device
// Supports: MemRd, MemWr, CfgRd0, CfgWr0
// 1KB BAR0 memory space
// Author: Saravana Kumar T J A
// ============================================
module pcie_ep_memory (
    input  wire        clk,
    input  wire        rst_n,

    // TLP receive interface (from RC/TB)
    input  wire        tlp_valid_in,
    input  wire [95:0] tlp_hdr_in,     // 3 DWORDs header
    input  wire [31:0] tlp_data_in,    // one DWORD data
    input  wire        tlp_data_valid,
    output reg         tlp_ready,      // EP ready to accept

    // TLP transmit interface (to RC/TB)
    output reg         tlp_valid_out,
    output reg  [95:0] tlp_hdr_out,
    output reg  [31:0] tlp_data_out,
    output reg         tlp_last_out,
    input  wire        tlp_ack_in,

    // Flow control credits
    output reg  [7:0]  posted_hdr_credits,
    output reg  [7:0]  nonpost_hdr_credits,
    output reg  [7:0]  cpl_hdr_credits,

    // Link status
    output reg         link_up,
    output reg  [3:0]  ltssm_state
);

    // ── LTSSM States ──────────────────────────
    localparam LTSSM_DETECT  = 4'd0;
    localparam LTSSM_POLLING = 4'd1;
    localparam LTSSM_CONFIG  = 4'd2;
    localparam LTSSM_L0      = 4'd3;
    localparam LTSSM_L0S     = 4'd4;
    localparam LTSSM_L1      = 4'd5;
    localparam LTSSM_RECOVERY= 4'd6;

    // ── TLP Type Encoding ─────────────────────
    localparam TLP_MRD   = 5'b00000; // Memory Read
    localparam TLP_MWR   = 5'b00000; // Memory Write (FMT=010)
    localparam TLP_CFGRD0= 5'b00100; // Config Read Type 0
    localparam TLP_CFGWR0= 5'b00100; // Config Write Type 0
    localparam TLP_CPL   = 5'b01010; // Completion no data
    localparam TLP_CPLD  = 5'b01010; // Completion with data

    // ── Memory ────────────────────────────────
    reg [31:0] bar0_mem  [0:255];  // 1KB BAR0 space
    reg [31:0] cfg_space [0:63];   // 256-byte config space

    // ── Internal registers ────────────────────
    reg [3:0]  ltssm_cnt;
    reg [7:0]  cpl_tag;
    reg [31:0] cpl_data;
    reg        cpl_pending;
    reg [15:0] req_id_r;
    reg [7:0]  tag_r;
    reg [9:0]  length_r;

    // ── TLP field extraction ──────────────────
    wire [2:0]  tlp_fmt    = tlp_hdr_in[95:93];
    wire [4:0]  tlp_type   = tlp_hdr_in[92:88];
    wire [9:0]  tlp_length = tlp_hdr_in[73:64];
    wire [15:0] requester  = tlp_hdr_in[63:48];
    wire [7:0]  tag        = tlp_hdr_in[47:40];
    wire [31:0] address    = tlp_hdr_in[31:0];

    wire is_write  = tlp_fmt[1];   // FMT bit 1 = has data
    wire is_cfgrd  = (tlp_type == 5'b00100) && !is_write;
    wire is_cfgwr  = (tlp_type == 5'b00100) &&  is_write;
    wire is_memrd  = (tlp_type == 5'b00000) && !is_write;
    wire is_memwr  = (tlp_type == 5'b00000) &&  is_write;

    integer i;

    // ── Initialize ────────────────────────────
    initial begin
        for (i = 0; i < 256; i = i + 1)
            bar0_mem[i] = 32'd0;
        for (i = 0; i < 64; i = i + 1)
            cfg_space[i] = 32'd0;

        // Config space defaults
        cfg_space[0] = 32'h0BAD_CAFE;  // Vendor:Device ID
        cfg_space[1] = 32'h0000_0000;  // Status:Command
        cfg_space[2] = 32'hFF00_0000;  // Class:Revision
        cfg_space[4] = 32'h0000_0000;  // BAR0 (set by CfgWr)
    end

    // ── LTSSM — Link Training ─────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ltssm_state <= LTSSM_DETECT;
            ltssm_cnt   <= 4'd0;
            link_up     <= 1'b0;
        end
        else begin
            case (ltssm_state)
                LTSSM_DETECT: begin
                    ltssm_cnt <= ltssm_cnt + 1;
                    if (ltssm_cnt == 4'd2)
                        ltssm_state <= LTSSM_POLLING;
                end
                LTSSM_POLLING: begin
                    ltssm_cnt <= ltssm_cnt + 1;
                    if (ltssm_cnt == 4'd5)
                        ltssm_state <= LTSSM_CONFIG;
                end
                LTSSM_CONFIG: begin
                    ltssm_cnt <= ltssm_cnt + 1;
                    if (ltssm_cnt == 4'd8) begin
                        ltssm_state <= LTSSM_L0;
                        link_up     <= 1'b1;
                    end
                end
                LTSSM_L0: begin
                    // Stay in L0 — fully operational
                    link_up <= 1'b1;
                end
                default: ltssm_state <= LTSSM_DETECT;
            endcase
        end
    end

    // ── Flow Control Credits ──────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            posted_hdr_credits   <= 8'd64;
            nonpost_hdr_credits  <= 8'd32;
            cpl_hdr_credits      <= 8'd64;
        end
        else if (link_up) begin
            // Replenish credits as TLPs are processed
            if (tlp_valid_in && tlp_ready && is_memwr)
                posted_hdr_credits <= posted_hdr_credits + 1;
            if (tlp_valid_in && tlp_ready && is_memrd)
                nonpost_hdr_credits <= nonpost_hdr_credits + 1;
        end
    end

    // ── TLP Receive and Process ───────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tlp_ready   <= 1'b0;
            cpl_pending <= 1'b0;
            cpl_tag     <= 8'd0;
            cpl_data    <= 32'd0;
            req_id_r    <= 16'd0;
            tag_r       <= 8'd0;
        end
        else begin
            tlp_ready <= link_up; // Accept TLPs when link is up

            if (tlp_valid_in && tlp_ready && link_up) begin

                if (is_memwr && tlp_data_valid) begin
                    // Memory Write — store data
                    bar0_mem[address[9:2]] <= tlp_data_in;
                    $display("[EP] MemWr: addr=0x%08h data=0x%08h",
                        address, tlp_data_in);
                end

                else if (is_memrd) begin
                    // Memory Read — prepare completion
                    cpl_data    <= bar0_mem[address[9:2]];
                    cpl_tag     <= tag;
                    req_id_r    <= requester;
                    tag_r       <= tag;
                    length_r    <= tlp_length;
                    cpl_pending <= 1'b1;
                    $display("[EP] MemRd: addr=0x%08h tag=%0d",
                        address, tag);
                end

                else if (is_cfgrd) begin
                    // Config Read — prepare completion
                    cpl_data    <= cfg_space[address[7:2]];
                    cpl_tag     <= tag;
                    req_id_r    <= requester;
                    tag_r       <= tag;
                    cpl_pending <= 1'b1;
                    $display("[EP] CfgRd: offset=0x%04h tag=%0d",
                        address[7:0], tag);
                end

                else if (is_cfgwr && tlp_data_valid) begin
                    // Config Write — update config space
                    cfg_space[address[7:2]] <= tlp_data_in;
                    $display("[EP] CfgWr: offset=0x%04h data=0x%08h",
                        address[7:0], tlp_data_in);
                end
            end
        end
    end

    // ── TLP Transmit — Send Completion ────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tlp_valid_out <= 1'b0;
            tlp_hdr_out   <= 96'd0;
            tlp_data_out  <= 32'd0;
            tlp_last_out  <= 1'b0;
        end
        else begin
            if (cpl_pending && !tlp_valid_out) begin
                // Build CplD header (3 DWORDs)
                // DWORD0: FMT=010(CplD) TYPE=01010
                tlp_hdr_out[95:88] <= {3'b010, 5'b01010}; // FMT+TYPE
                tlp_hdr_out[87:80] <= 8'h00;               // misc
                tlp_hdr_out[79:64] <= 16'h0000;            // misc
                tlp_hdr_out[63:48] <= 16'hBEEF;           // Completer ID
                tlp_hdr_out[47:32] <= {2'b00, 14'd4};     // Status + ByteCount
                tlp_hdr_out[31:16] <= req_id_r;           // Requester ID
                tlp_hdr_out[15:8]  <= tag_r;              // Tag
                tlp_hdr_out[7:0]   <= 8'h00;              // Lower addr

                tlp_data_out  <= cpl_data;
                tlp_valid_out <= 1'b1;
                tlp_last_out  <= 1'b1;
                cpl_pending   <= 1'b0;

                $display("[EP] CplD: tag=%0d data=0x%08h",
                    tag_r, cpl_data);
            end
            else if (tlp_valid_out && tlp_ack_in) begin
                tlp_valid_out <= 1'b0;
            end
        end
    end

endmodule
