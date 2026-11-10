; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static -verify-machineinstrs \
; RUN:   < %s | FileCheck %s
; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -relocation-model=pic -verify-machineinstrs < %s \
; RUN:   | FileCheck %s --check-prefix=PIC

; o64 is not one of the new ABIs, so as in o32 (and as GCC -mabi=o64 -pg
; emits it) _mcount pops two 32-bit words off the stack and the caller must
; drop $sp by 8 around the call. The return address is saved in $1 as usual.

define void @foo() {
; CHECK-LABEL: foo:
; CHECK:       addiu $sp, $sp, -40
; CHECK:       sd $ra, 32($sp)
; CHECK:       move $1, $ra
; CHECK-NEXT:  jal _mcount
; CHECK-NEXT:  addiu $sp, $sp, -8
; CHECK-NEXT:  ld $ra, 32($sp)
; CHECK-NEXT:  jr $ra
; CHECK-NEXT:  addiu $sp, $sp, 40

; PIC-LABEL:   foo:
; PIC:         lw $25, %call16(_mcount)($gp)
; PIC:         move $1, $ra
; PIC:         jalr $25
; PIC-NEXT:    addiu $sp, $sp, -8
; PIC-NEXT:    ld $ra, 32($sp)
entry:
  call void @_mcount()
  ret void
}

declare void @_mcount()
