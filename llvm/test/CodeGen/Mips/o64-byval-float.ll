; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static -verify-machineinstrs \
; RUN:   < %s | FileCheck %s

; As in o32, a by-value aggregate in an o64 argument slot consumes an integer
; register and does not shadow an FPU register. A double that follows it is
; therefore no longer eligible for $f12/$f13 and travels in its slot's GPR,
; as GCC -mabi=o64 passes f(struct { int a, b; }, double).

%struct.S = type { i32, i32 }
%struct.L = type { i64, i64 }

define double @take(ptr byval(%struct.S) align 8 %s, double %d) {
; CHECK-LABEL: take:
; CHECK-NOT:   $f13
; CHECK-DAG:   dmtc1 $5, $f0
; CHECK-DAG:   sd $4, 0($sp)
; CHECK:       .end take
  ret double %d
}

; A 16-byte aggregate takes two slots; the double lands in the third.
define double @take_large(ptr byval(%struct.L) align 8 %s, double %d) {
; CHECK-LABEL: take_large:
; CHECK-NOT:   $f13
; CHECK-NOT:   $f14
; CHECK:       dmtc1 $6, $f0
; CHECK:       .end take_large
  ret double %d
}

; A double that precedes the aggregate is still the first argument.
define double @take_first(double %d, ptr byval(%struct.S) align 8 %s) {
; CHECK-LABEL: take_first:
; CHECK:       mov.d $f0, $f12
; CHECK:       .end take_first
  ret double %d
}

declare void @callee(ptr byval(%struct.S) align 8, double)

define void @caller(ptr %p) {
; CHECK-LABEL: caller:
; CHECK-NOT:   $f13
; CHECK-DAG:   ld $4, 0($4)
; CHECK-DAG:   dsll $5, ${{[0-9]+}}, 62
; CHECK-DAG:   jal callee
; CHECK:       .end caller
  call void @callee(ptr byval(%struct.S) align 8 %p, double 2.0)
  ret void
}
