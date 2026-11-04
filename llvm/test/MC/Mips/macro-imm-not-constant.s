# RUN: not llvm-mc -triple=mips -mcpu=mips32 %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefixes=CHECK,GP32 --implicit-check-not=error:
# RUN: not llvm-mc -triple=mips64 -mcpu=mips3 %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefixes=CHECK,GP64 --implicit-check-not=error:

## These macros expand a constant, so like GAS they reject a symbol ("operand 3
## must be constant"). The 32-bit ones used to read it as 0 (or assert), and the
## and, or, xor and addu forms turned into a single instruction with a LO16
## relocation.

	.set noat
# CHECK: :[[#@LINE+1]]:2: error: instruction requires a CPU feature not currently enabled
	and $3, $3, data
# CHECK: :[[#@LINE+1]]:2: error: instruction requires a CPU feature not currently enabled
	or $3, data
# CHECK: :[[#@LINE+1]]:2: error: instruction requires a CPU feature not currently enabled
	xor $3, $3, %lo(data)
# CHECK: :[[#@LINE+1]]:15: error: expected 32-bit signed immediate
	addu $3, $3, data
# GP32: :[[#@LINE+2]]:14: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:14: error: invalid operand for instruction
	slt $3, $3, data
# GP32: :[[#@LINE+2]]:15: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:15: error: invalid operand for instruction
	sltu $3, $3, data
# GP32: :[[#@LINE+2]]:14: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:14: error: invalid operand for instruction
	nor $3, $3, data
# GP32: :[[#@LINE+2]]:14: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:14: error: invalid operand for instruction
	sge $3, $3, data
# GP32: :[[#@LINE+2]]:15: error: expected 32-bit immediate
# GP64: :[[#@LINE+1]]:15: error: invalid operand for instruction
	sgeu $3, $3, data
# GP32: :[[#@LINE+2]]:14: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:14: error: invalid operand for instruction
	sgt $3, $3, data
# GP32: :[[#@LINE+2]]:15: error: expected 32-bit immediate
# GP64: :[[#@LINE+1]]:15: error: invalid operand for instruction
	sgtu $3, $3, data
# GP32: :[[#@LINE+2]]:14: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:14: error: invalid operand for instruction
	sle $3, $3, data
# GP32: :[[#@LINE+2]]:15: error: expected 32-bit immediate
# GP64: :[[#@LINE+1]]:15: error: invalid operand for instruction
	sleu $3, $3, data
## The 64-bit-only forms.
# CHECK: :[[#@LINE+1]]:11: error: invalid operand for instruction
	ddiv $3, data

	.data
data:
