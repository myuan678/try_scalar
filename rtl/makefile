RTL_COMPILE_OUTPUT 	= $(TOY_SCALAR_PATH)/work/rtl_compile
SIM_FILELIST 		= $(TOY_SCALAR_PATH)/rtl/sim.f

.PHONY: compile dhry

all:
	vcs -full64 -debug_access -sverilog -f filelist.f +lint=PCWM +lint=TFIPC-L +define+macro=TOY_SIM

compile:
	mkdir -p $(RTL_COMPILE_OUTPUT)
	cd $(RTL_COMPILE_OUTPUT) ;vcs -full64 -debug_access -sverilog -f $(SIM_FILELIST) +lint=PCWM +lint=TFIPC-L +define+macro=TOY_SIM



ver:
	verilator -f filelist.f

verdi:
	verdi -sv -f filelist.f -ssf wave.fsdb

sim_chello:
	./simv +HEX=/tools/zdchen/riscv-proj/hello_world/build/hello_world_itcm.hex +DATA_HEX=/tools/zdchen/riscv-proj/hello_world/build/hello_world_dtcm.hex +DEBUG
	

sim_imm:
	./simv +HEX=../unittest/build/hello_word/hello_word_toy_itcm.hex +DEBUG +WAVE

sim_ls:
	./simv +HEX=../test/sanity_ls.hex

sim_jal:
	./simv +HEX=../test/sanity_jal.hex

sim_wenv:
	./simv +HEX=../test/sanity_wenv.hex

sim_rvload:
	./simv +HEX=../test/sanity_rvload.hex