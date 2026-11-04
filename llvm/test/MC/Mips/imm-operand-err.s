## Print an error if a microMIPS immediate needs a relocation. The standard
## encodings get R_MIPS_LO16 instead (logical-imm-symbol.s).
# RUN: not llvm-mc -filetype=obj -triple=mips -mcpu=mips32r2 -mattr=+micromips \
# RUN:   -o /dev/null %s 2>&1 | FileCheck %s --implicit-check-not=error:

# CHECK: [[#@LINE+1]]:16: error: unsupported relocation type
  ori  $4, $4, start
  ori  $4, $4, (start - .)

# CHECK: [[#@LINE+1]]:18: error: unsupported relocation type
  addiu  $4, $4, start
  addiu  $4, $4, (start - .)

start:
