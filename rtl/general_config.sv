//==============================================================================
// File:        general_config.sv
// Description: General configuration of the processor.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

package general_config;
    localparam int DATA_WIDTH           = 32;
    localparam int ADDR_WIDTH           = 32;
    localparam int REG_COUNT            = 32;
    localparam int REG_ADDR_WIDTH       = $clog2(REG_COUNT);        // Log2 ceil the number of registers
endpackage