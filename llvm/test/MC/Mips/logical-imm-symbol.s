# RUN: llvm-mc -triple=mips -mcpu=mips3 -filetype=obj %s -o - \
# RUN:   | llvm-objdump -dr - | FileCheck %s --check-prefix=O32
# RUN: llvm-mc -triple=mips64 -mcpu=mips3 -filetype=obj %s -o - \
# RUN:   | llvm-objdump -dr - | FileCheck %s --check-prefix=N64

## GAS relocates a symbol in the immediate of an I-type instruction with
## R_MIPS_LO16, lui included. A REL addend keeps its low 16 bits and a RELA one
## all of them. The encodings and relocations match GNU as 2.47
## (-march=vr4300, -mabi=32 and -mabi=64).

	.set noreorder
	.text
# O32:      34 63 00 04  ori $3, $3, 0x4
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      34 63 00 00  ori $3, $3, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0x4
	ori $3, $3, data
# O32:      30 63 23 49  andi $3, $3, 0x2349
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      30 63 00 00  andi $3, $3, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0x12349
	andi $3, $3, data+0x12345
# O32:      38 63 00 04  xori $3, $3, 0x4
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      38 63 00 00  xori $3, $3, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0x4
	xori $3, $3, data
# O32:      28 63 00 04  slti $3, $3, 0x4
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      28 63 00 00  slti $3, $3, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0x4
	slti $3, $3, data
# O32:      2c 63 00 04  sltiu $3, $3, 0x4
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      2c 63 00 00  sltiu $3, $3, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0x4
	sltiu $3, $3, data
# O32:      64 63 00 04  daddiu $3, $3, 0x4
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      64 63 00 00  daddiu $3, $3, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0x4
	daddiu $3, $3, data
# O32:      3c 03 00 04  lui $3, 0x4
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      3c 03 00 00  lui $3, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data+0x4
	lui $3, data
# O32:      24 63 00 00  addiu $3, $3, 0x0
# O32-NEXT:   R_MIPS_LO16 .data
# N64:      24 63 00 00  addiu $3, $3, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE .data{{$}}
	addiu $3, $3, data-4
# O32:      34 63 00 00  ori $3, $3, 0x0
# O32-NEXT:   R_MIPS_LO16 ext
# N64:      34 63 00 00  ori $3, $3, 0x0
# N64-NEXT:   R_MIPS_LO16/R_MIPS_NONE/R_MIPS_NONE ext
	ori $3, $3, ext
## A difference that layout resolves needs no relocation.
# O32:      34 63 00 08  ori $3, $3, 0x8
# O32-NOT:  R_MIPS
# N64:      34 63 00 08  ori $3, $3, 0x8
# N64-NOT:  R_MIPS
	ori $3, $3, (e - s)

	.data
	.word 0
data:	.word 0
s:	.space 8
e:
