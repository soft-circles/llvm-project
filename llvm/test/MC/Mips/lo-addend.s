# RUN: llvm-mc -triple=mips -mcpu=mips3 %s | FileCheck %s --check-prefix=ASM
# RUN: llvm-mc -triple=mips -mcpu=mips3 -filetype=obj %s -o - \
# RUN:   | llvm-objdump -dr - | FileCheck %s --check-prefix=O32
# RUN: llvm-mc -triple=mips64 -mcpu=mips3 -filetype=obj %s -o - \
# RUN:   | llvm-objdump -dr - | FileCheck %s --check-prefix=N64
# RUN: not llvm-mc -triple=mips -mcpu=mips3 --defsym ERR=1 %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefix=ERR --implicit-check-not=error:

## GAS reads "%lo(X) + E" as "%lo(X + E)", and takes a load or store whose
## address has no base register as one based on $zero. The encodings and
## relocations match GNU as 2.47 (-march=vr4300, -mabi=32 and -mabi=64).

	.set noreorder
	.text
# ASM: lhu $9, %lo(data+28)($zero)
# O32:      94 09 00 1e  lhu $9, 0x1e($zero)
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      94 09 00 00  lhu $9, 0x0($zero)
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0x1e
	lhu $9, %lo(data) + 28
# ASM: lhu $9, %lo(data+28)($zero)
# O32:      94 09 00 1e  lhu $9, 0x1e($zero)
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      94 09 00 00  lhu $9, 0x0($zero)
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0x1e
	lhu $9, %lo(data) + 28($0)
# ASM: sw $9, %lo(data-4)($zero)
# O32:      ac 09 ff fe  sw $9, -0x2($zero)
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      ac 09 00 00  sw $9, 0x0($zero)
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data-0x2
	sw $9, %lo(data) - 4
# ASM: addiu $2, $2, %lo(data+12)
# O32:      24 42 00 0e  addiu $2, $2, 0xe
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      24 42 00 00  addiu $2, $2, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0xe
	addiu $2, $2, %lo(data) + 16 - 4
## A leading '-' applies to the first term only.
# ASM: addiu $2, $2, %lo(data-2)
# O32:      24 42 00 00  addiu $2, $2, 0x0
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      24 42 00 00  addiu $2, $2, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data{{$}}
	addiu $2, $2, %lo(data) - 4 + 2
## An addend wider than 16 bits.
# ASM: lw $9, %lo(data+65536)($2)
# O32:      8c 49 00 02  lw $9, 0x2($2)
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      8c 49 00 00  lw $9, 0x0($2)
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0x10002
	lw $9, %lo(data) + 0x10000($2)
## A full address with no base register is the lui/lw pair.
# O32:      3c 09 00 00  lui $9, 0x0
# O32-NEXT:   R_MIPS_HI16 .data
# O32-NEXT: 8d 29 00 06  lw $9, 0x6($9)
# O32-NEXT:   R_MIPS_LO16 .data
	lw $9, (data) + 4

.ifdef ERR
## Only a plain %lo takes an addend after it. %lo(%neg(%gp_rel(X))) is a
## GP-offset relocation, which an addend would turn into a plain LO16.
# ERR: :[[#@LINE+1]]:41: error: unexpected token in argument list
	addiu $2, $2, %lo(%neg(%gp_rel(data))) + 4
# ERR: :[[#@LINE+1]]:10: error: expected memory with 32-bit signed offset
	lhu $9, %hi(data) + 4
.endif

	.data
	.byte 1, 2
data:
	.byte 3
