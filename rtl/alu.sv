//==============================================================================
// File:        alu.sv
// Description: Simple Arithmetic Logic Unit.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

import operations::*;
import general_config::*;

module alu (
    input   alu_op_t                                                control,     // Signal from the control unit
    input   logic       [general_config::DATA_WIDTH - 1:0]          a,           // Operand A
    input   logic       [general_config::DATA_WIDTH - 1:0]          b,           // Operand B
    output  logic       [general_config::DATA_WIDTH - 1:0]          res          // Result
);

always_comb begin
    // Assign the result depending on the operation
    case (control)
        ALU_OP_ADD:     res = a + b;
        ALU_OP_SUB:     res = a - b;
        ALU_OP_AND:     res = a & b;
        ALU_OP_OR:      res = a | b;
        ALU_OP_XOR:     res = a ^ b;
        ALU_OP_SLL:     res = a << b;
        ALU_OP_SRL:     res = a >> b;
        ALU_OP_SRA:     res = $signed(a) >>> b;

        // TODO SLT and the others
        ALU_OP_PASS1:   res = a;
        ALU_OP_PASS2:   res = b;
        default: res = '0;                    // Return 0 on error to make them more blunt
    endcase
end
    
endmodule