# A .set register alias whose name starts with '$', as libdragon's rsp.inc
# writes them, works as an operand. Assigning the name a value again ends the
# alias, and .set with a register starts it again. The encodings match GNU as
# 2.47.

# RUN: llvm-mc %s -triple=mips-unknown-linux-gnu -mcpu=mips1 -show-encoding \
# RUN:   | FileCheck %s
# RUN: llvm-mc %s -triple=mips64-unknown-linux-gnu -mcpu=mips3 -target-abi o64 \
# RUN:   -show-encoding | FileCheck %s

  .set noat

  .set $v01, $1
  .set $v31, $31
  lwc2 $v01, 0($2)            # CHECK: lwc2 $1, 0($2)     # encoding: [0xc8,0x41,0x00,0x00]
  swc2 $v31, 16($sp)          # CHECK: swc2 $31, 16($sp)  # encoding: [0xeb,0xbf,0x00,0x10]
  cfc2 $2, $v01               # CHECK: cfc2 $2, $1        # encoding: [0x48,0x42,0x08,0x00]
  ctc2 $v31, $v01             # CHECK: ctc2 $ra, $1       # encoding: [0x48,0xdf,0x08,0x00]
  lw $2, 0($v01)              # CHECK: lw $2, 0($1)       # encoding: [0x8c,0x22,0x00,0x00]

# A constant value ends the alias: $v01 is an expression again.
  .set $v01, 0x2
  addiu $3, $0, ($v01 << 6)   # CHECK: addiu $3, $zero, 128 # encoding: [0x24,0x03,0x00,0x80]

# .set with a register makes it an alias again.
  .set $v01, $5
  lwc2 $v01, 0($2)            # CHECK: lwc2 $5, 0($2)     # encoding: [0xc8,0x45,0x00,0x00]

# Assigning with '=' ends the alias too.
  $v01 = 3
  addiu $3, $0, $v01          # CHECK: addiu $3, $zero, 3 # encoding: [0x24,0x03,0x00,0x03]

# An alias outranks a register of the same name, as in GNU as.
  .set $t0, $1
  lwc2 $t0, 0($2)             # CHECK: lwc2 $1, 0($2)     # encoding: [0xc8,0x41,0x00,0x00]

# Names without '$' follow the same rules.
  .set r7, $7
  lwc2 r7, 0($2)              # CHECK: lwc2 $7, 0($2)     # encoding: [0xc8,0x47,0x00,0x00]
  .set r7, 4
  addiu $3, $0, r7            # CHECK: addiu $3, $zero, 4 # encoding: [0x24,0x03,0x00,0x04]
  .set r7, $7
  lwc2 r7, 0($2)              # CHECK: lwc2 $7, 0($2)     # encoding: [0xc8,0x47,0x00,0x00]

# A numeric alias replaces an earlier named-register value, and a later
# named-register value replaces the alias.
  .set r1, $t0
  .set r1, $1
  addu r1, $2, $3             # CHECK: addu $1, $2, $3    # encoding: [0x00,0x43,0x08,0x21]
  .set r1, $t1
  addu r1, $2, $3             # CHECK: addu $9, $2, $3    # encoding: [0x00,0x43,0x48,0x21]

# A label with the alias's name is a label, not a register.
  .set noreorder
  .set lab, $5
lab:
  j lab                       # CHECK: j lab              # encoding: [0b000010AA,A,A,A]
  nop
