verdiSetActWin -dock widgetDock_<Message>
simSetSimulator "-vcssv" -exec \
<<<<<<< HEAD
           "/data/usr/xuemy/try_scalar/try_scalar/work/rtl_compile/simv" -args \
           "+HEX=/tools/hurj/riscv-proj/hello_world/build/dhrystone_itcm.hex +DATA_HEX=/tools/hurj/riscv-proj/hello_world/build/dhrystone_dtcm.hex +TIMEOUT=200000 +WAVE +PC=pc_trace.log"
debImport "-sv" "-f" "/data/usr/xuemy/try_scalar/try_scalar/rtl/sim.f" "-dbdir" \
          "/data/usr/xuemy/try_scalar/try_scalar/work/rtl_compile/simv.daidir"
=======
           "/data/usr/xuemy/8fetch_ooo/toy_scalar/work/rtl_compile/simv" -args \
           "+HEX=/tools/hurj/riscv-proj/isa/rv32ui-p-addi_itcm.hex +DATA_HEX=/tools/hurj/riscv-proj/isa/rv32ui-p-addi_dtcm.hex +TIMEOUT=200000 +WAVE +PC=pc_trace.log"
debImport "-sv" "-f" "/data/usr/xuemy/8fetch_ooo/toy_scalar/rtl/sim.f" "-dbdir" \
          "/data/usr/xuemy/8fetch_ooo/toy_scalar/work/rtl_compile/simv.daidir"
debLoadSimResult /data/usr/xuemy/8fetch_ooo/toy_scalar/wave.fsdb
wvCreateWindow
verdiWindowResize -win $_Verdi_1 "0" "0" "800" "578"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "toy_top" -win $_nTrace1
srcSetScope "toy_top" -delim "." -win $_nTrace1
srcHBSelect "toy_top" -win $_nTrace1
srcDeselectAll -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcDeselectAll -win $_nTrace1
srcSelect -signal "inst_mem_req_sideband" -line 16 -pos 1 -win $_nTrace1
srcHBSelect "toy_top.u_toy_scalar" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
>>>>>>> 89e66991d0bf01e1b1c749468c20af396b652198
