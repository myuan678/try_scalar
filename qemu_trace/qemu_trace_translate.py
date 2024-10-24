

def convert_trace_log(trace_log):
    # Split the trace log into sections
    sections = trace_log.split()
    #print(sections)
    #print(sections)
    # Extract relevant information from each section
    zero_key_index = sections.index("pc")
    pc = sections[zero_key_index+1]
    #inst = sections[0].split('[')[1].split('/')[3]
    #reg_idx = int(sections[0].split('[')[1].split('/')[2])
    
    # Extract register values from x0 to x31
    zero_key_index = sections.index("x0/zero")
    #print(zero_key_index)
    #print(sections[63:])
    res = sections[zero_key_index:]
    res = res[1::2]
    #print(res)
    #print(len(res))


    registers = [f"{reg}:{value}" for reg, value in zip(['zo', 'ra', 'sp', 'gp', 'tp', 't0', 't1', 't2',
                                                         's0', 's1', 'a0', 'a1', 'a2', 'a3', 'a4', 'a5',
                                                         'a6', 'a7', 's2', 's3', 's4', 's5', 's6', 's7',
                                                         's8', 's9', 's10', 's11', 't3', 't4', 't5', 't6'],
                                                        res)]

    # Format the output string
    #result = f"[pc={pc}][inst=0][reg idx=0][{ ' '.join(registers)}]"
    result = f"[pc={pc}][{ ' '.join(registers)}]"


    return result


# Example usage
#trace_log = "Trace 0: 0x7fdc68000100 [00000000/0000000080000000/07014003/ff020201] V = 0 pc 80000000 mhartid 00000000 mstatus 00000000 mstatush 00000000 hstatus 00000000 vsstatus 00000000 mip 00000080 mie 00000000 mideleg 00001444 hideleg 00000000 medeleg 00000000 hedeleg 00000000 mtvec 00000000 stvec 00000000 vstvec 00000000 mepc 00000000 sepc 00000000 vsepc 00000000 mcause 00000000 scause 00000000 vscause 00000000 mtval 00000000 stval 00000000 htval 00000000 mtval2 00000000 mscratch 00000000 sscratch 00000000 satp 00000000 x0/zero 00000000 x1/ra 00000000 x2/sp 00000000 x3/gp 00000000 x4/tp 00000000 x5/t0 00000000 x6/t1 00000000 x7/t2 00000000 x8/s0 00000000 x9/s1 00000000 x10/a0 00000000 x11/a1 00000000 x12/a2 00000000 x13/a3 00000000 x14/a4 00000000 x15/a5 00000000 x16/a6 00000000 x17/a7 00000000 x18/s2 00000000 x19/s3 00000000 x20/s4 00000000 x21/s5 00000000 x22/s6 00000000 x23/s7 00000000 x24/s8 00000000 x25/s9 00000000 x26/s10 00000000 x27/s11 00000000 x28/t3 00000000 x29/t4 00000000 x30/t5 00000000 x31/t6 00000000"

#converted_result = convert_trace_log(trace_log)


fr_name = 'dhrystone_qemu_sim_trace.log'
fw_name = 'translated_sim_trace.log'
fr = open(fr_name,'r')
fw = open(fw_name,'w')

text = fr.read()


src_list = text.strip().split('Trace ')
src_list = ['Trace ' + x for x in src_list]
src_list = src_list[1:]

res_list = []
for src in src_list:
    res = convert_trace_log(src) + '\n'
    #res_list.append(res)

    fw.writelines(res)


#print(res_list)


