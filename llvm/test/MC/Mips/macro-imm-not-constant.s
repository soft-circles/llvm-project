# RUN: not llvm-mc -triple=mips -mcpu=mips32 %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefixes=CHECK,GP32 --implicit-check-not=error:
# RUN: not llvm-mc -triple=mips64 -mcpu=mips3 --defsym=GP64=1 %s \
# RUN:   -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefixes=CHECK,GP64 --implicit-check-not=error:
# RUN: llvm-mc -triple=mips -mcpu=mips32 --defsym=OK=1 %s \
# RUN:   | FileCheck %s --check-prefix=OK

## These macros expand a constant, so like GAS they reject a symbol ("operand 3
## must be constant").

.ifdef OK
## A symbol with a constant value is still a constant.
x = 5
# OK:      slti $3, $3, 5
	slt $3, $3, x
# OK-NEXT: andi $3, $3, 5
	and $3, $3, x
# OK-NEXT: addiu $1, $zero, 5
# OK-NEXT: div $zero, $3, $1
	div $3, $3, x
.else
	.set noat
## FIXME: GAS says "operand 3 must be constant"; the microMIPS form is the
## near miss here.
# CHECK: :[[#@LINE+1]]:2: error: instruction requires a CPU feature not currently enabled
	and $3, $3, data
# CHECK: :[[#@LINE+1]]:2: error: instruction requires a CPU feature not currently enabled
	or $3, data
# CHECK: :[[#@LINE+1]]:2: error: instruction requires a CPU feature not currently enabled
	xor $3, $3, %lo(data)
# CHECK: :[[#@LINE+1]]:15: error: expected 32-bit signed immediate
	addu $3, $3, data
# GP32: :[[#@LINE+2]]:14: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:14: error: expected constant immediate
	slt $3, $3, data
# GP32: :[[#@LINE+2]]:15: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:15: error: expected constant immediate
	sltu $3, $3, data
# GP32: :[[#@LINE+2]]:14: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:14: error: expected constant immediate
	nor $3, $3, data
# GP32: :[[#@LINE+2]]:14: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:14: error: expected constant immediate
	sge $3, $3, data
# GP32: :[[#@LINE+2]]:15: error: expected 32-bit immediate
# GP64: :[[#@LINE+1]]:15: error: expected constant immediate
	sgeu $3, $3, data
# GP32: :[[#@LINE+2]]:14: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:14: error: expected constant immediate
	sgt $3, $3, data
# GP32: :[[#@LINE+2]]:15: error: expected 32-bit immediate
# GP64: :[[#@LINE+1]]:15: error: expected constant immediate
	sgtu $3, $3, data
# GP32: :[[#@LINE+2]]:14: error: expected 32-bit signed immediate
# GP64: :[[#@LINE+1]]:14: error: expected constant immediate
	sle $3, $3, data
# GP32: :[[#@LINE+2]]:15: error: expected 32-bit immediate
# GP64: :[[#@LINE+1]]:15: error: expected constant immediate
	sleu $3, $3, data
# CHECK: :[[#@LINE+1]]:14: error: expected 32-bit signed immediate
	div $3, $3, data
# CHECK: :[[#@LINE+1]]:15: error: expected 32-bit signed immediate
	divu $3, $3, data
# CHECK: :[[#@LINE+1]]:14: error: expected 32-bit signed immediate
	rem $3, $3, data
# CHECK: :[[#@LINE+1]]:15: error: expected 32-bit signed immediate
	remu $3, $3, data
# CHECK: :[[#@LINE+1]]:14: error: expected 32-bit signed immediate
	seq $3, $3, data
# CHECK: :[[#@LINE+1]]:14: error: expected 32-bit signed immediate
	sne $3, $3, data
# CHECK: :[[#@LINE+1]]:14: error: expected 32-bit signed immediate
	mul $3, $3, data
.ifdef GP64
## The 64-bit-only forms.
# GP64: :[[#@LINE+1]]:11: error: expected constant immediate
	ddiv $3, data
# GP64: :[[#@LINE+1]]:15: error: expected constant immediate
	ddiv $3, $3, data
# GP64: :[[#@LINE+1]]:12: error: expected constant immediate
	ddivu $3, data
# GP64: :[[#@LINE+1]]:16: error: expected constant immediate
	ddivu $3, $3, data
.endif

	.data
data:
.endif
