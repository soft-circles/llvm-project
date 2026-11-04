# RUN: llvm-mc -triple=mips -filetype=obj %s -o - \
# RUN:   | llvm-objdump -t -s -j .data -j .sdata - | FileCheck %s

## The other directives GAS aligns to their size, directive names in any case,
## and the section directives that turn the alignment back on after
## ".align 0" and drop the labels waiting for it. The symbols and bytes match
## GNU as 2.47.

# CHECK:      00000004 l .data 00000000 f
# CHECK-NEXT: 00000008 l .data 00000000 s
# CHECK-NEXT: 00000010 l .data 00000000 d
# CHECK-NEXT: 00000020 l .data 00000000 q
# CHECK-NEXT: 00000028 l .data 00000000 g
# CHECK-NEXT: 0000002c l .data 00000000 w
# CHECK-NEXT: 00000032 l .data 00000000 h
# CHECK-NEXT: 00000038 l .data 00000000 sec
# CHECK-NEXT: 00000040 l .data 00000000 push
# CHECK-NEXT: 00000048 l .data 00000000 prev
# CHECK-NEXT: 00000050 l .data 00000000 sub
# CHECK-NEXT: 00000004 l .sdata 00000000 sd
# CHECK-NEXT: 00000055 l .data 00000000 stay
# CHECK-NEXT: 00000058 l .data 00000000 after
# CHECK-NEXT: 0000005c l .data 00000003 foo
# CHECK-NEXT: 00000003 l *ABS* 00000000 len
# CHECK-NEXT: 0000005f l .data 00000000 dot
# CHECK-NEXT: 00000060 l .data 00000000 bar
# CHECK:      Contents of section .data:
# CHECK-NEXT:  0000 01000000 3f800000 40000000 00000000
# CHECK-NEXT:  0010 3ff00000 00000000 01000000 00000000
# CHECK-NEXT:  0020 00000000 00000004 00000005 00000006
# CHECK-NEXT:  0030 01000007 01000000 00000008 01000000
# CHECK-NEXT:  0040 00000009 01000000 0000000a 01000000
# CHECK-NEXT:  0050 0000000b 01000000 0000000c 01020300
# CHECK-NEXT:  0060 00000003 0000005f
# CHECK-NOT:   Contents
# CHECK:      Contents of section .sdata:
# CHECK-NEXT:  0000 01000000 0000000d

	.data
	.byte 1
f:	.float 1.0
s:	.single 2.0
d:	.double 1.0
	.byte 1
q:	.quad 4
g:	.gpword 5
w:	.WORD 6
	.byte 1
h:	.Half 7

## Each section directive turns the alignment back on, even when it names the
## section already current.
	.byte 1
	.align 0
	.section .data
sec:	.word 8
	.byte 1
	.align 0
	.pushsection .data
	.popsection
push:	.word 9
	.byte 1
	.align 0
	.text
	.previous
prev:	.word 10
	.byte 1
	.align 0
	.subsection 0
sub:	.word 11
	.sdata
	.byte 1
	.align 0
	.sdata
sd:	.word 13

## A label left behind by a section switch stays put.
	.data
	.byte 1
stay:
	.text
	nop
	.data
after:	.word 12

## The temporary labels behind "." are not moved, so sizes and offsets
## measured with it don't count the padding.
foo:	.byte 1, 2, 3
	.size foo, . - foo
len = . - foo
dot = .
bar:	.word len
	.word dot
