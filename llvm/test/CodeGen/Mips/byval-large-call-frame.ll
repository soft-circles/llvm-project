; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static < %s \
; RUN:   | FileCheck %s --check-prefix=O64
; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips64 -target-abi=n64 \
; RUN:   -mattr=+noabicalls -relocation-model=static < %s \
; RUN:   | FileCheck %s --check-prefix=N64

; A byval argument whose outgoing area does not fit in a 16-bit offset stops
; the call frame from being reserved, so $sp moves down around the call. The
; loads that fill the argument registers from the local copy run after that
; move and must account for it.

%Big = type { [8192 x i64] }

declare void @take_big(ptr byval(%Big) align 8)
declare void @fill(ptr)

define void @local_big() {
  %b = alloca %Big, align 8
  call void @fill(ptr %b)
  call void @take_big(ptr byval(%Big) align 8 %b)
  ret void
}

; On O64 %b lives at 8($sp) before the call sequence moves $sp down by 65536.
; O64-LABEL: local_big:
; O64:         addiu $16, $sp, 8
; O64:         lui $1, 1
; O64-NEXT:    subu $sp, $sp, $1
; O64:         jal memcpy
; O64-NEXT:    ori $6, $zero, 65504
; O64-NEXT:    lui $1, 1
; O64-NEXT:    addu $1, $sp, $1
; O64-NEXT:    ld $7, 32($1)
; O64-NEXT:    lui $1, 1
; O64-NEXT:    addu $1, $sp, $1
; O64-NEXT:    ld $6, 24($1)
; O64-NEXT:    lui $1, 1
; O64-NEXT:    addu $1, $sp, $1
; O64-NEXT:    ld $5, 16($1)
; O64-NEXT:    lui $1, 1
; O64-NEXT:    addu $1, $sp, $1
; O64-NEXT:    jal take_big
; O64-NEXT:    ld $4, 8($1)
; O64-NEXT:    lui $1, 1
; O64-NEXT:    addu $sp, $sp, $1

; On N64 %b lives at 16($sp) before the call sequence moves $sp down by 65472.
; N64-LABEL: local_big:
; N64:         daddiu $16, $sp, 16
; N64:         ori $1, $zero, 65472
; N64-NEXT:    dsubu $sp, $sp, $1
; N64:         jal memcpy
; N64-NEXT:    move $4, $sp
; N64-NEXT:    lui $1, 1
; N64-NEXT:    daddu $1, $sp, $1
; N64-NEXT:    ld $11, 8($1)
; N64:         ld $10, 0($1)
; N64:         ld $9, -8($1)
; N64:         ld $8, -16($1)
; N64:         ld $7, -24($1)
; N64:         ld $6, -32($1)
; N64:         ld $5, -40($1)
; N64-NEXT:    lui $1, 1
; N64-NEXT:    daddu $1, $sp, $1
; N64-NEXT:    jal take_big
; N64-NEXT:    ld $4, -48($1)
; N64-NEXT:    ori $1, $zero, 65472
; N64-NEXT:    daddu $sp, $sp, $1
