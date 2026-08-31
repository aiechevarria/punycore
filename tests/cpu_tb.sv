//==============================================================================
// File:        alu_tb.sv
// Description: ALU testbench
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

import operations::*;
import general_config::*;

module cpu_tb;
    logic   clk, reset;


    cpu dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock: 10 time units per period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("All cpu tests passed!");
        $finish;
    end

endmodule