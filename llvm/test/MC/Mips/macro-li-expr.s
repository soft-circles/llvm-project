# li and dli of an expression that isn't constant at parse time load its low
# 16 bits with addiu, as GNU as does. The fixup folds after layout or becomes a
# R_MIPS_LO16 relocation (or the one an explicit operator asks for).

# RUN: llvm-mc %s -triple=mips-unknown-elf -mcpu=mips2 -show-encoding \
# RUN:   | FileCheck %s --check-prefix=ASM
# RUN: llvm-mc %s -triple=mips-unknown-elf -mattr=micromips -show-encoding \
# RUN:   | FileCheck %s --check-prefix=MM
# RUN: llvm-mc %s -triple=mips-unknown-elf -mcpu=mips32r2 -mattr=micromips \
# RUN:   -filetype=obj | llvm-objdump -dr --no-show-raw-insn - \
# RUN:   | FileCheck %s --check-prefix=MMOBJ
# RUN: llvm-mc %s -triple=mips-unknown-elf -mcpu=mips2 -filetype=obj \
# RUN:   | llvm-objdump -dr --no-show-raw-insn - \
# RUN:   | FileCheck %s --check-prefixes=OBJ,REL
# RUN: llvm-mc %s -triple=mips64-unknown-elf -mcpu=mips3 -target-abi o64 \
# RUN:   --defsym=DLI=1 -filetype=obj \
# RUN:   | llvm-objdump -dr --no-show-raw-insn - \
# RUN:   | FileCheck %s --check-prefixes=OBJ,REL,DLI
# RUN: llvm-mc %s -triple=mips64-unknown-elf -mcpu=mips3 -target-abi n32 \
# RUN:   --defsym=DLI=1 -filetype=obj \
# RUN:   | llvm-objdump -dr --no-show-raw-insn - \
# RUN:   | FileCheck %s --check-prefixes=OBJ,RELA,DLI
# RUN: llvm-mc %s -triple=mips64-unknown-elf -mcpu=mips3 -target-abi n64 \
# RUN:   --defsym=DLI=1 -filetype=obj \
# RUN:   | llvm-objdump -dr --no-show-raw-insn - \
# RUN:   | FileCheck %s --check-prefixes=OBJ,RELA,DLI

  .text
a:
  nop
b:
# An external symbol.
  li $4, sym
# ASM:      addiu $4, $zero, %lo(sym) # encoding: [0x24,0x04,A,A]
# ASM-NEXT: #   fixup A - offset: 0, value: %lo(sym), kind: fixup_Mips_LO16
# MM:       addiu $4, $zero, %lo(sym) # encoding: [0x30,0x80,A,A]
# MM-NEXT:  #   fixup A - offset: 0, value: %lo(sym), kind: fixup_MICROMIPS_LO16
# MMOBJ:      {{^ +}}4: addiu $4, $zero, 0x0
# MMOBJ-NEXT: {{^[[:space:]]+0+}}4: R_MICROMIPS_LO16 sym{{$}}
# OBJ:      {{^ +}}4: addiu $4, $zero, 0x0
# OBJ-NEXT: {{^[[:space:]]+0+}}4: R_MIPS_LO16{{.*}} sym{{$}}

# An explicit %lo.
  li $4, %lo(sym)
# ASM:      addiu $4, $zero, %lo(sym) # encoding: [0x24,0x04,A,A]
# ASM-NEXT: #   fixup A - offset: 0, value: %lo(sym), kind: fixup_Mips_LO16
# OBJ-NEXT: {{^ +}}8: addiu $4, $zero, 0x0
# OBJ-NEXT: {{^[[:space:]]+0+}}8: R_MIPS_LO16{{.*}} sym{{$}}

# A label difference whose labels are both defined.
  li $4, b-a
# ASM:      addiu $4, $zero, %lo(b-a) # encoding: [0x24,0x04,A,A]
# ASM-NEXT: #   fixup A - offset: 0, value: %lo(b-a), kind: fixup_Mips_LO16
# OBJ-NEXT: {{^ +}}c: addiu $4, $zero, 0x4

# A local label in this section.
  li $4, 1f
1:
# ASM:      addiu $4, $zero, %lo($tmp0) # encoding: [0x24,0x04,A,A]
# ASM-NEXT: #   fixup A - offset: 0, value: %lo($tmp0), kind: fixup_Mips_LO16
# REL-NEXT:  {{^ +}}10: addiu $4, $zero, 0x14
# REL-NEXT:  {{^[[:space:]]+0+}}10: R_MIPS_LO16 .text{{$}}
# RELA-NEXT: {{^ +}}10: addiu $4, $zero, 0x0
# RELA-NEXT: {{^[[:space:]]+0+}}10: R_MIPS_LO16{{.*}} .text+0x14{{$}}

# A forward .set.
  li $4, fwd
# ASM:      addiu $4, $zero, %lo(fwd) # encoding: [0x24,0x04,A,A]
# ASM-NEXT: #   fixup A - offset: 0, value: %lo(fwd), kind: fixup_Mips_LO16
# OBJ-NEXT: {{^ +}}14: addiu $4, $zero, 0x1234

# A forward label difference.
  li $4, c-a
# OBJ-NEXT: {{^ +}}18: addiu $4, $zero, 0x34

# A symbol in another section.
  li $4, d
# OBJ-NEXT: {{^ +}}1c: addiu $4, $zero, 0x0
# OBJ-NEXT: {{^[[:space:]]+0+}}1c: R_MIPS_LO16{{.*}} .data{{$}}

# A value that doesn't fit in 16 bits keeps its low 16 bits.
  li $4, big
# OBJ-NEXT: {{^ +}}20: addiu $4, $zero, 0x2345
  li $4, negf
# OBJ-NEXT: {{^ +}}24: addiu $4, $zero, -0x5

# Another explicit operator keeps its relocation.
  li $4, %hi(sym)
# ASM:      addiu $4, $zero, %hi(sym) # encoding: [0x24,0x04,A,A]
# ASM-NEXT: #   fixup A - offset: 0, value: %hi(sym), kind: fixup_Mips_HI16
# OBJ-NEXT: {{^ +}}28: addiu $4, $zero, 0x0
# OBJ-NEXT: {{^[[:space:]]+0+}}28: R_MIPS_HI16{{.*}} sym{{$}}
# MMOBJ:      {{^ +}}28: addiu $4, $zero, 0x0
# MMOBJ-NEXT: {{^[[:space:]]+0+}}28: R_MICROMIPS_HI16 sym{{$}}

.ifdef DLI
  dli $4, sym
# DLI-NEXT: {{^ +}}2c: addiu $4, $zero, 0x0
# DLI-NEXT: {{^[[:space:]]+0+}}2c: R_MIPS_LO16{{.*}} sym{{$}}
  dli $4, c-a
# DLI-NEXT: {{^ +}}30: addiu $4, $zero, 0x34
.else
  nop
  nop
.endif

c:
  nop
# OBJ:      {{^ +}}34: nop

# A .set that comes first is constant at parse time and takes the usual
# expansion.
  .set bwd, 0x12345
  li $4, bwd
# OBJ-NEXT: {{^ +}}38: lui $4, 0x1
# OBJ-NEXT: {{^ +}}3c: ori $4, $4, 0x2345

# Other explicit operators keep their relocations.
  li $4, %gp_rel(sym)
# OBJ-NEXT: {{^ +}}40: addiu $4, $zero, 0x0
# OBJ-NEXT: {{^[[:space:]]+0+}}40: R_MIPS_GPREL16{{.*}} sym{{$}}

# An addend wider than 16 bits.
  li $4, sym+0x12345
# REL-NEXT:  {{^ +}}44: addiu $4, $zero, 0x2345
# REL-NEXT:  {{^[[:space:]]+0+}}44: R_MIPS_LO16 sym{{$}}
# RELA-NEXT: {{^ +}}44: addiu $4, $zero, 0x0
# RELA-NEXT: {{^[[:space:]]+0+}}44: R_MIPS_LO16{{.*}} sym+0x12345{{$}}

# A forward .set wider than 32 bits keeps its low 16 bits too. GNU as reports
# an error for this on O32 and O64.
  li $4, huge
# OBJ-NEXT: {{^ +}}48: addiu $4, $zero, 0x6789

# A difference of labels that are already laid out loads its full value, as
# does a .set of one. This folds only when emitting an object.
s:
  .space 0x12340
e:
  li $4, e-s
  .set k, e-s
  li $5, k
# OBJ:      {{^ +}}1238c: lui $4, 0x1
# OBJ-NEXT: {{^ +}}12390: ori $4, $4, 0x2340
# OBJ-NEXT: {{^ +}}12394: lui $5, 0x1
# OBJ-NEXT: {{^ +}}12398: ori $5, $5, 0x2340

  .set fwd, 0x1234
  .set big, 0x12345
  .set negf, -5
  .set huge, 0x123456789

  .data
d:
  .word 0
