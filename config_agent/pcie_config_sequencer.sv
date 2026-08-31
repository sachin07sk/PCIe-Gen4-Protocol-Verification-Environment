class pcie_config_sequencer extends uvm_sequencer#(pcie_config_seq_item);
  `uvm_component_utils(pcie_config_sequencer)
  function new(string name = "pcie_config_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
