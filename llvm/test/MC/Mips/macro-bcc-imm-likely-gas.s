# RUN: llvm-mc %s -triple=mips-unknown-linux -mcpu=mips2 -show-encoding 2>%t.err | FileCheck %s
# RUN: FileCheck %s --check-prefix=WARN < %t.err

# A likely branch that compares a register with an immediate expands as in GNU
# as. One that is never taken is bnel $0, $0, which still annuls its delay
# slot, and one that is always taken is a plain b.

  .set noreorder
foo:
  bltl $3, 0, foo
# CHECK: bltzl $3, foo              # encoding: [0x04,0x62,A,A]
  bgel $3, 1, foo
# CHECK: bgtzl $3, foo              # encoding: [0x5c,0x60,A,A]
  bltul $3, 1, foo
# CHECK: beqzl $3, foo             # encoding: [0x50,0x60,A,A]
  bgeul $3, 1, foo
# CHECK: bnezl $3, foo             # encoding: [0x54,0x60,A,A]
  bltul $3, 0, foo
# CHECK: bnezl $zero, foo          # encoding: [0x54,0x00,A,A]
  bgtul $3, -1, foo
# CHECK: bnezl $zero, foo          # encoding: [0x54,0x00,A,A]
  bgtl $3, 0x7fffffff, foo
# CHECK: bnezl $zero, foo          # encoding: [0x54,0x00,A,A]
  blel $3, 0x7fffffff, foo
# WARN: :[[@LINE-1]]:3: warning: branch is always taken
# CHECK: b foo                      # encoding: [0x10,0x00,A,A]
  bgel $3, -0x80000000, foo
# WARN: :[[@LINE-1]]:3: warning: branch is always taken
# CHECK: b foo                      # encoding: [0x10,0x00,A,A]
  bgeul $3, 0, foo
# WARN: :[[@LINE-1]]:3: warning: branch is always taken
# CHECK: b foo                      # encoding: [0x10,0x00,A,A]
  bleul $3, -1, foo
# WARN: :[[@LINE-1]]:3: warning: branch is always taken
# CHECK: b foo                      # encoding: [0x10,0x00,A,A]
