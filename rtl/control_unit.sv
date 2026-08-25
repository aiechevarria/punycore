//==============================================================================
// File:        control_unit.sv
// Description: Main control unit and instruction decode logic. Based on the RV32I 2.1 spec: https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html
//              These others are also useful: https://projectf.io/posts/riscv-cheat-sheet/
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

import operations::*;

module control_unit (
    input   logic [DATA_WIDTH - 1:0]    insn;           // The entire instruction, it will be decomposed later
    output  logic                       reg_write;      // If the result is written to rd
    output  logic                       mem_write;      // If the result is written to memory
    output  logic                       alu_src_2;      // If the second source of the alu should be the contents of a reg or an immediate
    output  branch_type_t               branch_type;    // If the operation is a branch (and the type of branch)
    output  alu_op_t                    alu_control;    // The operation the ALU must perform with the data
    output  immediate_type_t            immed_control;  // The type of immediate that the immediate unit must reconstruct
);

always_comb begin
    // Defaults
    reg_write   = 0;
    mem_write   = 0;
    alu_src_2   = 0;
    branch_type = BRANCH_TYPE_NONE;
    alu_control = ALU_ADD;
    immed_control   = IMMED_TYPE_B;

    // Fetch the type of instruction
    op_t opcode = get_opcode(insn);

    // Get the encoding type
    op_encoding_t encoding = get_opcode_encoding(opcode);

    // Set the operation of the ALU
    alu_control = get_alu_op(opcode);

    // Extract the corresponding instruction bits for that encoding
    unique case (encoding)
        OP_ENC_R: begin
            // Register-register instructions
            reg_write = 1;
            alu_src_2 = 0;  // Source from a register
        end
        OP_ENC_I: begin
            // Register-immediate instructions
            reg_write = 1;
            alu_src_2 = 1;  // Source from an immediate
            immed_control = IMMED_TYPE_I;   // Set the immediate type

            // TODO treat JALR as a jump
        end
        OP_ENC_S: begin
            // Store instructions
            mem_write = 1;
            alu_src_2 = 1;                  // src2 is used, but is wired to the main memory instead of the ALU's op2. The immediate will be used as a second operand.
            immed_control = IMMED_TYPE_S;
        end
        OP_ENC_B: begin
            // Branch instructions
            // TODO Create a Branch Unit that takes the pc, immediate and alu's result. If the op is a branch, use this unit. If the alu produces a 0 result, jump. 
            branch_type = BRANCH_TYPE_NORMAL;
            immed_control = IMMED_TYPE_B;
        end
        OP_ENC_U: begin
            // Upper immediate instructions
            // LUI takes an immediate, left-shifts it by 12 and sends it to rd
            if (encoding == OP_LUI) begin
                reg_write = 1;
                alu_src_2 = 1;
                immed_control = IMMED_TYPE_U;
            else
                // AUIPC. Same as LUI, but it ends up in the PC
                branch_type = BRANCH_TYPE_AUIPC;
                immed_control = IMMED_TYPE_U;
            end
        end
        OP_ENC_J: begin
            // TODO implement the Branch Unit and wire this correspondingly
        end
        OP_ENC_MISC_MEM: begin
            // We do not have to worry about these for now.
        end
        OP_ENC_SYSTEM: begin
            // We also do not worry about these.
        end
    endcase

    // TODO on error insert a NOP (ADDI x0, x0, 0)
end
    
endmodule