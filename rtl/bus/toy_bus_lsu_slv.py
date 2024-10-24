# pylint: disable =unused-wildcard-import
from uhdl.uhdl.core import *
# pylint: enable  =unused-wildcard-import

# from .Bundle import LwnocBundle


class ToyCoreSlv(Component):

    def __init__(self, node, fwd_pld_type, bwd_pld_type, forward=True):
        super().__init__()
        self.topo_node = node


        # IO Define
        self.in0_req_vld    = Input(UInt(1))
        self.in0_req_rdy    = Output(UInt(1))
        self.in0_req_addr   = Input(UInt(32))
        self.in0_req_data   = Input(UInt(256))
        self.in0_req_strb   = Input(UInt(32))
        self.in0_req_opcode = Input(UInt(1))
        self.in0_req_sideband= Input(UInt(10))

        self.in0_ack_vld    = Output(UInt(1))
        self.in0_ack_rdy    = Input(UInt(1))
        self.in0_ack_data   = Output(UInt(256))
        self.in0_ack_sideband= Output(UInt(10))


        self.out0_req       = fwd_pld_type()
        self.out0_ack       = bwd_pld_type().reverse()

        self.out0_req.vld       += self.in0_req_vld
        self.in0_req_rdy        += self.out0_req.rdy
        self.out0_req.sideband  += self.in0_req_sideband
        self.out0_req.addr      += self.in0_req_addr
        self.out0_req.strb      += self.in0_req_strb
        self.out0_req.data      += self.in0_req_data
        self.out0_req.opcode    += self.in0_req_opcode 
        self.out0_req.src_id    += UInt(4,self.topo_node.nodeid)
        self.out0_req.tgt_id    += \
        When(And(GreaterEqual(self.in0_req_addr,UInt("32'h80000000")),Less(self.in0_req_addr,UInt("32'hA0000000")))).\
            then(UInt(4,2)).\
        when(And(GreaterEqual(self.in0_req_addr,UInt("32'hA0000000")),Less(self.in0_req_addr,UInt("32'hC0000000")))).\
            then(UInt(4,3)).\
        otherwise(UInt(4,4))


        self.in0_ack_vld        += self.out0_ack.vld
        self.out0_ack.rdy       += self.in0_ack_rdy
        self.in0_ack_data       += self.out0_ack.data
        self.in0_ack_sideband   += self.out0_ack.sideband

        # self.clk            = Input(UInt(1))
        # self.rst_n          = Input(UInt(1))
        # self.in0_req        = fwd_pld_type().reverse()
        # self.in0_ack        = bwd_pld_type()

        # self.out0_mem_en     = Output(UInt(1))
        # self.out0_mem_addr   = Output(UInt(32))
        # self.out0_mem_data   = Input(UInt(32))

       #  
        # self.in0_req.rdy += UInt(1,1)

        # self.in0_ack.opcode += UInt(1,0)
        # self.in0_ack.src_id += UInt(4,0)
        # self.in0_ack.tgt_id += UInt(4,0)



        # self.out0_mem_en    += self.in0_req.vld
        # self.out0_mem_addr  += Combine(UInt(4,0),Cut(self.in0_req.addr,29,2))

        # self.in0_ack.data   += self.out0_mem_data


        # self.vld_reg = Reg(UInt(1),self.clk,self.rst_n)

        # self.vld_reg += self.in0_req.vld


        # self.in0_ack.vld += self.vld_reg