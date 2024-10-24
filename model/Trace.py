from prettytable import PrettyTable


import re



class Instruction(object):

    def __init__(self, input_string=None):
        self.pc             = None
        self.content        = None
        self.cycle          = None
        self.jb_occurred    = False
        self.pjb            = False
        self.target_pc      = 0
        if not input_string is None:
            self.parse(input_string)

    def __str__(self):
        return "[pc=%x][inst=%08x][cycle=%d][jb=%d][jb_occurred=%d][b=%d][j=%d][tpc=%08x][pjb=%d]" % (self.pc, self.content, self.cycle, self.is_jb, self.jb_occurred, self.is_branch, self.is_jump, self.target_pc, self.pjb) 
        # return f"[pc=%h][inst=%h][cycle=%d][jb=%d][jb_occurred=%d]" % (self.pc, self.content, self.cycle, self.is_jb, self.jb_occurred) 


    def parse(self, input_string):
        matches = re.findall(r"\[(pc|inst|cycle)=([a-fA-F0-9]+)\]", input_string)
        result = {key: value for key, value in matches}
        self.pc         = int(result['pc'],16)
        self.content    = int(result['inst'],16)
        self.cycle      = int(result['cycle'])

    @property
    def opcode(self):
        return (self.content >> 0) & 0b1111111

    @property
    def funct3(self):
        return (self.content >> 12) & 0b111

    @property
    def is_branch(self):
        return True if (self.opcode == 0b1100011) else False

    @property
    def is_jump(self):
        return True if ((self.opcode == 0b1101111) or (self.opcode == 0b1100111)) else False

    @property
    def is_jb(self):
        return True if (self.is_branch or self.is_jump) else False
    


class Trace(object):

    def __init__(self, filename):
        self.filename = filename
        self.inst_list = []
        self._parse_file()
        self._state_update()

    
    def _parse_file(self):
        with open(self.filename, 'r') as f:
            text_list = f.readlines()
        self.inst_list = [Instruction(x) for x in text_list]


    def _state_update(self):

        inst_num = len(self.inst_list)

        for i in range(0,inst_num-1):
            if(self.inst_list[i].pc + 4 != self.inst_list[i+1].pc):
                self.inst_list[i].jb_occurred = True
                self.inst_list[i].target_pc   = self.inst_list[i+1].pc


    @property
    def inst_num(self):
        return len(self.inst_list)
    
    @property
    def normal_inst_num(self):
        return len([x for x in self.inst_list if not x.is_jb])
    
    @property
    def jump_num(self):
        return len([x for x in self.inst_list if x.is_jump])
    
    @property
    def branch_num(self):
        return len([x for x in self.inst_list if x.is_branch])
    
    @property
    def branch_occur_num(self):
        return len([x for x in self.inst_list if (x.is_branch and x.jb_occurred)])
    
    @property
    def branch_not_occur_num(self):
        return len([x for x in self.inst_list if (x.is_branch and (not x.jb_occurred))])


    def report(self):
        table = PrettyTable()

        table.field_names = ["Inst Type", "Num", "Cycle/Inst", "IPC", "Total Cycle"]



        normal_icost    = 1
        jump_icost      = 2
        bocc_icost      = 2
        bnocc_icost     = 1

        normal_cost     = normal_icost  * self.normal_inst_num
        jump_cost       = jump_icost    * self.jump_num
        bocc_cost       = bocc_icost    * self.branch_occur_num
        bnocc_cost      = bnocc_icost   * self.branch_not_occur_num

        total_cost      = normal_cost + jump_cost + bocc_cost + bnocc_cost
        total_icost     = total_cost/self.inst_num
        
        table.add_row(['Normal'         ,   self.normal_inst_num        ,   normal_icost                    , '-'                               ,  normal_cost      ])
        table.add_row(['Jump'           ,   self.jump_num               ,   jump_icost                      , '-'                               ,  jump_cost        ])
        table.add_row(['Branch Occur'   ,   self.branch_occur_num       ,   bocc_icost                      , '-'                               ,  bocc_cost        ])
        table.add_row(['Branch Not Occ' ,   self.branch_not_occur_num   ,   bnocc_icost                     , '-'                               ,  bnocc_cost       ])
        table.add_row(['Total'          ,   self.inst_num               ,   "{:.2f}".format(total_icost)    , "{:.2f}".format(1/total_icost)    ,  total_cost       ])
        
        return table


if __name__ == "__main__":

    trace = Trace('dhrystone20_core_pc_trace.log')
    print(trace.report())

    trace = Trace('coremark10_all_pc_trace.log')
    print(trace.report())
