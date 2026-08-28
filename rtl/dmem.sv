//==============================================================================
// File:        dmem.sv
// Description: Instruction memory.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-28
//==============================================================================

import general_config::*;

module dmem (
    input   logic                                               clk,
    input   logic                                               we,
    input   logic       [general_config::DATA_WIDTH - 1:0]      alu_in,
    input   logic       [general_config::DATA_WIDTH - 1:0]      reg_in,
    output  logic       [general_config::DATA_WIDTH - 1:0]      data_out
);

logic [DATA_WIDTH - 1:0] dmem [0:9] = '{
    32'h00A0_0093,  // addi x1,  x0, 10
    32'h0140_0113,  // addi x2,  x0, 20
    32'h0020_81B3,  // add  x3,  x1, x2
    32'h4011_0233,  // sub  x4,  x2, x1
    32'h0020_F2B3,  // and  x5,  x1, x2
    32'h0020_E333,  // or   x6,  x1, x2
    32'h0020_C3B3,  // xor  x7,  x1, x2
    32'h0020_94B3,  // sll  x8,  x1, x2
    32'h0011_54B3,  // srl  x9,  x2, x1
    32'h0020_A533   // slt  x10, x1, x2
};

always_ff @(posedge clk) begin
    logic index = alu_in / (DATA_WIDTH / 8);    // Position in the dmem arr.

    data_out = '0;                              // Default output

    // Only read if we == 0
    if (we == 0)    data_out    <= dmem[index];
    else            dmem[index] <= reg_in;
end
endmodule