# RUN: llvm-mc -triple=mips -filetype=obj %s -o - \
# RUN:   | llvm-objdump -s -j .data - | FileCheck %s

## As with .space, a .ds count that isn't constant at parse time, such as one
## that refers to later labels, is resolved after layout. GNU as 2.47 gives the
## same bytes for .ds.b. For a deferred .ds.w or .ds.l it drops the element
## size and fills N bytes; this fills N elements, as a constant count does.

# CHECK:      Contents of section .data:
# CHECK-NEXT:  0000 01000000 00000009 00000000 00000a00
# CHECK-NEXT:  0010 00000000 00000000 00000005 0607
	.data
	.byte 1
	.ds.b (e - s) * 2
	.byte 9
	.ds.w e - s
	.byte 10
	.ds.l e - s
s:
	.byte 5, 6, 7
e:
