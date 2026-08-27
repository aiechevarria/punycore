//==============================================================================
// File:        immediate_extender.sv
// Description: Reconstructs and extends immediates based on the encoding type of the instruction
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

import operations::*;

module control_unit (
    input   logic [DATA_WIDTH - 1:0]    insn;           // The entire instruction
    input   immediate_type_t            immed_type;     // Type of the immediate
    output  logic [DATA_WIDTH - 1:0]    result;         // The extended immediate
);

always_comb begin
    logic                       sign = insn[31];    // The sign bit is always present on the last 32nd bit of the insn. This simplifies sing extension
    logic [DATA_WIDTH - 1:0]    extracted;          // The immediate that has been extracted from the instruction

    // Check docs/encoding/0immediate_reconstruction.png
    unique case (immed_type)
        IMMED_TYPE_I: begin
            result[0]       = insn[20];
            result[4:1]     = insn[24:21];
            result[10:5]    = insn[30:25];
        end
        
        IMMED_TYPE_S: begin
            result[0]       = insn[7];
            result[4:1]     = insn[11:8];
            result[10:5]    = insn[30:25];
        end
        
        // https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html#1-1-5-2-conditional-branches
        // "The 12-bit B-immediate encodes signed offsets in multiples of 2 bytes" and "The conditional branch range is ±4 KiB."
        IMMED_TYPE_B: begin
            result[0]       = 1'b0;
            result[4:1]     = insn[11:8];
            result[10:5]    = insn[30:25];
            result[11]      = insn[7];
        end

        IMMED_TYPE_U: begin
            result[11:0]    = 12'b0;
            result[19:12]   = insn[19:12];
            result[30:20]   = insn[30:20];
            result[31]      = sign;
        end

        IMMED_TYPE_J: begin
            result[0]       = 1'b0;
            result[4:1]     = insn[24:21];
            result[10:5]    = insn[30:25];
            result[11]      = insn[20];
            result[19:12]   = insn[19:12];
        end
    endcase

    // Finally, sign extend when required
    if (immed_type == IMMED_TYPE_I || immed_type == IMMED_TYPE_S)   result[31:11] = {21{sign}};
    else if (immed_type == IMMED_TYPE_B)                            result[31:12] = {20{sign}};
    else if (immed_type == IMMED_TYPE_J)                            result[31:20] = {12{sign}};
end
endmodule