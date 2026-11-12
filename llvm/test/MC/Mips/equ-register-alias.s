# RUN: llvm-mc %s -triple=mips-unknown-linux -mcpu=mips1 -show-encoding | \
# RUN:   FileCheck %s

# As in GNU as, ".equ name, $N" names a register, as ".set name, $N" does.
# An .equ of anything else still defines a symbol.

  .equ src, $22
  .equ step, 5
# CHECK: addi $22, $12, 4               # encoding: [0x21,0x96,0x00,0x04]
  addi src, $12, 4
# CHECK: sub $18, $22, $14              # encoding: [0x02,0xce,0x90,0x22]
  sub $18, src, $14
# CHECK: addiu $2, $3, 5                # encoding: [0x24,0x62,0x00,0x05]
  addiu $2, $3, step
