; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls,+soft-float -relocation-model=static \
; RUN:   -verify-machineinstrs < %s | FileCheck %s

; Like n32 and n64, o64 keeps 32-bit values sign-extended in its 64-bit
; registers, so an i32 libcall argument is sign-extended (sll $r, $r, 0) even
; when the operation treats it as unsigned. It used to be zero-extended with a
; 0xffffffff mask.

define double @u2d(i32 %a) {
; CHECK-LABEL: u2d:
; CHECK:       addiu $sp, $sp, -40
; CHECK-NOT:   dsll
; CHECK:       jal __floatunsidf
; CHECK-NEXT:  sll $4, $4, 0
  %r = uitofp i32 %a to double
  ret double %r
}

define float @u2f(i32 %a) {
; CHECK-LABEL: u2f:
; CHECK:       addiu $sp, $sp, -40
; CHECK-NOT:   dsll
; CHECK:       jal __floatunsisf
; CHECK-NEXT:  sll $4, $4, 0
  %r = uitofp i32 %a to float
  ret float %r
}

define double @s2d(i32 %a) {
; CHECK-LABEL: s2d:
; CHECK:       jal __floatsidf
; CHECK-NEXT:  sll $4, $4, 0
  %r = sitofp i32 %a to double
  ret double %r
}

define double @powi(double %a, i32 %b) {
; CHECK-LABEL: powi:
; CHECK:       addiu $sp, $sp, -40
; CHECK-NOT:   dsll
; CHECK:       jal __powidf2
; CHECK-NEXT:  sll $5, $5, 0
  %r = call double @llvm.powi.f64.i32(double %a, i32 %b)
  ret double %r
}
