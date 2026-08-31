; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static -stop-after=prologepilog \
; RUN:   < %s | FileCheck %s

@escape = external global ptr

define void @large_frame() {
entry:
  %storage = alloca [40000 x i8], align 8
  store volatile ptr %storage, ptr @escape
  ret void
}

; CHECK-LABEL: name: large_frame
; CHECK:       stackSize: 40008
; CHECK:       - { id: 1, name: '', type: spill-slot, offset: -40008, size: 8, alignment: 8,
