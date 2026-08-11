//==============================================================================
// File:        operations.sv
// Description: Operations supported by the processor.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

package operations;
    localparam int ALU_OP_ADDR_WIDTH = 4;     // Up to 16 ops

    typedef enum logic [ALU_OP_ADDR_WIDTH - 1:0] {
        ALU_ADD,
        ALU_SUB,
        ALU_AND,
        ALU_OR,
        ALU_XOR,
        ALU_SLL,
        ALU_SRL,
        ALU_SRA
    } alu_op_t;
endpackage