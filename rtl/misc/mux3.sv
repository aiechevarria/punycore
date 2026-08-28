//==============================================================================
// File:        mux3.sv
// Description: 3:1 multiplexer.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-28
//==============================================================================
import general_config::*;

module mux3 (
    input logic [general_config::DATA_WIDTH - 1:0]  in0, in1, in2,
    input logic [1:0]                               ctrl,
    output logic [general_config::DATA_WIDTH - 1:0] out
);

always_comb begin
    case (ctr)
        2'b00:              out = in0;
        2'b01:              out = in1;
        2'b10:              out = in2;
        default:            out = 'x;
    endcase
end
endmodule