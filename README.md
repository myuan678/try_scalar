# Toy Scalar


## Environment

在项目根目录下执行:

    source prj.env

设置环境变量和工具，环境变量用在了各种filelist和makefile中。

## Folder

- rtl

这里面存放了所有的rtl。这里面的makefile已经过时，不再维护。

- rv_isa_test

这里面放了一个cmake，用来构建一个并行测试的makefile。使用的测试例是预先编译好存放在lserver上的测试向量。这个cmake会抓取目标目录下的所有测试，构建一个ctest。在这个目录下执行cmake -b build后，会将makefile生成在build目录下。进入build目录执行ctest -j64，会并行执行所有rv官方开源的指令集测试。目前cmake只抓取I和M指令的测试。

这些测试是将一段代码放在rtl上进行运行，如果这段代码能够运行成功（即正常退出）,那么我们就认为这个case pass,目前还没有加入和simulator的逐条指令运行结果比对.



## Makefile

- make compile

编译rtl，将rtl编译到work/rtl_compile下。

- make lint

run lint。

- make dhry

使用编译好的simv跑dhrystone测试，这个测试使用的itcm和dtcm数据，都是预先编译好存在lserver的特定目录下的。因此只能在lserver上运行。

- make cm

跑coremark，其它同上。

- make verdi

看最近一次dhrystone或coremark的波形。


## RTL CLI




## SAM

| ID  | Name       | Start Addr   | Size         | End Addr    |
|-----|------------|--------------|--------------|-------------|
| 1   | ITCM       | 0x8000_0000  | 0x2000_0000  | 0x9FFF_FFFF |
| 2   | DTCM       | 0xA000_0000  | 0x2000_0000  | 0xBFFF_FFFF |
| 3   | Host       | 0xC000_0000  | 0x0000_1000  | 0xC000_0FFF |
| 4   | Uart       | 0xC000_1000  | 0x0000_1000  | 0xC000_1FFF |

## TODO

- 优化MUL/DIV流水线
- 评估时序
- 实现中断
- 实现非法指令异常
- 测试异常和中断
- 随机指令发生器

