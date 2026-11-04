# RUN: not llvm-mc %s -triple=mips-unknown-linux-gnu -mcpu=mips1 2>&1 \
# RUN:   | FileCheck %s

  .set $v01, $1
# '$' and the name must be adjacent.
  lwc2 $ v01, 0($2)   # CHECK: :[[@LINE]]:8: error: unexpected token in argument list
# A live alias is a register, not an immediate.
  addiu $3, $0, $v01  # CHECK: :[[@LINE]]:17: error: expected 16-bit signed immediate
# Once the alias ends, the name is not a register.
  .set $v01, 2
  lwc2 $v01, 0($2)    # CHECK: :[[@LINE]]:8: error: invalid operand for instruction
  lwc2 $nope, 0($2)   # CHECK: :[[@LINE]]:8: error: invalid operand for instruction
