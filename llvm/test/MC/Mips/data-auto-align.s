# RUN: llvm-mc -triple=mips -filetype=obj %s -o - \
# RUN:   | llvm-objdump -t -s -j .text -j .data - | FileCheck %s
# RUN: llvm-mc -triple=mips %s | FileCheck %s --check-prefix=ASM

## GAS aligns .half, .short, .hword, .word, .int, .long and .dword data to its
## size, and moves the labels at the current position to the aligned address.
## .2byte, .4byte and .8byte are not aligned. ".align 0" turns this off until
## the next nonzero .align or section change. The symbols and bytes match
## GNU as 2.47.

# CHECK:      00000001 l .data 00000000 a
# CHECK-NEXT: 00000004 l .data 00000000 b
# CHECK-NEXT: 00000008 l .data 00000000 c
# CHECK-NEXT: 0000000c l .data 00000000 d
# CHECK-NEXT: 0000000f l .data 00000000 e
# CHECK-NEXT: 00000014 l .data 00000000 f
# CHECK-NEXT: 0000001c l .data 00000000 g
# CHECK-NEXT: 00000024 l .data 00000000 h
# CHECK-NEXT: 00000029 l .data 00000000 i
# CHECK-NEXT: 00000038 l .data 00000000 j
# CHECK-NEXT: 00000038 l .data 00000000 k
# CHECK-NEXT: 00000041 l .data 00000000 l
# CHECK-NEXT: 00000048 l .data 00000000 m
# CHECK-NEXT: 00000050 l .data 00000000 n
# CHECK-NEXT: 00000055 l .data 00000000 q
# CHECK-NEXT: 00000058 l .data 00000000 o
# CHECK-NEXT: 00000002 l .text 00000000 p
# CHECK:      Contents of section .text:
# CHECK-NEXT:  0000 01000010
# CHECK:      Contents of section .data:
# CHECK-NEXT:  0000 01000201 00030100 00040100 00050100
# CHECK-NEXT:  0010 00000601 00000007 01000000 00000008
# CHECK-NEXT:  0020 01000000 00000009 01000000 00000000
# CHECK-NEXT:  0030 0a010000 00000000 00000000 0000000b
# CHECK-NEXT:  0040 01000000 0c010000 0000000d 01010000
# CHECK-NEXT:  0050 0000000e 01780000 0000000f

## The text form prints the padding after the label.
# ASM:      a:
# ASM-NEXT:   .2byte 2
# ASM:      b:
# ASM-NEXT:   .p2align 1, 0x0
# ASM-NEXT:   .2byte 3
# ASM:      l:
# ASM-NEXT:   .4byte 12
# ASM:      m:
# ASM-NEXT:   .p2align 2, 0x0
# ASM-NEXT:   .4byte 13

	.data
	.byte 1
a:	.2byte 2
	.byte 1
b:	.short 3
	.byte 1
c:	.hword 4
	.byte 1
d:	.half 5
	.byte 1
e:	.4byte 6
	.byte 1
f:	.int 7
	.byte 1
g:	.long 8
	.byte 1
h:	.word 9
	.byte 1
i:	.8byte 10
	.byte 1
## Both labels move.
j:
k:	.dword 11
	.byte 1
	.align 0
l:	.word 12
	.text
	.data
	.byte 1
m:	.word 13
	.byte 1
	.align 0
	.byte 1
	.align 1
n:	.word 14
	.byte 1
## A label in front of other data stays put.
q:	.ascii "x"
o:	.word 15
	.text
	.byte 1
p:	.half 16
