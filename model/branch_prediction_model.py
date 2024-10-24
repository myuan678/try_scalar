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


trace_file_name = 'dhrystone20_core_pc_trace.log'
trace_file_ptr  = open(trace_file_name, 'r')
trace_file_text = trace_file_ptr.readlines()

inst_list = [Instruction(x) for x in trace_file_text]


class BranchPredictor(object):

    def __init__(self):
        self.pc = 0
        self.cnt = 0
        self.predict_num = 0
        self.predict_success_num = 0

    def success(self):
        self.predict_success_num += 1

    def update(self, is_jump, target_pc):
        if is_jump:
            self.pc = target_pc
            if self.cnt <= 2:
                self.cnt += 1
        else:
            if self.cnt >= -1:
                self.cnt -= 1

    def predict_jump(self):
        self.predict_num += 1
        return True if self.cnt >= 0 else False

    def predict_pc(self):
        return self.pc


#################################################################################################

inst_num    = len(inst_list)
jb_inst_num      = 0
jb_taken_num    = 0
current_pc  = 0



#predict_jump = False
#predict_pc = 0

predictor = BranchPredictor()


inst_num = len(inst_list)

for i in range(0,inst_num-1):
    if(inst_list[i].pc + 4 != inst_list[i+1].pc):
        inst_list[i].jb_occurred = True
        inst_list[i].target_pc   = inst_list[i+1].pc


for inst in inst_list:
    if(inst.is_jb):
        inst.pjb = predictor.predict_jump()
        if((predictor.predict_jump() == inst.jb_occurred)) and (predictor.predict_pc() == inst.target_pc):
            predictor.success()
        predictor.update(inst.jb_occurred, inst.target_pc)

for inst in inst_list:
    print(inst)
#print(predictor.predict_num)
#print(predictor.predict_success_num)

        #print(predictor.predict_jump())
        #print(inst.jb_occurred)
        #print(predictor.predict_pc())
        #print(inst.target_pc)

#for inst in inst_list:
#    inst.pc     







# for inst in inst_list:

#     # jump happened
#     if(inst.pc != current_pc + 4):
#         jb_taken_num += 1
#         
#         if(predictor.predict_jump()):
#             predictor.success()


#     # jump not happend
#     else:
#         pass




#     # detect jump
#     if(inst.is_jb):
#         jb_inst_num += 1
#         predict_jump = predictor.predict_jump()
#         predict_pc   = predictor.predict_pc()




#     current_pc = inst.pc

#print("Total %8d jumps."            % jb_taken_num    )
#print("Total %8d jb instructions."  % jb_inst_num)
#print("Total %8d instructions."     % inst_num  )
