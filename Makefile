# Directories
VERILATOR_DIR       = ./verilator
VERILATOR_OBJ_DIR   = ./verilator/obj
RTL_DIR             = ./rtl
PKG_DIR				= $(RTL_DIR)/pkg
TESTS_DIR           = ./tests

# Executables and commands
VERILATOR           = verilator
VERILATOR_TEST_CMD = $(VERILATOR) --binary --timing --assert

# Packages
PACKAGES = \
	$(PKG_DIR)/general_config.sv \
	$(PKG_DIR)/operations.sv

.PHONY: test test-alu test-register-file clean

test: test-alu test-register-file
	@echo "======================"
	@echo " ALL TESTS PASSED"
	@echo "======================"

test-alu:
	$(VERILATOR_TEST_CMD) --Mdir $(VERILATOR_OBJ_DIR)/alu --top-module alu_tb $(PACKAGES) $(RTL_DIR)/alu.sv $(TESTS_DIR)/alu_tb.sv
	$(VERILATOR_OBJ_DIR)/alu/Valu_tb

test-register-file:
	$(VERILATOR_TEST_CMD) --Mdir $(VERILATOR_OBJ_DIR)/register_file --top-module register_file_tb $(PACKAGES) $(RTL_DIR)/register_file.sv $(TESTS_DIR)/register_file_tb.sv
	$(VERILATOR_OBJ_DIR)/register_file/Vregister_file_tb

clean:
	rm -rf $(VERILATOR_OBJ_DIR)