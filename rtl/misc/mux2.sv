//==============================================================================
// File:        mux2.sv
// Description: 2:1 multiplexer.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-28
//==============================================================================
import general_config::*;

module mux2 (
    input logic [general_config::DATA_WIDTH - 1:0]  in0, in1,
    input logic                                     ctrl,
    output logic [general_config::DATA_WIDTH - 1:0] out
);
    assign out = ctrl ? in0 : in1;
endmodule