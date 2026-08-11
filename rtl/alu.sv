//==============================================================================
// File:        alu.sv
// Description: Simple Arithmetic Logic Unit.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

import operations;
import general_config;

module alu (
    input   alu_op_t    [general_config::DATA_WIDTH - 1:0] control,     // Signal from the control unit
    input   logic       [general_config::DATA_WIDTH - 1:0] a,           // Operand A
    input   logic       [general_config::DATA_WIDTH - 1:0] b,           // Operand B
    output  logic       [general_config::DATA_WIDTH - 1:0] res,         // Result
);

// Assign the result depending on the operation
case (control)
    ALU_ADD: res = a + b;
    ALU_SUB: res = a - b;
    ALU_AND: res = a & b;
    ALU_OR:  res = a | b;
    ALU_XOR: res = a ^ b;
    ALU_SLL: res = a << b;
    ALU_SRL: res = a >> b;
    ALU_SRA: res = $signed(a) >>> b;
    default: res = 0;                    // Return 0 on error to make them more blunt
endcase
    
endmodule