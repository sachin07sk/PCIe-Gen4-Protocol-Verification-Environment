`include "top.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
class pcie_env_config extends uvm_object;
  `uvm_object_utils(pcie_env_config)

  bit has_phy_agent        = 1;
  bit has_link_agent       = 1;
  bit has_trans_agent      = 1;
  bit has_flow_ctrl_agent  = 1;
  bit has_config_agent     = 1;
  bit has_pwr_mgmt_agent   = 1;
  bit has_scoreboard       = 1;
  bit has_virtual_sequencer = 1;

  pcie_phy_agent_config        phy_agt_cnfg;
  pcie_link_agent_config       link_agt_cnfg;
  pcie_trans_agent_config      trans_agt_cnfg;
  pcie_flow_ctrl_agent_config  flow_ctrl_agt_cnfg;
  pcie_config_agent_config     config_agt_cnfg;
  pcie_pwr_mgmt_agent_config   pwr_mgmt_agt_cnfg;

  function new(string name = "pcie_env_config");
    super.new(name);
  endfunction
endclass
