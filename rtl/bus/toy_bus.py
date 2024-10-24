from uhdl.uhdl.Demo.lwnoc2 import design
from uhdl.uhdl import *
from uhdl.uhdl.Demo import *

from toy_bus_mem_mst    import ToyMemMst
from toy_bus_lsu_slv    import ToyCoreSlv
#from toy_bus_fetch_slv  import ToyFetchSlv

class ToyBusReq(Bundle,metaclass=design.BundleMeta):

    def __init__(self):
        super().__init__()
        self.vld            = Output(UInt(1))
        self.rdy            = Input(UInt(1))
        self.addr           = Output(UInt(32))
        self.strb           = Output(UInt(32))
        self.data           = Output(UInt(256))
        self.opcode         = Output(UInt(1))
        self.src_id         = Output(UInt(4))
        self.tgt_id         = Output(UInt(4))
        self.sideband       = Output(UInt(10))
        #self.head           = Output(UInt(1))
        #self.tail           = Output(UInt(1))
        


class ToyBusAck(Bundle,metaclass=design.BundleMeta):

    def __init__(self):
        super().__init__()
        self.vld            = Output(UInt(1))
        self.rdy            = Input(UInt(1))
        self.opcode         = Output(UInt(1))
        self.data           = Output(UInt(256))
        self.sideband       = Output(UInt(10))
        self.src_id         = Output(UInt(4))
        self.tgt_id         = Output(UInt(4))
        #self.head           = Output(UInt(1))
        #self.tail           = Output(UInt(1))

N = Network(name='toy_bus')

N.default_interface_forward     = ToyBusReq
N.default_interface_backward    = ToyBusAck
N._lock_arbiter = False

fetch   = Slave     ('fetch'    ,0  , design=ToyCoreSlv     )
lsu     = Slave     ('lsu'      ,1  , design=ToyCoreSlv     )
itcm    = Master    ('itcm'     ,2  , design=ToyMemMst      )
dtcm    = Master    ('dtcm'     ,3  , design=ToyMemMst      )
eslv    = Master    ('eslv'     ,4  , design=ToyMemMst      )

dec_lsu     = Decoder   ('dec_lsu'  ,   10)
dec_fetch   = Decoder   ('dec_fetch',   11)


arb_itcm    = Arbiter   ('arb_itcm' ,   12)
arb_dtcm    = Arbiter   ('arb_dtcm' ,   13)

dec_dmem    = Decoder   ('dec_dmem',    14)


N.add(fetch)
N.add(lsu)

N.add(itcm)
N.add(dtcm)
N.add(eslv)

N.add(dec_fetch)
N.add(dec_lsu)
N.add(dec_dmem)

N.add(arb_dtcm)
N.add(arb_itcm)


N.link(fetch    , dec_fetch )
N.link(lsu      , dec_lsu   )

N.link(dec_fetch, arb_itcm  )
N.link(dec_lsu  , arb_itcm  )
N.link(dec_fetch, arb_dtcm  )
N.link(dec_lsu  , arb_dtcm  )


N.link(arb_itcm  , itcm     )
N.link(arb_dtcm, dec_dmem)
N.link(dec_dmem  , dtcm     )
N.link(dec_dmem  , eslv      )

N._show()
N.rtl_prefix = 'toy_bus'
N.generate_verilog()
N._design.generate_filelist(prefix='$TOY_SCALAR_PATH/rtl/bus',name='toy_bus.f')
N._design.run_lint()