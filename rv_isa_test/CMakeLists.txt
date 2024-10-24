cmake_minimum_required(VERSION 2.8)
project(test)
include(CTest)

enable_testing()


set( TEST_FILE_DIR  "$ENV{RV_TEST_PATH}/isa"  )
set( SIMV_PATH      "$ENV{TOY_SCALAR_PATH}/work/rtl_compile/simv"   )

file(GLOB_RECURSE rv32ui_srcs RELATIVE "${TEST_FILE_DIR}" "${TEST_FILE_DIR}/rv32ui*.dump")
file(GLOB_RECURSE rv32um_srcs RELATIVE "${TEST_FILE_DIR}" "${TEST_FILE_DIR}/rv32um*.dump")
file(GLOB_RECURSE rv32uc_srcs RELATIVE "${TEST_FILE_DIR}" "${TEST_FILE_DIR}/rv32uc*.dump")
# file(GLOB_RECURSE rv32ua_srcs RELATIVE "${TEST_FILE_DIR}" "${TEST_FILE_DIR}/rv32ua*.dump")
file(GLOB_RECURSE rv32uf_srcs RELATIVE "${TEST_FILE_DIR}" "${TEST_FILE_DIR}/rv32uf*.dump")



list(APPEND all_srcs ${rv32ui_srcs} ${rv32um_srcs} ${rv32uc_srcs} ${rv32ua_srcs} ${rv32uf_srcs})

foreach(srcfile IN LISTS all_srcs)
    # Get file name without directory
    message("find src: ${srcfile}")
    get_filename_component(test_name ${srcfile} NAME_WE)

    add_test (
        NAME    ${test_name} 
        COMMAND ${SIMV_PATH} -exitstatus +HEX=${TEST_FILE_DIR}/${test_name}_itcm.hex +DATA_HEX=${TEST_FILE_DIR}/${test_name}_data.hex +TIMEOUT=12000
    )

    set_tests_properties(${test_name} PROPERTIES TIMEOUT 240)
endforeach()



    # get_filename_component(elfname ${srcfile} NAME_WE)
   #  
    # # build for spike
    # add_executable(${elfname}_spike ${srcfile})
    # set_target_properties(${elfname}_spike PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname})
    # target_link_options(${elfname}_spike PRIVATE -Wl,-melf32lriscv -Wl,-T spike.ld -Wl,-Map=${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname}/${elfname}_spike.map )#-Wl,-T toy.ld)
    # post_build_spike(${elfname}_spike)

    # # build for toy
    # add_executable(${elfname}_toy ${srcfile})
    # set_target_properties(${elfname}_toy PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname})
    # target_link_options(${elfname}_toy PRIVATE -Wl,-melf32lriscv -Wl,-T toy.ld -Wl,-Map=${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname}/${elfname}_toy.map )#-Wl,-T toy.ld)
    # post_build_toy(${elfname}_toy)

