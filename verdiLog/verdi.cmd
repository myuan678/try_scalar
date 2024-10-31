verdiSetActWin -dock widgetDock_<Message>
simSetSimulator "-vcssv" -exec \
           "/data/usr/xuemy/try_scalar/try_scalar/work/rtl_compile/simv" -args \
           "+HEX=/tools/hurj/riscv-proj/hello_world/build/dhrystone_itcm.hex +DATA_HEX=/tools/hurj/riscv-proj/hello_world/build/dhrystone_dtcm.hex +TIMEOUT=200000 +WAVE +PC=pc_trace.log"
debImport "-sv" "-f" "/data/usr/xuemy/try_scalar/try_scalar/rtl/sim.f" "-dbdir" \
          "/data/usr/xuemy/try_scalar/try_scalar/work/rtl_compile/simv.daidir"
