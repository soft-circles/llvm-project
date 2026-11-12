# RUN: llvm-mc %s -triple=mips-unknown-linux -mcpu=mips1 -filetype=obj \
# RUN:   -mips-pad-code-sections -o - | llvm-readobj --sections - | FileCheck %s
# RUN: llvm-mc %s -triple=mips-unknown-linux -mcpu=mips1 -filetype=obj -o - | \
# RUN:   llvm-readobj --sections - | FileCheck %s --check-prefix=NOPAD
# RUN: llvm-mc %s -triple=mips-unknown-linux -mcpu=mips1 -filetype=obj \
# RUN:   -mips-pad-code-sections -o - | llvm-objdump -d --no-show-raw-insn - | \
# RUN:   FileCheck %s --check-prefix=DIS

# With -mips-pad-code-sections the end of each code section, and only of code
# sections, is padded to the alignment its code asked for, as in GNU as. The
# end is the end of the last subsection, so subsection 1 still follows
# subsection 0 directly.

  .text
  addiu $2, $2, 1
  .align 3
  addiu $2, $2, 2
  .text 1
  addiu $2, $2, 3
  addiu $2, $2, 5
  .data
  .byte 1, 2, 3
  .section .other, "ax"
  .align 4
  addiu $2, $2, 4

# CHECK-LABEL: Name: .text
# CHECK:       Size: 24
# CHECK-LABEL: Name: .data
# CHECK:       Size: 3
# CHECK-LABEL: Name: .other
# CHECK:       Size: 16

# NOPAD-LABEL: Name: .text
# NOPAD:       Size: 20
# NOPAD-LABEL: Name: .other
# NOPAD:       Size: 4

# DIS-LABEL: <.text>:
# DIS-NEXT:   0: addiu $2, $2, 0x1
# DIS-NEXT:   4: nop
# DIS-NEXT:   8: addiu $2, $2, 0x2
# DIS-NEXT:   c: addiu $2, $2, 0x3
# DIS-NEXT:  10: addiu $2, $2, 0x5
# DIS-NEXT:  14: nop
# DIS-EMPTY:
