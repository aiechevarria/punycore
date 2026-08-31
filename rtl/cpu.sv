//==============================================================================
// File:        cpu.sv
// Description: The main CPU component. Instantiates and wires all components together.
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-31
//==============================================================================

import operations::*;
import general_config::*;

module cpu (
    input logic                                      reset,  // Sets the PC to 0 and starts execution
    input logic                                      clk
);
    // PC and memories
    logic [general_config::DATA_WIDTH - 1:0]    pc_out, insn_out, data_out;

    // RF
    logic [general_config::DATA_WIDTH - 1:0]    reg1_out, reg2_out;
    
    // Immed extender
    logic [general_config::DATA_WIDTH - 1:0]    immed_out;

    // ALU
    logic                                       alu_carry, alu_ovf;
    logic [general_config::DATA_WIDTH - 1:0]    alu_out;

    // Branch Unit
    logic [general_config::DATA_WIDTH - 1:0]    next_pc, bu_reg_wb;

    // Muxes
    logic [general_config::DATA_WIDTH - 1:0]    mux_alu_b, mux_wd3_in;

    // Control unit
    immediate_type_t                            immed_ctrl;
    alu_op_t                                    alu_ctrl;
    branch_type_t                               branch_type;
    reg_write_src_t                             reg_write_src;
    logic                                       reg_write_en, mem_write_en, alu_src_2;

    // Instantiate and wire all components together
    pc prog_counter (
        .clk(clk),
        .reset(reset),
        .pc_in(next_pc),
        .pc_out(pc_out)
    );

    imem insn_mem (
        .clk(clk),
        .pc_in(pc_out),
        .insn_out(insn_out)
    );

    control_unit cu (
        .insn(insn_out),
        .reg_write_en(reg_write_en),
        .mem_write_en(mem_write_en),
        .reg_write_src(reg_write_src),
        .alu_src_2(alu_src_2),
        .branch_type(branch_type),
        .alu_control(alu_ctrl),
        .immed_control(immed_ctrl)
    );

    register_file rf (
        .clk(clk),
        .ra1(insn_out[19:15]),
        .ra2(insn_out[24:20]),
        .ra3(insn_out[11:7]),
        .we3(reg_write_en),
        .wd3(mux_wd3_in),
        .rd1(reg1_out),
        .rd2(reg2_out)
    );

    immediate_extender immed (
        .insn(insn_out),
        .immed_type(immed_ctrl),
        .result(immed_out)
    );

    mux2 alu_2_mux (
        .in0(reg2_out),
        .in1(immed_out),
        .ctrl(alu_src_2),
        .out(mux_alu_b)
    );

    alu arith (
        .control(alu_ctrl),
        .a(reg1_out),
        .b(mux_alu_b),
        .res(alu_out),
        .carry(alu_carry),
        .signed_ovf(alu_ovf)
    );

    branch_unit bu (
        .branch_type(branch_type),
        .alu_carry(alu_carry),
        .alu_signed_ovf(alu_ovf),
        .alu_output(alu_out),
        .immediate(immed_out),
        .curr_pc(pc_out),
        .next_pc(next_pc),
        .reg_wb(bu_reg_wb)
    );

    dmem data_mem (
        .clk(clk),
        .we(mem_write_en),
        .alu_in(alu_out),
        .reg_in(reg2_out),
        .data_out(data_out)
    );

    mux3 reg_write_mux (
        .in0(data_out),
        .in1(alu_out),
        .in2(bu_reg_wb),
        .ctrl(reg_write_src),
        .out(mux_wd3_in)
    );

endmodule