# RUN: llvm-mc -triple=mips -filetype=obj %s -o - \
# RUN:   | llvm-objdump -t -s -j .text -j .data - | FileCheck %s
# RUN: llvm-mc -triple=mips %s | FileCheck %s --check-prefix=ASM
# RUN: llvm-mc -triple=mips %s | llvm-mc -triple=mips -filetype=obj - -o - \
# RUN:   | llvm-objdump -t -s -j .text -j .data - | FileCheck %s
# RUN: not llvm-mc -triple=mips --defsym ERR=1 %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefix=ERR --implicit-check-not=error:

## As in GAS, .align moves the labels at the current position past its
## padding; .p2align and .balign don't. An alignment of 0, given as any
## absolute expression, turns off the automatic alignment of data. The symbols
## and bytes match GNU as 2.47, apart from the maximum operand, which this GAS
## doesn't take.

# CHECK:      00000008 l .data 00000000 a
# CHECK-NEXT: 00000009 l .data 00000000 p
# CHECK-NEXT: 00000011 l .data 00000000 b
# CHECK-NEXT: 0000001c l .data 00000000 f
# CHECK-NEXT: 0000001e l .data 00000000 u
# CHECK-NEXT: 00000000 l *ABS* 00000000 Z
# CHECK-NEXT: 00000020 l .data 00000000 z
# CHECK-NEXT: 00000022 l .data 00000000 m
# CHECK-NEXT: 00000008 l .text 00000000 t
# CHECK:      Contents of section .text:
# CHECK-NEXT:  0000 00000000 01000000 00000000
# CHECK:      Contents of section .data:
# CHECK-NEXT:  0000 01000000 00000000 01000000 00000000
# CHECK-NEXT:  0010 01000000 00000000 01555555 01000101
# CHECK-NEXT:  0020 000102

# ASM:      a:
# ASM-NEXT:   .align 3
# ASM:      f:
# ASM-NEXT:   .align 2, 85
# ASM:        .align 0
# ASM:      m:
# ASM-NEXT:   .align 3, , 4

	.data
	.byte 1
a:	.align 3
	.byte 1
p:	.p2align 3
	.byte 1
b:	.balign 8
	.byte 1
f:	.align 2, 0x55
	.byte 1
u:	.ALIGN 1
	.byte 1
Z = 0
	.align Z
	.byte 1
z:	.half 1
## Seven bytes of padding are more than the maximum of 4, so there are none.
m:	.align 3,,4
	.byte 2

## In code the padding is nops.
	.text
	nop
	.byte 1
t:	.align 3
	nop

.ifdef ERR
# ERR: :[[#@LINE+1]]:9: error: invalid alignment value
	.align 32
# ERR: :[[#@LINE+1]]:9: error: invalid alignment value
	.align -1
# ERR: :[[#@LINE+1]]:12: error: alignment directive can never be satisfied in this many bytes, ignoring maximum bytes expression
	.align 3,,0
# ERR: :[[#@LINE+1]]:9: error: expected absolute expression
	.align undefined
.endif
