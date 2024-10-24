# pylint: disable =unused-wildcard-import
from uhdl.uhdl.core import *
# pylint: enable  =unused-wildcard-import

# from .Bundle import LwnocBundle


class ToyMemMst(Component):

    def __init__(self, node, fwd_pld_type, bwd_pld_type, forward=True):
        super().__init__()
        self.topo_node = node


        # IO Define
        self.clk            = Input(UInt(1))
        self.rst_n          = Input(UInt(1))
        self.in0_req        = fwd_pld_type().reverse()
        self.in0_ack        = bwd_pld_type()

        self.out0_mem_en            = Output(UInt(1))
        self.out0_mem_addr          = Output(UInt(32))
        self.out0_mem_rd_data       = Input(UInt(256))
        self.out0_mem_wr_data       = Output(UInt(256))
        self.out0_mem_wr_byte_en    = Output(UInt(32))
        self.out0_mem_wr_en         = Output(UInt(1))
        self.out0_mem_req_sideband  = Output(UInt(10))
        self.out0_mem_ack_sideband  = Input(UInt(10))
        


        

        
        self.in0_req.rdy += UInt(1,1)

        self.in0_ack.opcode += UInt(1,0)
        self.in0_ack.src_id += UInt(4,0)
        self.in0_ack.tgt_id += UInt(4,0)



        self.out0_mem_en            += self.in0_req.vld
        self.out0_mem_addr          += Combine(UInt(8,0),Cut(self.in0_req.addr,28,5))
        self.in0_ack.data           += self.out0_mem_rd_data
        self.out0_mem_wr_data       += self.in0_req.data
        self.out0_mem_wr_byte_en    += self.in0_req.strb
        self.out0_mem_wr_en         += self.in0_req.opcode
        self.out0_mem_req_sideband  += self.in0_req.sideband
        self.in0_ack.sideband       += self.out0_mem_ack_sideband

        self.vld_reg = Reg(UInt(1),self.clk,self.rst_n)
        self.vld_reg += And(self.in0_req.vld,Not(self.in0_req.opcode))
        self.in0_ack.vld += self.vld_reg


        self.node_id_reg = Reg(UInt(4,0),self.clk,self.rst_n)
        self.node_id_reg += self.in0_req.src_id
        self.in0_ack.tgt_id += self.node_id_reg

