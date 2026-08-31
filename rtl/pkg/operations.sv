//==============================================================================
// File:        operations.sv
// Description: Operations supported by the processor. Extracted from https://docs.riscv.org/reference/isa/v20260120/unpriv/rv-32-64g.html
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

package operations;
    localparam int ALU_OP_ADDR_WIDTH    = 4;    // Up to 16 ops

    // Complete list of RV32I instructions
    typedef enum logic [5:0] {
        OP_LUI,
        OP_AUIPC,
        OP_JAL,
        OP_JALR,
        OP_BEQ,
        OP_BNE,
        OP_BLT,
        OP_BGE,
        OP_BLTU,
        OP_BGEU,
        OP_LB,
        OP_LH,
        OP_LW,
        OP_LBU,
        OP_LHU,
        OP_SB,
        OP_SH,
        OP_SW,
        OP_ADDI,
        OP_SLTI,
        OP_SLTIU,
        OP_XORI,
        OP_ORI,
        OP_ANDI,
        OP_SLLI,
        OP_SRLI,
        OP_SRAI,
        OP_ADD,
        OP_SUB,
        OP_SLL,
        OP_SLT,
        OP_SLTU,
        OP_XOR,
        OP_SRL,
        OP_SRA,
        OP_OR,
        OP_AND,
        OP_FENCE,
        OP_FENCE_TSO,
        OP_PAUSE,
        OP_ECALL,
        OP_EBREAK,
        OP_ERROR
    } op_t;

    // A simplified subset of the RV32I instructions for the ALU
    typedef enum logic [ALU_OP_ADDR_WIDTH - 1:0] {
        ALU_OP_ADD,
        ALU_OP_SUB,
        ALU_OP_AND,
        ALU_OP_OR,
        ALU_OP_XOR,
        ALU_OP_SLL,
        ALU_OP_SRL,
        ALU_OP_SRA,
        ALU_OP_SLT,
        ALU_OP_PASS1,       // Pasthrough of the first operand
        ALU_OP_PASS2,       // Passthroug of the second operand
        ALU_OP_SLTU
    } alu_op_t;

    // The types of instruction encodings specified on the spec (check docs/encoding/ for details)
    typedef enum logic [3:0] {
        OP_ENC_R,
        OP_ENC_I,
        OP_ENC_S,
        OP_ENC_B,
        OP_ENC_U,
        OP_ENC_J,
        OP_ENC_MISC_MEM,
        OP_ENC_SYSTEM
    } op_encoding_t;

    // In RISC-V, immediates are scattered in separate fields on the instruction. The sign extender must reconstruct these based on the type of instruction
    typedef enum logic [2:0] {
        IMMED_TYPE_I,
        IMMED_TYPE_S,
        IMMED_TYPE_B,
        IMMED_TYPE_U,
        IMMED_TYPE_J
    } immediate_type_t;

    // Registers can store content from the ALU, main memory and the Branch Unit (on JAL/JALR)
    typedef enum logic [1:0] {
        REG_WRITE_SRC_ALU,
        REG_WRITE_SRC_MEM,
        REG_WRITE_SRC_BRANCH
    } reg_write_src_t;

    // Branches are resolved after the ALU phase, some of the control unit logic has to be offloaded to the Branch Unit
    // Knowing the type of branch is important
    typedef enum logic [3:0] {
        BRANCH_TYPE_NONE,           // The instruction is not a branch, increment PC normally
        BRANCH_TYPE_BEQ,
        BRANCH_TYPE_BNE,
        BRANCH_TYPE_BLT,
        BRANCH_TYPE_BGE,
        BRANCH_TYPE_BLTU,
        BRANCH_TYPE_BGEU,
        BRANCH_TYPE_JAL,
        BRANCH_TYPE_JALR,
        BRANCH_TYPE_AUIPC
    } branch_type_t;

    /**
     * Translates the bit-encoded opcode to an enum of type op_t for ease of use.
     *
     * @param op_bits The encoded instruction.
     * @return The op_t equivalent of the instruction
     */
    function automatic op_t get_opcode(logic [DATA_WIDTH - 1:0] op_bits);
        // Extract the other fields 
        logic [3:0] fm = op_bits[31:28];                        // Fence mode
        logic [2:0] funct3 = op_bits[14:12];
        logic [6:0] funct7 = op_bits[31:25];

        // Take a look at the opcode first
        case (op_bits[7 - 1:0])
            7'b0110111:    return OP_LUI;           // These 4 can be infered just from the opcode field itself
            7'b0010111:    return OP_AUIPC;         // The rest require peeking some additional fields
            7'b1101111:    return OP_JAL;
            7'b1100111:    return OP_JALR;
            7'b1100011: begin
                // Branch operations
                unique case (funct3)
                    3'b000:     return OP_BEQ;
                    3'b001:     return OP_BNE;
                    3'b100:     return OP_BLT;
                    3'b101:     return OP_BGE;
                    3'b110:     return OP_BLTU;
                    3'b111:     return OP_BGEU;
                    default:    return OP_ERROR;
                endcase
            end
            7'b0000011: begin
                // Load operations
                case (funct3)
                    3'b000:     return OP_LB;
                    3'b001:     return OP_LH;
                    3'b010:     return OP_LW;
                    3'b100:     return OP_LBU;
                    3'b101:     return OP_LHU;
                    default:    return OP_ERROR;
                endcase
            end
            7'b1000011: begin
                // Store operations
                case (funct3)
                    3'b000:     return OP_SB;
                    3'b001:     return OP_SH;
                    3'b010:     return OP_SW;  
                    default:    return OP_ERROR;
                endcase
            end
            7'b0010011: begin
                // Immediate operations
                case (funct3)
                    3'b000:     return OP_ADDI;
                    3'b010:     return OP_SLTI;
                    3'b011:     return OP_SLTIU;
                    3'b100:     return OP_XORI;
                    3'b110:     return OP_ORI;
                    3'b111:     return OP_ANDI;
                    3'b001:     return OP_SLLI;
                    3'b101: begin
                        // These two require checking funct7
                        unique case (funct7)
                            7'b0000000: return OP_SRLI;
                            7'b0100000: return OP_SRAI;
                            default:    return OP_ERROR;
                        endcase
                    end
                    default:    return OP_ERROR;
                endcase
            end
            7'b0110011: begin
                // Register-register operations
                case (funct3)
                    3'b000: begin
                        case (funct7)
                            7'b0000000: return OP_ADD;
                            7'b0100000: return OP_SUB;
                            default:    return OP_ERROR;
                        endcase
                    end
                    3'b001:     return OP_SLL;
                    3'b010:     return OP_SLT;
                    3'b011:     return OP_SLTU;
                    3'b100:     return OP_XOR;
                    3'b101: begin
                        case (funct7)
                            7'b0000000: return OP_SRL;
                            7'b0100000: return OP_SRA;
                            default:    return OP_ERROR;
                        endcase
                    end
                    3'b110:     return OP_OR;
                    3'b111:     return OP_AND;
                    default:    return OP_ERROR;
                endcase
            end
            7'b0001111: begin
                // Fence operations
                // These are weird and require the special FM field

                // PAUSE is extra weird. It is encoded as a FENCE with fm=0 PW=1, success=0, rd=x0, rs1=x0
                if (fm == 4'b0000 && op_bits[24] == 1 && op_bits[23:20] == 4'b0000 && op_bits[19:15] == 5'b00000 && op_bits[11:7] == 5'b00000)   return OP_PAUSE;

                case (fm)
                    4'b0000:    return OP_FENCE;
                    4'b1000:    return OP_FENCE_TSO;
                    default:    return OP_ERROR;
                endcase
            end

            7'b1110011: begin
                // The LSB of func12 determines the type.
                if (op_bits[20] == 0)   return OP_ECALL;
                else                    return OP_EBREAK;
            end
            default:    return OP_ERROR;
        endcase
    endfunction

    /**
     * Gets the type of encoding for a given opcode.
     *
     * @param op_bits The opcode.
     * @return The op_encoding_t that the opcode uses.
     */
    function automatic op_encoding_t get_opcode_encoding(op_t opcode);
        case (opcode)
            OP_ADD:     return OP_ENC_R;
            OP_SUB:     return OP_ENC_R;
            OP_SLL:     return OP_ENC_R;
            OP_SLT:     return OP_ENC_R;
            OP_SLTU:    return OP_ENC_R;
            OP_XOR:     return OP_ENC_R;
            OP_SRL:     return OP_ENC_R;
            OP_SRA:     return OP_ENC_R;
            OP_OR:      return OP_ENC_R;
            OP_AND:     return OP_ENC_R;

            OP_ADDI:    return OP_ENC_I;
            OP_SLTI:    return OP_ENC_I;
            OP_SLTIU:   return OP_ENC_I;
            OP_XORI:    return OP_ENC_I;
            OP_ORI:     return OP_ENC_I;
            OP_ANDI:    return OP_ENC_I;
            OP_SLLI:    return OP_ENC_I;
            OP_SRLI:    return OP_ENC_I;
            OP_SRAI:    return OP_ENC_I;
            OP_LB:      return OP_ENC_I;
            OP_LH:      return OP_ENC_I;
            OP_LW:      return OP_ENC_I;
            OP_LBU:     return OP_ENC_I;
            OP_LHU:     return OP_ENC_I;
            OP_JALR:    return OP_ENC_I;

            OP_SB:      return OP_ENC_S;
            OP_SH:      return OP_ENC_S;
            OP_SW:      return OP_ENC_S;
            OP_BEQ:     return OP_ENC_B;
            OP_BNE:     return OP_ENC_B;
            OP_BLT:     return OP_ENC_B;
            OP_BGE:     return OP_ENC_B;
            OP_BLTU:    return OP_ENC_B;
            OP_BGEU:    return OP_ENC_B;

            OP_LUI:     return OP_ENC_U;
            OP_AUIPC:   return OP_ENC_U;
            
            OP_JAL:     return OP_ENC_J;
            OP_FENCE:   return OP_ENC_MISC_MEM;
            OP_FENCE_TSO:   return OP_ENC_MISC_MEM;  
            OP_PAUSE:   return OP_ENC_MISC_MEM;

            OP_ECALL:   return OP_ENC_SYSTEM;
            OP_EBREAK:  return OP_ENC_SYSTEM;
            default:    return OP_ENC_R;                // If no match, return whatever to get rid of the warning 
        endcase
    endfunction

    /**
     * Gets the simplified operation the ALU must perform corresponding to an op_t.
     *
     * @param op_bits The opcode.
     * @return The alu_op_t that the opcode corresponds to.
     */
    function automatic alu_op_t get_alu_op(op_t opcode);
        case (opcode)
            // Arithmetic operations
            OP_ADD:         return ALU_OP_ADD;
            OP_ADDI:        return ALU_OP_ADD;
            OP_SUB:         return ALU_OP_SUB;
            OP_XOR:         return ALU_OP_XOR;
            OP_XORI:        return ALU_OP_XOR;
            OP_SLL:         return ALU_OP_SLL;
            OP_SLLI:        return ALU_OP_SLL;
            OP_SRL:         return ALU_OP_SRL;
            OP_SRLI:        return ALU_OP_SRL;
            OP_SRA:         return ALU_OP_SRA;
            OP_SRAI:        return ALU_OP_SRA;
            OP_OR:          return ALU_OP_OR;
            OP_ORI:         return ALU_OP_OR;
            OP_AND:         return ALU_OP_AND;
            OP_ANDI:        return ALU_OP_AND;
            OP_SLT:         return ALU_OP_SLT;
            OP_SLTI:        return ALU_OP_SLT;
            OP_SLTU:        return ALU_OP_SLTU;
            OP_SLTIU:       return ALU_OP_SLTU;
            OP_LUI:         return ALU_OP_PASS2;        // The immediate is ready when reaching the ALU, the immediate unit handles everything.
            
            // Non arithmetic operations that still require the ALU for some calculation (addresses, offsets...)
            // The immediate gets added to the offset
            OP_LB:          return ALU_OP_ADD;
            OP_LH:          return ALU_OP_ADD;
            OP_LW:          return ALU_OP_ADD;
            OP_LBU:         return ALU_OP_ADD;
            OP_LHU:         return ALU_OP_ADD;
            OP_SB:          return ALU_OP_ADD;
            OP_SH:          return ALU_OP_ADD;
            OP_SW:          return ALU_OP_ADD;

            // Unconditional jumps
            OP_JAL:         return ALU_OP_ADD;
            OP_JALR:        return ALU_OP_ADD;
            OP_AUIPC:       return ALU_OP_ADD;

            // Conditional jumps
                // On conditional jumps, the ALU performs half of the comparison hrough substracting both registers
            OP_BEQ:         return ALU_OP_SUB;
            OP_BNE:         return ALU_OP_SUB;
            OP_BLT:         return ALU_OP_SUB;
            OP_BGE:         return ALU_OP_SUB;
            OP_BLTU:        return ALU_OP_SUB;
            OP_BGEU:        return ALU_OP_SUB;

            // Operations that are not currently implemented / do not require the ALU at all
            OP_FENCE:       return ALU_OP_PASS1;
            OP_FENCE_TSO:   return ALU_OP_PASS1;
            OP_PAUSE:       return ALU_OP_PASS1;
            OP_ECALL:       return ALU_OP_PASS1;
            OP_EBREAK:      return ALU_OP_PASS1;
            default:        return ALU_OP_PASS1;
        endcase
    endfunction
endpackage