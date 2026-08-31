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
    input   alu_op_t                                                control,        // Signal from the control unit
    input   logic       [general_config::DATA_WIDTH - 1:0]          a,              // Operand A
    input   logic       [general_config::DATA_WIDTH - 1:0]          b,              // Operand B
    output  logic       [general_config::DATA_WIDTH - 1:0]          res,            // Result
    output  logic                                                   carry,          // For unsigned values, if there is a carry bit (on addition, overflow) 
    output  logic                                                   signed_ovf      // For signed values, if both operands have the same sign and the result does not (also overflow)
);

always_comb begin
    // Add an extra bit for arithmetic operations
    logic [general_config::DATA_WIDTH:0] ext_res = 33'b0;
    carry = 0;
    signed_ovf = 0;

     // Assign the result depending on the operation
    case (control)
        // The ALU knows no difference between signedness on the numbers that are being processed, since arithmetic instructions do not have are signed/unsigned variants.
        // For comparisons and particular instructions that depend on signedness, the ALU must be able to detect carry bits and sign overflow and pass them forward
        // i.e. If the user issues an unsigned compare, then both numbers must be unsigned values, and the branch unit must compare the carry bit
        ALU_OP_ADD: begin
            // To detect these two, we perform addition and substraction with additional bits
            ext_res = {1'b0, a} + {1'b0, b};

            // The result gets mapped as usual
            res = ext_res[general_config::DATA_WIDTH - 1:0];
            
            // The last bit represents the carry, if these were unsigned numbers and this bit were 1, there would be overflow
            carry = ext_res[general_config::DATA_WIDTH];

            // For signed we cannot check the last bit because of a fundamental reason: we do not know which numbers are signed or not, therefore, we cannot perform sign-extension upon adding both numbers
            // Luckily, sign overflow can only happen if both numbers have the same sign (implementable with a XOR as seen below) and if the result has different sign that any of the operands.
            signed_ovf = ~(a[31] ^ b[31]) & (res[31] ^ a[31]);
        end
        ALU_OP_SUB: begin
            // Again subtraction with additional bits cannot be done in an straightforward way because ambiguity in signedness.
            // Instead we perform an addition as before, but changing the sign on the second operand by performing two's complement. 
            ext_res = {1'b0, a} + {1'b0, ~b} + 33'd1;       // Add 1 on the lsb (with 32 trailing 0s) 
            res = ext_res[general_config::DATA_WIDTH - 1:0];

            carry = ext_res[general_config::DATA_WIDTH];

            // Same as before, but the negation can be skipped 
            signed_ovf = (a[31] ^ b[31]) & (res[31] ^ a[31]);
        end
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