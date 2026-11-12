# RUN: llvm-mc %s -triple=mips-unknown-linux -mcpu=mips1 -show-encoding | \
# RUN:   FileCheck %s
# RUN: not llvm-mc %s -triple=mips-unknown-linux -mcpu=mips1 --defsym NOAT=1 \
# RUN:   -filetype=obj -o /dev/null 2>&1 | FileCheck %s --check-prefix=NOAT

# As in GNU as, an ALU macro whose immediate needs more than 16 bits builds it
# in $at, even when the destination differs from the source.

# CHECK:      lui $1, 4                 # encoding: [0x3c,0x01,0x00,0x04]
# CHECK-NEXT: and $9, $4, $1            # encoding: [0x00,0x81,0x48,0x24]
  and $9, $4, 0x40000
# CHECK-NEXT: lui $1, 65280             # encoding: [0x3c,0x01,0xff,0x00]
# CHECK-NEXT: or $4, $6, $1             # encoding: [0x00,0xc1,0x20,0x25]
  or $4, $6, 0xff000000
# CHECK-NEXT: lui $1, 1                 # encoding: [0x3c,0x01,0x00,0x01]
# CHECK-NEXT: add $6, $16, $1           # encoding: [0x02,0x01,0x30,0x20]
  add $6, $16, 0x10000
# CHECK-NEXT: lui $1, 1                 # encoding: [0x3c,0x01,0x00,0x01]
# CHECK-NEXT: nor $4, $5, $1            # encoding: [0x00,0xa1,0x20,0x27]
  nor $4, $5, 0x10000

# As in GNU as, nor of an unsigned 16-bit immediate is ori then nor with $zero,
# and needs no $at.
  .set noat
# CHECK:      ori $4, $5, 65535         # encoding: [0x34,0xa4,0xff,0xff]
# CHECK-NEXT: not $4, $4                # encoding: [0x00,0x80,0x20,0x27]
  nor $4, $5, 0xffff
# CHECK-NEXT: ori $4, $4, 32768         # encoding: [0x34,0x84,0x80,0x00]
# CHECK-NEXT: not $4, $4                # encoding: [0x00,0x80,0x20,0x27]
  nor $4, $4, 0x8000
  .set at

.ifdef NOAT
  .set noat
# NOAT: :[[@LINE+1]]:3: error: pseudo-instruction requires $at, which is not available
  and $9, $4, 0x40000
# NOAT: :[[@LINE+1]]:3: error: pseudo-instruction requires $at, which is not available
  nor $9, $4, 0x10000
.endif
