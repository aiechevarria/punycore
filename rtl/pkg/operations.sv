//==============================================================================
// File:        operations.sv
// Description: Operations supported by the processor. Extracted from https://docs.riscv.org/reference/isa/v20260120/unpriv/rv-32-64g.html
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

package operations;
    localparam int OPCODE_WIDTH         = 7;    // As defined per RV32I
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
        OP_FENCE.TSO,
        OP_PAUSE,
        OP_ECALL,
        OP_EBREAK
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
        IMMED_TYPE_J,
    } immediate_type_t;

    // Branches are resolved after the ALU phase, some of the control unit logic has to be offloaded to the Branch Unit
    // Knowing the type of branch is important
    typedef enum logic [1:0] {
        BRANCH_TYPE_NONE,           // The instruction is not a branch, do pc + 4.
        BRANCH_TYPE_NORMAL,         // Normal, as in just a branch
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
        logic [6:0] funct7 = op_bits[14:12];

        // Take a look at the opcode first
        unique case (op_bits[OPCODE_WIDTH - 1:0])
            OPCODE_WIDTH'b0110111:    return  OP_LUI;           // These 4 can be infered just from the opcode field itself
            OPCODE_WIDTH'b0010111:    return  OP_AUIPC;         // The rest require peeking some additional fields
            OPCODE_WIDTH'b1101111:    return  OP_JAL;
            OPCODE_WIDTH'b1100111:    return  OP_JALR;
            OPCODE_WIDTH'b1100011: begin
                // Branch operations
                unique case (funct3)
                    3'b000:    return  OP_BEQ;
                    3'b001:    return  OP_BNE;
                    3'b100:    return  OP_BLT;
                    3'b101:    return  OP_BGE;
                    3'b110:    return  OP_BLTU;
                    3'b111:    return  OP_BGEU;
                endcase
            end
            OPCODE_WIDTH'b0000011: begin
                // Load operations
                unique case (funct3)
                    3'b000:    return  OP_LB;
                    3'b001:    return  OP_LH;
                    3'b010:    return  OP_LW;
                    3'b100:    return  OP_LBU;
                    3'b101:    return  OP_LHU;
                endcase
            end
            OPCODE_WIDTH'b1000011: begin
                // Store operations
                unique case (funct3)
                    3'b000:    return  OP_SB;
                    3'b001:    return  OP_SH;
                    3'b010:    return  OP_SW;
                endcase
            end
            OPCODE_WIDTH'b0010011: begin
                // Immediate operations
                unique case (funct3)
                    3'b000:    return  OP_ADDI;
                    3'b010:    return  OP_SLTI;
                    3'b011:    return  OP_SLTIU;
                    3'b100:    return  OP_XORI;
                    3'b110:    return  OP_ORI;
                    3'b111:    return  OP_ANDI;
                    3'b001:    return  OP_SLLI;
                    3'b101: begin
                        // These two require checking funct7
                        unique case (funct7)
                            7'b0000000: return OP_SRLI;
                            7'b0100000: return OP_SRAI;
                        endcase
                    end
                endcase
            end
            OPCODE_WIDTH'b0110011: begin
                // Register-register operations
                unique case (funct3)
                    3'b000: begin
                        unique case (funct7)
                            7'b0000000: return OP_ADD;
                            7'b0100000: return OP_SUB;
                        endcase
                    end
                    3'b001:    return  OP_SLL;
                    3'b010:    return  OP_SLT;
                    3'b011:    return  OP_SLTU;
                    3'b100:    return  OP_XOR;
                    3'b101: begin
                        unique case (funct7)
                            7'b0000000: return OP_SRL;
                            7'b0100000: return OP_SRA;
                        endcase
                    end
                    3'b110:    return  OP_OR;
                    3'b111:    return  OP_AND;
                endcase
            end
            OPCODE_WIDTH'b0001111: begin
                // Fence operations
                // These are weird and require the special FM field

                // PAUSE is extra weird. It is encoded as a FENCE with fm=0 PW=1, success=0, rd=x0, rs1=x0
                if (fm == 4'b0000 && op_bits[24] == 1 && op_bits[23:20] = 4'b0000 && op_bits[19:15] == 5'b00000 && op_bits[11:7] == 5'b00000)   return OP_PAUSE;

                unique case (fm)
                    4'b0000:    return OP_FENCE;
                    4'b1000:    return OP_FENCE.TSO;
                endcase
            end

            OPCODE_WIDTH'1110011: begin
                // The LSB of func12 determines the type.
                if (op_bits[20] == 0)   return OP_ECALL;
                else                    return OP_EBREAK;
            end
        endcase
    endfunction

    /**
     * Gets the type of encoding for a given opcode.
     *
     * @param op_bits The opcode.
     * @return The op_encoding_t that the opcode uses.
     */
    function automatic op_encoding_t get_opcode_encoding(op_t opcode);
        unique case(opcode)
            OP_ADD:
            OP_SUB:
            OP_SLL:
            OP_SLT:
            OP_SLTU:
            OP_XOR:
            OP_SRL:
            OP_SRA:
            OP_OR:
            OP_AND:
                return OP_ENC_R;
            OP_ADDI:
            OP_SLTI:
            OP_SLTIU:
            OP_XORI:
            OP_ORI:
            OP_ANDI:
            OP_SLLI:
            OP_SRLI:
            OP_SRAI:
            OP_LB:
            OP_LH:
            OP_LW:
            OP_LBU:
            OP_LHU:
            OP_JALR:
                return OP_ENC_I;
            OP_SB:
            OP_SH:
            OP_SW:
                return OP_ENC_S;
            OP_BEQ:
            OP_BNE:
            OP_BLT:
            OP_BGE:
            OP_BLTU:
            OP_BGEU:
                return OP_ENC_B;
            OP_LUI:
            OP_AUIPC:
                return OP_ENC_U;
            OP_JAL:
                return OP_ENC_J;
            OP_FENCE:
            OP_FENCE.TSO:
            OP_PAUSE:
                return OP_ENC_MISC_MEM;
            OP_ECALL:
            OP_EBREAK:
                return OP_ENC_SYSTEM;
        endcase
    endfunction

    /**
     * Gets the simplified operation the ALU must perform corresponding to an op_t.
     *
     * @param op_bits The opcode.
     * @return The alu_op_t that the opcode corresponds to.
     */
    function automatic alu_op_t get_alu_op(op_t opcode);
        unique case (opcode)
            // Arithmetic operations
            OP_ADD:
            OP_ADDI:
                return ALU_OP_ADD;
            OP_SUB:
                return ALU_OP_SUB;
            OP_XOR:
            OP_XORI:
                return ALU_OP_XOR;
            OP_SLL:
            OP_SLLI:
                return ALU_OP_SLL;
            OP_SRL:
            OP_SRLI:
                return ALU_OP_SRL;
            OP_SRA:
            OP_SRAI:
                return ALU_OP_SRA;
            OP_OR:
            OP_ORI:
                return ALU_OP_OR;
            OP_AND:
            OP_ANDI:
                return ALU_OP_AND;
            OP_SLT:
            OP_SLTI:
                return ALU_OP_SLT;
            OP_SLTU:
            OP_SLTIU:
                return ALU_OP_SLTU;
            OP_LUI:     
                return ALU_OP_PASS2;        // The immediate is ready when reaching the ALU, the immediate unit handles everything.
            
            // Non arithmetic operations that still require the ALU for some calculation (addresses, offsets...)
            OP_LB:
            OP_LH:
            OP_LW:
            OP_LBU:
            OP_LHU:
            OP_SB:
            OP_SH:
            OP_SW:
                return ALU_OP_ADD;          // The immediate gets added to the offset

            // Conditional and unconditional jumps
            OP_JAL:
            OP_JALR:
            OP_BEQ:
            OP_BNE:
            OP_BLT:
            OP_BGE:
            OP_BLTU:
            OP_BGEU:
            OP_AUIPC:
                return ALU_OP_ADD;

            // Operations that are not currently implemented / do not require the ALU at all
            OP_FENCE:
            OP_FENCE.TSO:
            OP_PAUSE:
            OP_ECALL:
            OP_EBREAK:
                return ALU_OP_PASS1;
        endcase
    endfunction
endpackage