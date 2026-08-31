//==============================================================================
// File:        branch_unit.sv
// Description: Branch Unit for controling the PC wrt. the output of the Control Unit and ALU. Handles the different types of jumps.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-25
//==============================================================================

import operations::*;
import general_config::*;

module branch_unit (
    input   branch_type_t               branch_type,
    input   logic                       alu_carry,
    input   logic                       alu_signed_ovf,
    input   logic [DATA_WIDTH - 1:0]    alu_output,
    input   logic [DATA_WIDTH - 1:0]    immediate,
    input   logic [ADDR_WIDTH - 1:0]    curr_pc,
    output  logic [ADDR_WIDTH - 1:0]    next_pc,
    output  logic [DATA_WIDTH - 1:0]    reg_wb              // This is here exclusively for JAL / JALR, since it requires storing PC + 4 to a GP register
);

always_comb begin
    logic                       is_negative         = alu_output[31] ^ alu_signed_ovf;  // If the nubmer is negative or the sign overflow is active, the comparison is less 
    logic [ADDR_WIDTH - 1:0]    offset              = 32'b0;
    
    unique case (branch_type)
        BRANCH_TYPE_NONE:           offset = (ADDR_WIDTH / 8);                                      // When no branching happens, increment the PC to the next instruction
        BRANCH_TYPE_BEQ:            if (alu_output == 32'b0)            offset = immediate;
        BRANCH_TYPE_BNE:            if (alu_output != 32'b0)            offset = immediate;
        BRANCH_TYPE_BLT:            if (is_negative)                    offset = immediate;
        BRANCH_TYPE_BGE:            if (~is_negative)                   offset = immediate;
        BRANCH_TYPE_BLTU:           if (~alu_carry)                     offset = immediate;         // If the ALU has no carry, the second operand is smaller
        BRANCH_TYPE_BGEU:           if (alu_carry)                      offset = immediate;
        BRANCH_TYPE_JAL:            offset = immediate;                                             // pc += imm
        BRANCH_TYPE_JALR:           offset = alu_output;                                            // pc = rs1 + imm  (performed by the ALU already)
        BRANCH_TYPE_AUIPC:          offset = immediate;                                             // The immediate is already processed by the immediate unit, it can be added safely.
    endcase 

    if (branch_type == BRANCH_TYPE_JALR)    next_pc = offset;               // JALR overwrites the PC without caring about the last state
    else                                    next_pc = curr_pc + offset;

    // Always set but used only in JAL / JALR
    reg_wb = curr_pc + (ADDR_WIDTH / 8);
end
endmodule