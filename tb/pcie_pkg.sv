// ============================================
// PCIe Shared Package Definitions
// Author: Saravana Kumar T J A
// ============================================
`ifndef PCIE_PKG_SV
`define PCIE_PKG_SV

package pcie_pkg;
    typedef enum bit [2:0] {
        FMT_3DW_NODATA = 3'b000,
        FMT_3DW_DATA   = 3'b010
    } tlp_fmt_t;

    typedef enum bit [4:0] {
        TLP_MEM_REQ = 5'b00000,
        TLP_CFG_REQ = 5'b00100
    } tlp_type_t;

    function automatic string get_tlp_name(bit [2:0] fmt, bit [4:0] tlp_type);
        if (tlp_type == 5'b00000) return (fmt[1]) ? "MemWr" : "MemRd";
        if (tlp_type == 5'b00100) return (fmt[1]) ? "CfgWr0" : "CfgRd0";
        return "UNKNOWN_TLP";
    endfunction
endpackage

`endif
