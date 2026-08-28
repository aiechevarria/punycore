//==============================================================================
// File:        pc.sv
// Description: Program Counter registry.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-28
//==============================================================================

import general_config::*;

module pc (
    input   logic                                               clk,
    input   logic       [general_config::ADDR_WIDTH - 1:0]      pc_in,
    output  logic       [general_config::ADDR_WIDTH - 1:0]      pc_out
);

logic [DATA_WIDTH - 1:0] pc;

always_ff @(posedge clk) begin
    pc <= pc_in;
end

always_comb begin
    pc_out = pc;
end
endmodule