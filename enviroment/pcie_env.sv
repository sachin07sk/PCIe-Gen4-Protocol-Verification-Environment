`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;

class pcie_env extends uvm_env;
  `uvm_component_utils(pcie_env)

  pcie_phy_agent        phy_agt;
  pcie_link_agent       link_agt;
  pcie_trans_agent      trans_agt;
  pcie_flow_ctrl_agent  flow_ctrl_agt;
  pcie_config_agent     config_agt;
  pcie_pwr_mgmt_agent   pwr_mgmt_agt;
  pcie_scoreboard       sb;
  pcie_env_config       env_cnfg;
  pcie_virtual_sequencer vsqr;

  function new(string name = "pcie_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_env_config)::get(this, "", "env_cnfg", env_cnfg))
      `uvm_fatal(get_full_name(), "env config not found")

    if (env_cnfg.has_phy_agent) begin
      uvm_config_db#(pcie_phy_agent_config)::set(this, "phy_agt*", "agt_cnfg", env_cnfg.phy_agt_cnfg);
      phy_agt = pcie_phy_agent::type_id::create("phy_agt", this);
    end
    if (env_cnfg.has_link_agent) begin
      uvm_config_db#(pcie_link_agent_config)::set(this, "link_agt*", "agt_cnfg", env_cnfg.link_agt_cnfg);
      link_agt = pcie_link_agent::type_id::create("link_agt", this);
    end
    if (env_cnfg.has_trans_agent) begin
      uvm_config_db#(pcie_trans_agent_config)::set(this, "trans_agt*", "agt_cnfg", env_cnfg.trans_agt_cnfg);
      trans_agt = pcie_trans_agent::type_id::create("trans_agt", this);
    end
    if (env_cnfg.has_flow_ctrl_agent) begin
      uvm_config_db#(pcie_flow_ctrl_agent_config)::set(this, "flow_ctrl_agt*", "agt_cnfg", env_cnfg.flow_ctrl_agt_cnfg);
      flow_ctrl_agt = pcie_flow_ctrl_agent::type_id::create("flow_ctrl_agt", this);
    end
    if (env_cnfg.has_config_agent) begin
      uvm_config_db#(pcie_config_agent_config)::set(this, "config_agt*", "agt_cnfg", env_cnfg.config_agt_cnfg);
      config_agt = pcie_config_agent::type_id::create("config_agt", this);
    end
    if (env_cnfg.has_pwr_mgmt_agent) begin
      uvm_config_db#(pcie_pwr_mgmt_agent_config)::set(this, "pwr_mgmt_agt*", "agt_cnfg", env_cnfg.pwr_mgmt_agt_cnfg);
      pwr_mgmt_agt = pcie_pwr_mgmt_agent::type_id::create("pwr_mgmt_agt", this);
    end
    if (env_cnfg.has_virtual_sequencer)
      vsqr = pcie_virtual_sequencer::type_id::create("vsqr", this);
    if (env_cnfg.has_scoreboard)
      sb = pcie_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (env_cnfg.has_phy_agent && env_cnfg.has_scoreboard)
      phy_agt.mon.mon_port.connect(sb.ap_phy.analysis_export);
    if (env_cnfg.has_link_agent && env_cnfg.has_scoreboard)
      link_agt.mon.mon_port.connect(sb.ap_link.analysis_export);
    if (env_cnfg.has_trans_agent && env_cnfg.has_scoreboard)
      trans_agt.mon.mon_port.connect(sb.ap_trans.analysis_export);
    if (env_cnfg.has_flow_ctrl_agent && env_cnfg.has_scoreboard)
      flow_ctrl_agt.mon.mon_port.connect(sb.ap_flow_ctrl.analysis_export);
    if (env_cnfg.has_config_agent && env_cnfg.has_scoreboard)
      config_agt.mon.mon_port.connect(sb.ap_config.analysis_export);
    if (env_cnfg.has_pwr_mgmt_agent && env_cnfg.has_scoreboard)
      pwr_mgmt_agt.mon.mon_port.connect(sb.ap_pwr_mgmt.analysis_export);

    if (env_cnfg.has_virtual_sequencer) begin
      if (env_cnfg.has_phy_agent)       vsqr.phy_sqr       = phy_agt.seqr;
      if (env_cnfg.has_link_agent)      vsqr.link_sqr      = link_agt.seqr;
      if (env_cnfg.has_trans_agent)     vsqr.trans_sqr     = trans_agt.seqr;
      if (env_cnfg.has_flow_ctrl_agent) vsqr.flow_ctrl_sqr = flow_ctrl_agt.seqr;
      if (env_cnfg.has_config_agent)    vsqr.config_sqr    = config_agt.seqr;
      if (env_cnfg.has_pwr_mgmt_agent)  vsqr.pwr_mgmt_sqr  = pwr_mgmt_agt.seqr;
    end
  endfunction
endclass
