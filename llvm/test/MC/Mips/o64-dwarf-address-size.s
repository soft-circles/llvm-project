# RUN: llvm-mc -triple mips64-unknown-elf -target-abi o64 -g -filetype=obj %s \
# RUN:   | llvm-dwarfdump --debug-info - | FileCheck %s

# O64 objects are ELF32 with 32-bit addresses even though the GPRs are 64-bit.
# CHECK: addr_size = 0x04

  nop
