# RUN: llvm-mc %s -triple=mips -mcpu=mips32r2 | \
# RUN:   FileCheck %s -check-prefix=CHECK-ASM
#
# RUN: llvm-mc %s -triple=mips -mcpu=mips32r2 -filetype=obj -o - | \
# RUN:   llvm-readobj --sections --section-data --section-relocations - | \
# RUN:     FileCheck %s -check-prefix=CHECK-OBJ

# CHECK-ASM: .4byte 3735929054
# CHECK-ASM: .8byte -2401050962867405073
# CHECK-ASM: .2byte 49374
# CHECK-ASM: .4byte label
# CHECK-ASM: .8byte label
# CHECK-ASM: .2byte label

# Checking if the data and reloations were correctly emitted. As in GAS, each
# .word, .dword and .hword is aligned to its size.
# CHECK-OBJ:  Section {
# CHECK-OBJ:    Name: .data
# CHECK-OBJ:    SectionData (
# CHECK-OBJ:      0000: DEADC0DE 00000000 DEADC0DE DEADBEEF
# CHECK-OBJ:      0010: C0DE0000 00000000 00000000 00000000
# CHECK-OBJ:      0020: 0000
# CHECK-OBJ:    )
# CHECK-OBJ:  }

# CHECK-OBJ:  Section {
# CHECK-OBJ:    Name: .rel.data
# CHECK-OBJ:    Relocations [
# CHECK-OBJ:      0x14 R_MIPS_32 .data
# CHECK-OBJ:      0x18 R_MIPS_64 .data
# CHECK-OBJ:      0x20 R_MIPS_16 .data
# CHECK-OBJ:    ]
# CHECK-OBJ:  }

.data
label:
        .word 0xdeadc0de
        .dword 0xdeadc0dedeadbeef
        .hword 0xc0de

        .word label
        .dword label
        .hword label
