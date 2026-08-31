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
    input   logic [DATA_WIDTH - 1:0]    insn,           // The entire instruction, it will be decomposed later
    output  logic                       reg_write_en,   // Enables write on registers
    output  logic                       mem_write_en,   // Enables write on memory
    output  reg_write_src_t             reg_write_src,  // If the result to store on a register is from the ALU, memory, or the Branch Unit
    output  logic                       alu_src_2,      // If the second source of the alu should be the contents of a reg or an immediate
    output  branch_type_t               branch_type,    // If the operation is a branch (and the type of branch)
    output  alu_op_t                    alu_control,    // The operation the ALU must perform with the data
    output  immediate_type_t            immed_control   // The type of immediate that the immediate unit must reconstruct
);

// Fetch the type of instruction
op_t opcode = get_opcode(insn);

// Get the encoding type
op_encoding_t encoding = get_opcode_encoding(opcode);

always_comb begin
    // Defaults
    reg_write_en    = 0;
    mem_write_en    = 0;
    reg_write_src   = REG_WRITE_SRC_ALU;
    alu_src_2       = 0;
    branch_type     = BRANCH_TYPE_NONE;
    alu_control     = ALU_OP_ADD;
    immed_control   = IMMED_TYPE_I;

    

    // Set the operation of the ALU
    alu_control = get_alu_op(opcode);

    // Extract the corresponding instruction bits for that encoding
    unique case (encoding)
        OP_ENC_R: begin
            // Register-register instructions
            reg_write_en    = 1;
            reg_write_src   = REG_WRITE_SRC_ALU;
            alu_src_2       = 0;  // Source from a register
        end

        OP_ENC_I: begin
            // Register-immediate instructions
            reg_write_en    = 1;
            alu_src_2       = 1;                // Source from an immediate
            immed_control   = IMMED_TYPE_I;     // Set the immediate type

            if (opcode == OP_JALR) begin
                // JALR is very special because it is a jump encoded in I format
                // TODO check if the immediate is actually TYPE I, "jalr uses a register plus 12-bit signed offset in a similar way to the load and store instructions"
                reg_write_src   = REG_WRITE_SRC_BRANCH;     // Because rd has to contain pc + 4
                branch_type     = BRANCH_TYPE_JALR;
            end else begin 
                reg_write_src   = REG_WRITE_SRC_ALU;
            end
        end

        OP_ENC_S: begin
            // Store instructions
            mem_write_en    = 1;
            alu_src_2       = 1;                    // src2 is used, but is wired to the main memory instead of the ALU's op2. The immediate will be used as a second operand.
            immed_control   = IMMED_TYPE_S;
        end

        OP_ENC_B: begin
            // Branch instructions
            case (opcode) 
                OP_BEQ:     branch_type = BRANCH_TYPE_BEQ;
                OP_BNE:     branch_type = BRANCH_TYPE_BNE;
                OP_BLT:     branch_type = BRANCH_TYPE_BLT;
                OP_BGE:     branch_type = BRANCH_TYPE_BGE;
                OP_BLTU:    branch_type = BRANCH_TYPE_BLTU;
                OP_BGEU:    branch_type = BRANCH_TYPE_BGEU;
                default:    branch_type = BRANCH_TYPE_BEQ;
            endcase
            immed_control = IMMED_TYPE_B;
        end

        OP_ENC_U: begin
            // Upper immediate instructions
            immed_control = IMMED_TYPE_U;

            // LUI takes an immediate, left-shifts it by 12 and sends it to rd
            if (opcode == OP_LUI) begin
                reg_write_en    = 1;
                alu_src_2       = 1;
            end else begin
                // AUIPC. Same as LUI, but it ends up in the PC
                branch_type = BRANCH_TYPE_AUIPC;
            end
        end

        OP_ENC_J: begin
            // This is pretty much just JAL
            reg_write_en    = 1;
            reg_write_src   = REG_WRITE_SRC_BRANCH;     // Because rd has to contain pc + 4
            immed_control   = IMMED_TYPE_J;
            branch_type     = BRANCH_TYPE_JAL;
        end

        OP_ENC_MISC_MEM: begin
            // We do not have to worry about these for now.
        end

        OP_ENC_SYSTEM: begin
            // We also do not worry about these.
        end
    endcase
end
    
endmodule