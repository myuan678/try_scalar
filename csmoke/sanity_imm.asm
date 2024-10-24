
main.elf:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <main>:
   0:	ff010113          	addi	sp,sp,-16
   4:	00812623          	sw	s0,12(sp)
   8:	01010413          	addi	s0,sp,16
   c:	00000793          	li	a5,0
  10:	00078513          	mv	a0,a5
  14:	00c12403          	lw	s0,12(sp)
  18:	01010113          	addi	sp,sp,16
  1c:	00008067          	ret

Disassembly of section .comment:

00000000 <.comment>:
   0:	3a434347          	fmsub.d	ft6,ft6,ft4,ft7,rmm
   4:	2820                	fld	fs0,80(s0)
   6:	2029                	jal	10 <main+0x10>
   8:	2e39                	jal	326 <main+0x326>
   a:	00302e33          	sgtz	t3,gp

Disassembly of section .riscv.attributes:

00000000 <.riscv.attributes>:
   0:	1b41                	addi	s6,s6,-16
   2:	0000                	unimp
   4:	7200                	flw	fs0,32(a2)
   6:	7369                	lui	t1,0xffffa
   8:	01007663          	bgeu	zero,a6,14 <main+0x14>
   c:	0011                	c.nop	4
   e:	0000                	unimp
  10:	1004                	addi	s1,sp,32
  12:	7205                	lui	tp,0xfffe1
  14:	3376                	fld	ft6,376(sp)
  16:	6932                	flw	fs2,12(sp)
  18:	7032                	flw	ft0,44(sp)
  1a:	0030                	addi	a2,sp,8
