# RUN: llvm-mc %s -triple=mips-unknown-linux -mcpu=mips1 -show-encoding 2>%t.err | FileCheck %s
# RUN: FileCheck %s --check-prefix=WARN < %t.err

# A branch that compares a register with an immediate expands as in GNU as:
# ble/bgt compare with the immediate plus one, a comparison with 0 or 1 is a
# compare-with-zero branch, and any other immediate sets $at with slti/sltiu.
# A branch that can never be taken is a nop.

  .set noreorder
foo:
  blt $3, 0, foo
# CHECK: bltz $3, foo               # encoding: [0x04,0x60,A,A]
  blt $3, 1, foo
# CHECK: blez $3, foo               # encoding: [0x18,0x60,A,A]
  blt $3, 32, foo
# CHECK: slti $1, $3, 32            # encoding: [0x28,0x61,0x00,0x20]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  ble $3, -1, foo
# CHECK: bltz $3, foo               # encoding: [0x04,0x60,A,A]
  ble $3, 0, foo
# CHECK: blez $3, foo               # encoding: [0x18,0x60,A,A]
  ble $3, 32, foo
# CHECK: slti $1, $3, 33            # encoding: [0x28,0x61,0x00,0x21]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  bge $3, 0, foo
# CHECK: bgez $3, foo               # encoding: [0x04,0x61,A,A]
  bge $3, 1, foo
# CHECK: bgtz $3, foo               # encoding: [0x1c,0x60,A,A]
  bge $3, 32, foo
# CHECK: slti $1, $3, 32            # encoding: [0x28,0x61,0x00,0x20]
# CHECK-NEXT: beqz $1, foo          # encoding: [0x10,0x20,A,A]
  bgt $3, -1, foo
# CHECK: bgez $3, foo               # encoding: [0x04,0x61,A,A]
  bgt $3, 0, foo
# CHECK: bgtz $3, foo               # encoding: [0x1c,0x60,A,A]
  bgt $3, 32, foo
# CHECK: slti $1, $3, 33            # encoding: [0x28,0x61,0x00,0x21]
# CHECK-NEXT: beqz $1, foo          # encoding: [0x10,0x20,A,A]
  bltu $3, 1, foo
# CHECK: beqz $3, foo               # encoding: [0x10,0x60,A,A]
  bltu $3, 32, foo
# CHECK: sltiu $1, $3, 32           # encoding: [0x2c,0x61,0x00,0x20]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  bleu $3, 0, foo
# CHECK: beqz $3, foo               # encoding: [0x10,0x60,A,A]
  bleu $3, 32, foo
# CHECK: sltiu $1, $3, 33           # encoding: [0x2c,0x61,0x00,0x21]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  bgeu $3, 1, foo
# CHECK: bnez $3, foo               # encoding: [0x14,0x60,A,A]
  bgeu $3, 32, foo
# CHECK: sltiu $1, $3, 32           # encoding: [0x2c,0x61,0x00,0x20]
# CHECK-NEXT: beqz $1, foo          # encoding: [0x10,0x20,A,A]
  bgtu $3, 0, foo
# CHECK: bnez $3, foo               # encoding: [0x14,0x60,A,A]
  bgtu $3, 32, foo
# CHECK: sltiu $1, $3, 33           # encoding: [0x2c,0x61,0x00,0x21]
# CHECK-NEXT: beqz $1, foo          # encoding: [0x10,0x20,A,A]
  blt $3, -32768, foo
# CHECK: slti $1, $3, -32768        # encoding: [0x28,0x61,0x80,0x00]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  ble $3, -32769, foo
# CHECK: slti $1, $3, -32768        # encoding: [0x28,0x61,0x80,0x00]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  ble $3, 32767, foo
# CHECK: ori $1, $zero, 32768       # encoding: [0x34,0x01,0x80,0x00]
# CHECK-NEXT: slt $1, $3, $1        # encoding: [0x00,0x61,0x08,0x2a]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  bgt $3, 32767, foo
# CHECK: ori $1, $zero, 32768       # encoding: [0x34,0x01,0x80,0x00]
# CHECK-NEXT: slt $1, $3, $1        # encoding: [0x00,0x61,0x08,0x2a]
# CHECK-NEXT: beqz $1, foo          # encoding: [0x10,0x20,A,A]
  bleu $3, 32767, foo
# CHECK: ori $1, $zero, 32768       # encoding: [0x34,0x01,0x80,0x00]
# CHECK-NEXT: sltu $1, $3, $1       # encoding: [0x00,0x61,0x08,0x2b]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  bltu $3, -32768, foo
# CHECK: sltiu $1, $3, -32768       # encoding: [0x2c,0x61,0x80,0x00]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  blt $3, 0x10000, foo
# CHECK: lui $1, 1                  # encoding: [0x3c,0x01,0x00,0x01]
# CHECK-NEXT: slt $1, $3, $1        # encoding: [0x00,0x61,0x08,0x2a]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  ble $3, 0x10000, foo
# CHECK: lui $1, 1                  # encoding: [0x3c,0x01,0x00,0x01]
# CHECK-NEXT: ori $1, $1, 1         # encoding: [0x34,0x21,0x00,0x01]
# CHECK-NEXT: slt $1, $3, $1        # encoding: [0x00,0x61,0x08,0x2a]
# CHECK-NEXT: bnez $1, foo          # encoding: [0x14,0x20,A,A]
  bltu $3, 0, foo
# CHECK: nop                        # encoding: [0x00,0x00,0x00,0x00]
  bgtu $3, -1, foo
# CHECK: nop                        # encoding: [0x00,0x00,0x00,0x00]
  bgt $3, 0x7fffffff, foo
# CHECK: nop                        # encoding: [0x00,0x00,0x00,0x00]
  ble $3, 0x7fffffff, foo
# WARN: :[[@LINE-1]]:3: warning: branch is always taken
# CHECK: b foo                      # encoding: [0x10,0x00,A,A]
  bge $3, -0x80000000, foo
# WARN: :[[@LINE-1]]:3: warning: branch is always taken
# CHECK: b foo                      # encoding: [0x10,0x00,A,A]
  bgeu $3, 0, foo
# WARN: :[[@LINE-1]]:3: warning: branch is always taken
# CHECK: b foo                      # encoding: [0x10,0x00,A,A]
  bleu $3, -1, foo
# WARN: :[[@LINE-1]]:3: warning: branch is always taken
# CHECK: b foo                      # encoding: [0x10,0x00,A,A]
