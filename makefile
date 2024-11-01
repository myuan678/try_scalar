RTL_COMPILE_OUTPUT 	= $(TOY_SCALAR_PATH)/work/rtl_compile

TIMESTAMP			= $(shell date +%Y%m%d_%H%M_%S)
GIT_REVISION 		= $(shell git show -s --pretty=format:%h)
.PHONY: compile lint

compile:
	mkdir -p $(RTL_COMPILE_OUTPUT)
	cd $(RTL_COMPILE_OUTPUT) ;vcs -kdb -full64 -debug_access -sverilog -f $(SIM_FILELIST) +lint=PCWM +lint=TFIPC-L +define+TOY_SIM

# wsl compile
comp:
	mkdir -p $(RTL_COMPILE_OUTPUT)
	cd $(RTL_COMPILE_OUTPUT) ;vcs -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed -kdb -lca -full64 -debug_access -sverilog -f $(SIM_FILELIST) +lint=PCWM +lint=TFIPC-L +define+TOY_SIM

lint:
	fde -file $(TOY_SCALAR_PATH)/qc/lint.tcl -flow lint

isa:
	cd ./rv_isa_test/build ;ctest -j64


dhry:
	${RTL_COMPILE_OUTPUT}/simv +HEX=${RV_TEST_PATH}/hello_world/build/dhrystone_itcm.hex +DATA_HEX=${RV_TEST_PATH}/hello_world/build/dhrystone_dtcm.hex +TIMEOUT=200000 +WAVE +PC=pc_trace.log | tee benchmark_output/dhry/$(GIT_REVISION)_$(TIMESTAMP).log

#dhry_try:
#	${RTL_COMPILE_OUTPUT}/simv +HEX=${RV_TEST_PATH}/isa/rv32ui-p-addi_itcm.hex +DATA_HEX=${RV_TEST_PATH}/isa/rv32ui-p-addi_dtcm.hex +TIMEOUT=200000 +WAVE +PC=pc_trace.log | tee benchmark_output/dhry/$(GIT_REVISION)_$(TIMESTAMP).log
#rv32ui-p-addi_itcm.hex
#rv32ui-p-andi_itcm.hex
#rv32ud-p-fadd_itcm.hex

ttest:
	${RTL_COMPILE_OUTPUT}/simv +HEX=${RV_TEST_PATH}/isa/rv32ui-p-add_itcm.hex +DATA_HEX=${RV_TEST_PATH}/isa/rv32ui-p-add_data.hex +TIMEOUT=200000 +WAVE +PC=pc_trace.log | tee benchmark_output/dhry/$(GIT_REVISION)_$(TIMESTAMP).log


dhry_test:
	${RTL_COMPILE_OUTPUT}/simv +HEX=${RV_TEST_PATH}/hello_world_backup/build/dhrystone_itcm.hex +DATA_HEX=${RV_TEST_PATH}/hello_world_backup/build/dhrystone_dtcm.hex +TIMEOUT=2000000 | tee benchmark_output/dhry/$(GIT_REVISION)_$(TIMESTAMP).log


cm:
<<<<<<< HEAD
	${RTL_COMPILE_OUTPUT}/simv +HEX=${RV_TEST_PATH}/hello_world/build/coremark_itcm.hex +DATA_HEX=${RV_TEST_PATH}/hello_world/build/coremark_dtcm.hex  +TIMEOUT=0 +PC=pccm_trace.log | tee benchmark_output/cm/$(GIT_REVISION)_$(TIMESTAMP).log

cm_test:
	${RTL_COMPILE_OUTPUT}/simv +HEX=/data/usr/huangt/hello_world_ht/toy_bm/coremark_itcm.hex +DATA_HEX=/data/usr/huangt/hello_world_ht/toy_bm/coremark_dtcm.hex  +TIMEOUT=0 +PC=pc_trace.log | tee benchmark_output/cm/$(GIT_REVISION)_$(TIMESTAMP).log

=======
	${RTL_COMPILE_OUTPUT}/simv +HEX=${RV_TEST_PATH}/hello_world/build/coremark_itcm.hex +DATA_HEX=${RV_TEST_PATH}/hello_world/build/coremark_dtcm.hex  +TIMEOUT=0 +PC=pc_trace.log | tee benchmark_output/cm/$(GIT_REVISION)_$(TIMESTAMP).log
cm_test:
	${RTL_COMPILE_OUTPUT}/simv +HEX=/data/usr/huangt/hello_world_ht/toy_bm/coremark_itcm.hex +DATA_HEX=/data/usr/huangt/hello_world_ht/toy_bm/coremark_dtcm.hex  +TIMEOUT=0 +PC=pc_trace.log | tee benchmark_output/cm/$(GIT_REVISION)_$(TIMESTAMP).log
>>>>>>> 89e66991d0bf01e1b1c749468c20af396b652198
cm_backup:
	${RTL_COMPILE_OUTPUT}/simv  +HEX=${RV_TEST_PATH}/hello_world_backup/build/coremark_itcm.hex +DATA_HEX=${RV_TEST_PATH}/hello_world_backup/build/coremark_dtcm.hex  +TIMEOUT=0 | tee benchmark_output/cm/$(GIT_REVISION)_$(TIMESTAMP).log

verdi:
	verdi -sv -f $(SIM_FILELIST) -ssf wave.fsdb -dbdir $(RTL_COMPILE_OUTPUT)/simv.daidir