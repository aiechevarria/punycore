# Directories
VERILATOR_DIR       = ./verilator
VERILATOR_OBJ_DIR   = ./verilator/obj
RTL_DIR             = ./rtl
PKG_DIR				= $(RTL_DIR)/pkg
MISC_DIR			= $(RTL_DIR)/misc
TESTS_DIR           = ./tests

# Executables and commands
VERILATOR           = verilator
VERILATOR_TEST_CMD = $(VERILATOR) --binary --timing --assert

# Packages
PACKAGES = \
	$(PKG_DIR)/general_config.sv \
	$(PKG_DIR)/operations.sv

MISC = \
	$(MISC_DIR)/mux2.sv \
	$(MISC_DIR)/mux3.sv

COMPONENTS = \
	$(RTL_DIR)/alu.sv \
	$(RTL_DIR)/branch_unit.sv \
	$(RTL_DIR)/control_unit.sv \
	$(RTL_DIR)/dmem.sv \
	$(RTL_DIR)/imem.sv \
	$(RTL_DIR)/immediate_extender.sv \
	$(RTL_DIR)/pc.sv \
	$(RTL_DIR)/register_file.sv \

.PHONY: test test-alu test-register-file test_cpu clean

test: test-alu test-register-file test-cpu
	@echo "======================"
	@echo " ALL TESTS PASSED"
	@echo "======================"

test-alu:
	$(VERILATOR_TEST_CMD) --Mdir $(VERILATOR_OBJ_DIR)/alu --top-module alu_tb $(PACKAGES) $(RTL_DIR)/alu.sv $(TESTS_DIR)/alu_tb.sv
	$(VERILATOR_OBJ_DIR)/alu/Valu_tb

test-register-file:
	$(VERILATOR_TEST_CMD) --Mdir $(VERILATOR_OBJ_DIR)/register_file --top-module register_file_tb $(PACKAGES) $(RTL_DIR)/register_file.sv $(TESTS_DIR)/register_file_tb.sv
	$(VERILATOR_OBJ_DIR)/register_file/Vregister_file_tb

test-cpu:
	$(VERILATOR_TEST_CMD) --Mdir $(VERILATOR_OBJ_DIR)/cpu --top-module cpu_tb $(PACKAGES) $(MISC) $(COMPONENTS) $(RTL_DIR)/cpu.sv $(TESTS_DIR)/cpu_tb.sv
	$(VERILATOR_OBJ_DIR)/cpu/Vcpu_tb

clean:
	rm -rf $(VERILATOR_OBJ_DIR)