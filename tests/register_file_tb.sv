//==============================================================================
// File:        alu_tb.sv
// Description: ALU testbench
//
// Author:      Aitor Echevarría Floranes
// Created:     2026-08-11
//==============================================================================

import operations::*;
import general_config::*;

module register_file_tb;
    logic                                               clk;
    logic [general_config::REG_ADDR_WIDTH - 1:0]       ra1;
    logic [general_config::REG_ADDR_WIDTH - 1:0]       ra2;
    logic [general_config::REG_ADDR_WIDTH - 1:0]       ra3;
    logic                                               we3;
    logic [general_config::DATA_WIDTH - 1:0]            wd3;

    logic [general_config::DATA_WIDTH - 1:0]            rd1;
    logic [general_config::DATA_WIDTH - 1:0]            rd2;


    register_file dut (
        .clk(clk),
        .ra1(ra1),
        .ra2(ra2),
        .ra3(ra3),
        .we3(we3),
        .wd3(wd3),
        .rd1(rd1),
        .rd2(rd2)
    );


    // Clock: 10 time units per period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // Write a register and wait for the write to occur
    task automatic write_register(
        input logic [general_config::REG_ADDR_WIDTH - 1:0]  reg_addr,
        input logic [general_config::DATA_WIDTH - 1:0]      data
    );
        ra3 = reg_addr;
        wd3 = data;
        we3 = 1'b1;

        @(posedge clk);
        #1;

        we3 = 1'b0;
    endtask


    // Read two registers and check their values
    task automatic read_registers(
        input logic [general_config::REG_ADDR_WIDTH - 1:0]  reg_addr1,
        input logic [general_config::REG_ADDR_WIDTH - 1:0]  reg_addr2,
        input logic [general_config::DATA_WIDTH - 1:0]      expected1,
        input logic [general_config::DATA_WIDTH - 1:0]      expected2
    );
        ra1 = reg_addr1;
        ra2 = reg_addr2;

        #1;

        assert(rd1 === expected1)
            else $fatal(
                1,
                "FAIL RD1: ra1=%d got=%h expected=%h",
                ra1, rd1, expected1
            );

        assert(rd2 === expected2)
            else $fatal(
                1,
                "FAIL RD2: ra2=%d got=%h expected=%h",
                ra2, rd2, expected2
            );
    endtask


    initial begin

        // ------------------------------------------------------------
        // x0 must always read as zero
        // ------------------------------------------------------------

        read_registers(
            5'd0,
            5'd0,
            32'h00000000,
            32'h00000000
        );


        // ------------------------------------------------------------
        // Basic writes and reads
        // ------------------------------------------------------------

        write_register(5'd1, 32'h12345678);
        read_registers(
            5'd1,
            5'd0,
            32'h12345678,
            32'h00000000
        );


        write_register(5'd2, 32'hDEADBEEF);
        read_registers(
            5'd1,
            5'd2,
            32'h12345678,
            32'hDEADBEEF
        );


        // ------------------------------------------------------------
        // Write a few different registers
        // ------------------------------------------------------------

        write_register(5'd5, 32'hAAAAAAAA);
        write_register(5'd10, 32'h55555555);
        write_register(5'd31, 32'hFFFFFFFF);

        read_registers(
            5'd5,
            5'd10,
            32'hAAAAAAAA,
            32'h55555555
        );

        read_registers(
            5'd31,
            5'd1,
            32'hFFFFFFFF,
            32'h12345678
        );


        // ------------------------------------------------------------
        // Overwrite an existing register
        // ------------------------------------------------------------

        write_register(5'd1, 32'hCAFEBABE);

        read_registers(
            5'd1,
            5'd2,
            32'hCAFEBABE,
            32'hDEADBEEF
        );


        // ------------------------------------------------------------
        // Attempt to write x0
        // x0 must remain zero
        // ------------------------------------------------------------

        write_register(5'd0, 32'hDEADBEEF);

        read_registers(
            5'd0,
            5'd1,
            32'h00000000,
            32'hCAFEBABE
        );


        // ------------------------------------------------------------
        // Writing x0 must not affect other registers
        // ------------------------------------------------------------
        read_registers(
            5'd1,
            5'd31,
            32'hCAFEBABE,
            32'hFFFFFFFF
        );


        $display("All register file tests passed!");
        $finish;
    end

endmodule