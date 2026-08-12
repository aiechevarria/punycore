//==============================================================================
// File:        register_file.sv
// Description: RV32I-like register file.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-12
//==============================================================================

import general_config::*;

module register_file (
    input   logic                                               clk,        // Clock
    input   logic       [general_config::REG_ADDR_WIDTH - 1:0]  ra1,        // Register address 1
    input   logic       [general_config::REG_ADDR_WIDTH - 1:0]  ra2,        // Register address 2
    input   logic       [general_config::REG_ADDR_WIDTH - 1:0]  ra3,        // Register address 3 (used exclusively for writeback)
    input   logic                                               we3,        // Write enable on register 3
    input   logic       [general_config::DATA_WIDTH - 1:0]      wd3,        // Writeback on register 3 data
    output  logic       [general_config::DATA_WIDTH - 1:0]      rd1,        // Register output 1
    output  logic       [general_config::DATA_WIDTH - 1:0]      rd2         // Register output 2
);

// Create REG_COUNT - 1 registers that are composed of DATA_WIDTH logic elements
// Register 0 is wired to 0
logic [DATA_WIDTH - 1:0] regs [1: REG_COUNT - 1];

always_ff @(posedge clk) begin
    // If writeback is enabled, store the WD3 content in RA3 (unless the register is 0)
    if (we3 && (ra3 != '0)) regs[ra3] <= wd3;
end

always_comb begin
    // Fetch the requested register's content
    if (ra1 == '0)  rd1 = '0;
    else            rd1 = regs[ra1];

    if (ra2 == '0)  rd2 = '0;
    else            rd2 = regs[ra2];
end

    
endmodule