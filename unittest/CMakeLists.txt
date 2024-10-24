function(post_build TARGET)
     set( OUTPUT_DIR     ${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname})
    #get_filename_component(elfname ${srcfile} NAME_WE)
     add_custom_target(${elfname}.bin ALL
            DEPENDS ${TARGET}
            #COMMAND ${CMAKE_OBJCOPY} -Obinary ${OUTPUT_DIR}/${TARGET}.elf ${OUTPUT_DIR}/${TARGET}.bin
            #COMMAND ${CMAKE_OBJCOPY} -Oihex --change-addresses=-4    ${elfname}.elf ${elfname}.hex
            #COMMAND hexdump -v -e '"%08x\\\n"' ${TARGET}.bin > ${TARGET}.hex
            COMMAND ${CMAKE_OBJDUMP} -D -m riscv:rv32 ${OUTPUT_DIR}/${TARGET}.elf > ${OUTPUT_DIR}/${TARGET}.asm



            COMMAND ${CMAKE_OBJCOPY} -O  verilog--only-section=.itcm ${OUTPUT_DIR}/${TARGET}.elf ${OUTPUT_DIR}/${TARGET}_itcm.hex


            #COMMAND timeout 1s /tools/zdchen/riscv-proj/riscv-isa-sim/build/spike -d -l --log=${OUTPUT_DIR}/spike.log --isa=RV32I --debug-cmd=dump_reg.spike.cmd ${OUTPUT_DIR}/${TARGET}.elf > reg.dump 2>&1

            )
endfunction()



function(post_build_spike TARGET)
     set( OUTPUT_DIR     ${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname})
     add_custom_target(${elfname}_spike_post ALL
          DEPENDS ${TARGET}
          COMMAND ${CMAKE_OBJDUMP} -D -m riscv:rv32 ${OUTPUT_DIR}/${TARGET}.elf > ${OUTPUT_DIR}/${TARGET}.asm
          #COMMAND ${CMAKE_OBJCOPY} -O verilog --only-section=.itcm ${OUTPUT_DIR}/${TARGET}.elf ${OUTPUT_DIR}/${TARGET}_itcm.hex
          #COMMAND timeout 1s /tools/zdchen/riscv-proj/riscv-isa-sim/build/spike -d -l --log=${OUTPUT_DIR}/spike.log --isa=RV32I --debug-cmd=dump_reg.spike.cmd ${OUTPUT_DIR}/${TARGET}.elf > reg.dump 2>&1
          )
endfunction()


function(post_build_toy TARGET)
     set( OUTPUT_DIR     ${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname})
     add_custom_target(${elfname}_toy_post ALL
          DEPENDS ${TARGET}
          COMMAND ${CMAKE_OBJDUMP} -D -m riscv:rv32 ${OUTPUT_DIR}/${TARGET}.elf > ${OUTPUT_DIR}/${TARGET}.asm
          COMMAND ${CMAKE_OBJCOPY} --verilog-data-width 4 --reverse-bytes=4 -O verilog --change-section-address .itcm=0x0 --only-section=.itcm ${OUTPUT_DIR}/${TARGET}.elf ${OUTPUT_DIR}/${TARGET}_itcm.hex
          )
endfunction()







#set(CMAKE_C_COMPILER riscv64-unknown-elf-gcc)





cmake_minimum_required(VERSION 3.0.0)

project(unittest VERSION 0.1.0)


##################################################################################################################################################


include(CMakeForceCompiler)


FIND_FILE( RISCV_XPACK_GCC_COMPILER "riscv64-unknown-elf-gcc" PATHS ENV INCLUDE)
set( RISCV_GCC_COMPILER ${RISCV_XPACK_GCC_COMPILER})



message( "RISC-V GCC found: ${RISCV_GCC_COMPILER}")

get_filename_component(RISCV_TOOLCHAIN_BIN_PATH ${RISCV_GCC_COMPILER} DIRECTORY)
get_filename_component(RISCV_TOOLCHAIN_BIN_GCC ${RISCV_GCC_COMPILER} NAME_WE)
get_filename_component(RISCV_TOOLCHAIN_BIN_EXT ${RISCV_GCC_COMPILER} EXT)

message( "RISC-V GCC Path: ${RISCV_TOOLCHAIN_BIN_PATH}" )


message("${RISCV_TOOLCHAIN_BIN_GCC}")
STRING(REGEX REPLACE "-gcc" "-" CROSS_COMPILE ${RISCV_TOOLCHAIN_BIN_GCC})
message( "RISC-V Cross Compile: ${CROSS_COMPILE}" )

# The Generic system name is used for embedded targets (targets without OS) in
# CMake
set( CMAKE_SYSTEM_NAME          Generic )
set( CMAKE_SYSTEM_PROCESSOR     rv32i )
set( CMAKE_EXECUTABLE_SUFFIX    ".elf")

# specify the cross compiler. We force the compiler so that CMake doesn't
# attempt to build a simple test program as this will fail without us using
# the -nostartfiles option on the command line
#CMAKE_FORCE_C_COMPILER( "${RISCV_TOOLCHAIN_BIN_PATH}/${CROSS_COMPILE}gcc${RISCV_TOOLCHAIN_BIN_EXT}" GNU )
#CMAKE_FORCE_CXX_COMPILER( "${RISCV_TOOLCHAIN_BIN_PATH}/${CROSS_COMPILE}g++${RISCV_TOOLCHAIN_BIN_EXT}" GNU )
set(CMAKE_ASM_COMPILER {CROSS_COMPILE}gcc )
set(CMAKE_AR ${CROSS_COMPILE}ar)
set(CMAKE_ASM_COMPILER ${CROSS_COMPILE}gcc)
set(CMAKE_C_COMPILER ${CROSS_COMPILE}gcc)
set(CMAKE_CXX_COMPILER ${CROSS_COMPILE}g++)

# We must set the OBJCOPY setting into cache so that it's available to the
# whole project. Otherwise, this does not get set into the CACHE and therefore
# the build doesn't know what the OBJCOPY filepath is
set( CMAKE_OBJCOPY      ${RISCV_TOOLCHAIN_BIN_PATH}/${CROSS_COMPILE}objcopy
     CACHE FILEPATH "The toolchain objcopy command " FORCE )

set( CMAKE_OBJDUMP      ${RISCV_TOOLCHAIN_BIN_PATH}/${CROSS_COMPILE}objdump
     CACHE FILEPATH "The toolchain objdump command " FORCE )

# Set the common build flags

# Set the CMAKE C flags (which should also be used by the assembler!
#set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g" )
set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=${CMAKE_SYSTEM_PROCESSOR} -mabi=ilp32 -nostdlib -nostartfiles -Wno-attributes" )
#set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=${CMAKE_SYSTEM_PROCESSOR} -mabi=ilp32 -nostdlib -nostartfiles -Ttext=0" )

set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS}" CACHE STRING "" )
set( CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}" CACHE STRING "" )
set( CMAKE_ASM_FLAGS "${CMAKE_C_FLAGS}" CACHE STRING "" )
#set( CMAKE_EXE_LINKER_FLAGS   "${CMAKE_EXE_LINKER_FLAGS}  -Wl,-m elf32lriscv -march=${CMAKE_SYSTEM_PROCESSOR}    -nostartfiles   " )
set( CMAKE_EXE_LINKER_FLAGS   "${CMAKE_EXE_LINKER_FLAGS}  ")

#################################################################################################################################################3

include_directories("${PROJECT_BINARY_DIR}")

enable_language(ASM)

# Find all *.s files and store in list native_srcs
file(GLOB_RECURSE native_srcs RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/*.s")
foreach(srcfile IN LISTS native_srcs)
    # Get file name without directory
    message("find src: ${srcfile}")
    get_filename_component(elfname ${srcfile} NAME_WE)
    
    # build for spike
    add_executable(${elfname}_spike ${srcfile})
    set_target_properties(${elfname}_spike PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname})
    target_link_options(${elfname}_spike PRIVATE -Wl,-melf32lriscv -Wl,-T spike.ld -Wl,-Map=${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname}/${elfname}_spike.map )#-Wl,-T toy.ld)
    post_build_spike(${elfname}_spike)

    # build for toy
    add_executable(${elfname}_toy ${srcfile})
    set_target_properties(${elfname}_toy PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname})
    target_link_options(${elfname}_toy PRIVATE -Wl,-melf32lriscv -Wl,-T toy.ld -Wl,-Map=${CMAKE_CURRENT_SOURCE_DIR}/build/${elfname}/${elfname}_toy.map )#-Wl,-T toy.ld)
    post_build_toy(${elfname}_toy)

endforeach()


#add_executable("assembly_to_hex" "sanity_wenv.s")
# set_target_linker("assembly_to_hex" "")




# function(set_target_linker TARGET LINKER_SCRIPT)
#     if(CMAKE_C_COMPILER_ID STREQUAL "IAR")
#         target_link_options(${TARGET} PRIVATE --config ${LINKER_SCRIPT})
#     elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
#         message("hello")
#         #target_link_options(${TARGET} PRIVATE -T${LINKER_SCRIPT})
#         #target_link_options(${TARGET} PRIVATE -Wl,-Map=${TARGET}.map)
#         set_target_properties(${TARGET} PROPERTIES SUFFIX "elf")
#     else()
#         message(FATAL_ERROR "Unknown CMAKE_C_COMPILER_ID $CMAKE_C_COMPILER_ID}")
#     endif()
# endfunction()





# usage
# cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/rv32imac.cmake ../

# Look for GCC in path
# https://xpack.github.io/riscv-none-embed-gcc/
#FIND_FILE( RISCV_XPACK_GCC_COMPILER_EXE "riscv-none-embed-gcc.exe" PATHS ENV INCLUDE)
#FIND_FILE( RISCV_XPACK_GCC_COMPILER "riscv-none-embed-gcc" PATHS ENV INCLUDE)
# New versions of xpack
#FIND_FILE( RISCV_XPACK_NEW_GCC_COMPILER_EXE "riscv-none-elf-gcc.exe" PATHS ENV INCLUDE)
#FIND_FILE( RISCV_XPACK_NEW_GCC_COMPILER "riscv-none-elf-gcc" PATHS ENV INCLUDE)

# Look for RISC-V github GCC
# https://github.com/riscv/riscv-gnu-toolchain
#FIND_FILE( RISCV_XPACK_GCC_COMPILER_EXT "riscv64-unknown-elf-gcc.exe" PATHS ENV INCLUDE)



# Select which is found
# if (EXISTS ${RISCV_XPACK_NEW_GCC_COMPILER})
# set( RISCV_GCC_COMPILER ${RISCV_XPACK_NEW_GCC_COMPILER})
# elseif (EXISTS ${RISCV_XPACK_GCC_NEW_COMPILER_EXE})
# set( RISCV_GCC_COMPILER ${RISCV_XPACK_NEW_GCC_COMPILER_EXE})
# elseif (EXISTS ${RISCV_XPACK_GCC_COMPILER})
# set( RISCV_GCC_COMPILER ${RISCV_XPACK_GCC_COMPILER})
# elseif (EXISTS ${RISCV_XPACK_GCC_COMPILER_EXE})
# set( RISCV_GCC_COMPILER ${RISCV_XPACK_GCC_COMPILER_EXE})
# #elseif (EXISTS ${RISCV_GITHUB_GCC_COMPILER})
# #set( RISCV_GCC_COMPILER ${RISCV_GITHUB_GCC_COMPILER})
# #elseif (EXISTS ${RISCV_GITHUB_GCC_COMPILER_EXE})
# #set( RISCV_GCC_COMPILER ${RISCV_GITHUB_GCC_COMPILER_EXE})
# else()
# message(FATAL_ERROR "RISC-V GCC not found. ${RISCV_GITHUB_GCC_COMPILER} ${RISCV_XPACK_GCC_COMPILER} ${RISCV_GITHUB_GCC_COMPILER_EXE} ${RISCV_XPACK_GCC_COMPILER_EXE}")
# endif()


# if(CMAKE_C_COMPILER_ID STREQUAL "IAR")
# add_custom_target(${TARGET}.bin ALL
#         DEPENDS ${TARGET}
#         COMMAND ${CMAKE_IAR_ELFTOOL} --bin ${TARGET}elf ${TARGET}.bin)
# elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")

# get_filename_component(elfname ${srcfile} NAME_WE)
# add_custom_target(${elfname}.bin ALL
#         DEPENDS ${TARGET}
#         COMMAND ${CMAKE_OBJCOPY} -Obinary   ${elfname}.elf ${elfname}.bin
#         #COMMAND ${CMAKE_OBJCOPY} -Oihex --change-addresses=-4    ${elfname}.elf ${elfname}.hex
#         COMMAND hexdump -v -e '"%08x\\\n"' ${elfname}.bin > ${elfname}.hex
#         COMMAND ${CMAKE_OBJDUMP} -D -b binary -m riscv:rv32 ${elfname}.bin > ${elfname}.asm
#         )
# else()
# message(FATAL_ERROR "Unknown CMAKE_C_COMPILER ID $CMAKE_C_COMPILER_ID]")
# endif()