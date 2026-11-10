; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static -verify-machineinstrs \
; RUN:   < %s | FileCheck %s

; o64 has 64-bit GPRs and a 64-bit FPU register file, so an f64 fabs must
; clear bit 63 of the whole register with dmfc1/dmtc1, as n32 does. Splitting
; it into 32-bit halves wrote only the low word of the result.

define double @fabs_f64(double %a) {
; CHECK-LABEL: fabs_f64:
; CHECK:       dmfc1 $1, $f12
; CHECK-NEXT:  daddiu $2, $zero, 1
; CHECK-NEXT:  dsll $2, $2, 63
; CHECK-NEXT:  daddiu $2, $2, -1
; CHECK-NEXT:  and $1, $1, $2
; CHECK-NEXT:  jr $ra
; CHECK-NEXT:  dmtc1 $1, $f0
; CHECK-NOT:   mtc1
  %r = call double @llvm.fabs.f64(double %a)
  ret double %r
}

define float @fabs_f32(float %a) {
; CHECK-LABEL: fabs_f32:
; CHECK:       lui $1, 32767
; CHECK-NEXT:  ori $1, $1, 65535
; CHECK-NEXT:  mfc1 $2, $f12
; CHECK-NEXT:  nop
; CHECK-NEXT:  and $1, $2, $1
; CHECK-NEXT:  jr $ra
; CHECK-NEXT:  mtc1 $1, $f0
  %r = call float @llvm.fabs.f32(float %a)
  ret float %r
}

; copysign already took the 64-bit path; keep it there.
define double @copysign_f64(double %a, double %b) {
; CHECK-LABEL: copysign_f64:
; CHECK:       daddiu $1, $zero, 1
; CHECK-NEXT:  dsll $1, $1, 63
; CHECK-NEXT:  dmfc1 $2, $f13
; CHECK-NEXT:  nop
; CHECK-NEXT:  and $2, $2, $1
; CHECK-NEXT:  dmfc1 $3, $f12
; CHECK-NEXT:  daddiu $1, $1, -1
; CHECK-NEXT:  and $1, $3, $1
; CHECK-NEXT:  or $1, $1, $2
; CHECK-NEXT:  jr $ra
; CHECK-NEXT:  dmtc1 $1, $f0
  %r = call double @llvm.copysign.f64(double %a, double %b)
  ret double %r
}
