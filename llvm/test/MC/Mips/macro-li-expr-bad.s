# An expression li or dli can't encode is an error, never a 0.

# RUN: not llvm-mc %s -triple=mips-unknown-elf -mcpu=mips2 -filetype=obj \
# RUN:   -o /dev/null 2>&1 | FileCheck %s --check-prefix=LAYOUT \
# RUN:   --implicit-check-not=error:
# RUN: not llvm-mc %s -triple=mips-unknown-elf -mcpu=mips2 --defsym=DLI=1 \
# RUN:   -o /dev/null 2>&1 | FileCheck %s --check-prefix=PARSE \
# RUN:   --implicit-check-not=error:

  .text
a:
.ifdef DLI
  dli $4, sym
# PARSE: :[[@LINE-1]]:3: error: instruction requires a 64-bit architecture
.else
  li $4, d-a
# LAYOUT: :[[@LINE-1]]:3: error: expected relocatable expression
  li $4, sym-a
# LAYOUT: :[[@LINE-1]]:3: error: expected relocatable expression
  li $4, sym*2
# LAYOUT: :[[@LINE-1]]:3: error: expected relocatable expression
.endif

  .data
d:
  .word 0
