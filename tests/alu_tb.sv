//==============================================================================
// File:        alu_tb.sv
// Description: ALU testbench
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

import operations::*;
import general_config::*;

module alu_tb;
    alu_op_t                                                control;     // Signal from the control unit
    logic       [general_config::DATA_WIDTH - 1:0]          a;           // Operand A
    logic       [general_config::DATA_WIDTH - 1:0]          b;           // Operand B
    logic       [general_config::DATA_WIDTH - 1:0]          res;         // Result

    alu dut (
        .control(control),
        .a(a),
        .b(b),
        .res(res)
    );

    task automatic test(
        input   alu_op_t                                                tcontrol,     // Signal from the control unit
        input   logic       [general_config::DATA_WIDTH - 1:0]          ta,           // Operand A
        input   logic       [general_config::DATA_WIDTH - 1:0]          tb,           // Operand B
        input   logic       [general_config::DATA_WIDTH - 1:0]          expected     // Result
    );
        a  = ta;
        b  = tb;
        control = tcontrol;
        #1;

        assert(res === expected)
            else $fatal(
                1,
                "FAIL: a=%h b=%h op=%h got=%h expected=%h",
                a, b, control, res, expected
            );
    endtask

    initial begin
        // ADD/SUB
        test(ALU_ADD, 32'd20, 32'd30, 32'd50);
        test(ALU_SUB, 32'd30, 32'd20, 32'd10);

        // AND
        test(ALU_AND, 32'hFFFFFFFF, 32'h12345678, 32'h12345678);
        test(ALU_AND, 32'hAAAAAAAA, 32'h55555555, 32'h00000000);

        // OR
        test(ALU_OR, 32'h00000000, 32'h12345678, 32'h12345678);
        test(ALU_OR, 32'hAAAAAAAA, 32'h55555555, 32'hFFFFFFFF);

        // XOR
        test(ALU_XOR, 32'h12345678, 32'h12345678, 32'h00000000);
        test(ALU_XOR, 32'hFFFFFFFF, 32'h12345678, 32'hEDCBA987);

        // SLL
        test(ALU_SLL, 32'h00000001, 32'd0,  32'h00000001);
        test(ALU_SLL, 32'h00000001, 32'd1,  32'h00000002);
        test(ALU_SLL, 32'h00000001, 32'd31, 32'h80000000);

        // SRL
        test(ALU_SRL, 32'h80000000, 32'd1,  32'h40000000);
        test(ALU_SRL, 32'hFFFFFFFF, 32'd1, 32'h7FFFFFFF);
        test(ALU_SRL, 32'hFFFFFFFF, 32'd31, 32'h00000001);

        // SRA
        test(ALU_SRA, 32'h80000000, 32'd1,  32'hC0000000);
        test(ALU_SRA, 32'h80000000, 32'd31, 32'hFFFFFFFF);
        test(ALU_SRA, 32'hFFFFFFFF, 32'd4,  32'hFFFFFFFF);
        test(ALU_SRA, 32'h7FFFFFFF, 32'd1,  32'h3FFFFFFF);

        // Default
        test(alu_op_t'(4'd15), 32'h12345678, 32'h87654321, 32'h00000000);

        $display("All ALU tests passed!");
        $finish;
    end

endmodule
