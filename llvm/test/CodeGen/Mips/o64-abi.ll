; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static < %s | FileCheck %s
; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static -filetype=obj < %s \
; RUN:   | llvm-readelf -h -A - | FileCheck %s --check-prefix=ELF

declare i64 @callee(i64)

define i64 @fifth(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e) {
; CHECK-LABEL: fifth:
; CHECK:       ld $2, 32($sp)
  ret i64 %e
}

define ptr @ptr_inc(ptr %p) {
; CHECK-LABEL: ptr_inc:
; CHECK:       addiu $2, ${{[0-9]+}}, 4
; CHECK-NOT:   daddiu
  %q = getelementptr i8, ptr %p, i32 4
  ret ptr %q
}

define i64 @nonleaf(i64 %x) {
; CHECK-LABEL: nonleaf:
; CHECK:       addiu $sp, $sp, -40
; CHECK:       sd $ra, 32($sp)
; CHECK:       ld $ra, 32($sp)
; CHECK:       addiu $sp, $sp, 40
  %r = call i64 @callee(i64 %x)
  %s = add i64 %r, 1
  ret i64 %s
}

; A partial aggregate is left-justified in its 8-byte slot. This must use the
; original i40 width even though type legalization widens it to i64.
define zeroext i8 @aggregate_i40_first(i40 inreg %s) {
; CHECK-LABEL: aggregate_i40_first:
; CHECK:       dsrl ${{[0-9]+}}, $4, 56
  %shift = lshr i40 %s, 32
  %first = trunc i40 %shift to i8
  ret i8 %first
}

; The same left-justification applies after the four register slots are full.
define zeroext i8 @aggregate_i24_stack_first(i32 signext %a, i32 signext %b,
                                             i32 signext %c, i32 signext %d,
                                             i24 inreg %s) {
; CHECK-LABEL: aggregate_i24_stack_first:
; CHECK:       lbu $2, 32($sp)
  %shift = lshr i24 %s, 16
  %first = trunc i24 %shift to i8
  ret i8 %first
}

; A trailing four-byte fragment also starts at offset zero of its stack slot.
define i32 @aggregate_i32_stack(i32 signext %a, i32 signext %b,
                                i32 signext %c, i64 inreg %head,
                                i32 inreg %tail) {
; CHECK-LABEL: aggregate_i32_stack:
; CHECK:       lw $2, 32($sp)
  ret i32 %tail
}

; Leading scalar floats take $f12 and $f13; a float after an integer rides in
; that slot's GPR instead.
define double @second_double(double %a, double %b) {
; CHECK-LABEL: second_double:
; CHECK:       mov.d $f0, $f13
  ret double %b
}

define float @float_after_int(i32 signext %i, float %f) {
; CHECK-LABEL: float_after_int:
; CHECK:       mtc1 $5, $f0
  ret float %f
}

; An aggregate piece stays in the GPR even when it holds a double.
define double @double_inreg(double inreg %d) {
; CHECK-LABEL: double_inreg:
; CHECK:       dmtc1 $4, $f0
  ret double %d
}

; The caller shifts a partial aggregate into the upper bits of its slot.
declare void @take_i40(i40 inreg)

define void @pass_i40(i40 %s) {
; CHECK-LABEL: pass_i40:
; CHECK:       dsll $4, $4, 24
  call void @take_i40(i40 inreg %s)
  ret void
}

; ELF: Class: ELF32
; ELF: Data: 2's complement, big endian
; ELF: Flags: {{.*}}o64{{.*}}mips3
; ELF: GPR size: 64
; ELF: CPR1 size: 64
; ELF: FP ABI: Hard float (double precision)
