# RUN: llvm-mc %s -triple=mips-unknown-linux -mcpu=mips1 -filetype=obj -o - | \
# RUN:   llvm-objdump -dr --no-show-raw-insn - | FileCheck %s

# As in GNU as, la of an address under an explicit relocation operator is one
# addiu of that 16-bit value, from the base register or $zero.

# CHECK:      addiu $8, $gp, -0x18
# CHECK-NEXT: R_MIPS_LO16 sym
# CHECK-NEXT: addiu $8, $gp, 0x0
# CHECK-NEXT: R_MIPS_LO16 sym
# CHECK-NEXT: addiu $8, $zero, 0x0
# CHECK-NEXT: R_MIPS_LO16 sym
# CHECK-NEXT: addiu $8, $gp, 0x64
# CHECK-NEXT: lui $8, 0x0
# CHECK-NEXT: R_MIPS_HI16 sym
# CHECK-NEXT: addiu $8, $8, 0x0
# CHECK-NEXT: R_MIPS_LO16 sym
  la $8, (%lo(sym) + 16 - 40)($28)
  la $8, %lo(sym)($28)
  la $8, %lo(sym)
  la $8, 100($28)
  la $8, sym
