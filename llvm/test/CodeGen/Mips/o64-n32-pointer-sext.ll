; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static < %s \
; RUN:   | FileCheck %s --check-prefixes=ALL,O64
; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=n32 \
; RUN:   -mattr=+noabicalls -relocation-model=static < %s \
; RUN:   | FileCheck %s --check-prefixes=ALL,N32

; N32 and O64 hold 32-bit pointers in 64-bit GPRs, sign-extended like every
; other 32-bit value. A zero-extended KSEG0 address such as 0x80001000 makes
; GCC-built callees fault, so pointer arguments must be sign-extended even
; though IR pointers carry no signext attribute.

@g = global i32 0

declare void @take_ptr(ptr)

; A pointer from the upper half of an aggregate slot needs an arithmetic shift.
define void @pass_upper_half(i64 inreg %head, i64 inreg %pair) {
; ALL-LABEL: pass_upper_half:
; ALL:       dsra $4, $5, 32
; ALL-NOT:   dsrl $4
  %hi = lshr i64 %pair, 32
  %t = trunc nuw i64 %hi to i32
  %p = inttoptr i32 %t to ptr
  call void @take_ptr(ptr %p)
  ret void
}

; N32 has eight argument GPRs, so the fifth argument still goes in $8. O64
; stores only the low word of the stack slot.
declare void @take_fifth(i64, i64, i64, i64, ptr)

define void @pass_fifth(i64 %pair) {
; ALL-LABEL: pass_fifth:
; N32:       dsra $8, $4, 32
; O64:       sw ${{[0-9]+}}, 36($sp)
  %hi = lshr i64 %pair, 32
  %t = trunc nuw i64 %hi to i32
  %p = inttoptr i32 %t to ptr
  call void @take_fifth(i64 0, i64 0, i64 0, i64 0, ptr %p)
  ret void
}

; A constant address is materialized sign-extended, not as 0x0000000080001000.
define void @pass_constant() {
; ALL-LABEL: pass_constant:
; ALL:       lui $[[R:[0-9]+]], 32768
; ALL:       ori $4, $[[R]], 4096
  call void @take_ptr(ptr inttoptr (i32 -2147479552 to ptr))
  ret void
}

; Symbol and stack addresses come from 32-bit instructions and need nothing more.
define void @pass_global() {
; ALL-LABEL: pass_global:
; ALL:       lui $[[R:[0-9]+]], %hi(g)
; ALL:       addiu $4, $[[R]], %lo(g)
; ALL-NOT:   sll
  call void @take_ptr(ptr @g)
  ret void
}

define void @pass_stack() {
; ALL-LABEL: pass_stack:
; ALL:       addiu $4, $sp,
; ALL-NOT:   sll
  %a = alloca i32
  call void @take_ptr(ptr %a)
  ret void
}

; Incoming pointer arguments arrive sign-extended, so using one needs no sll.
define i32 @deref_argument(ptr %p) {
; ALL-LABEL: deref_argument:
; ALL-NOT:   sll
; ALL:       lw $2, 0($4)
  %v = load i32, ptr %p
  ret i32 %v
}

; Returned pointers stay i32, and truncating to i32 already sign-extends.
define ptr @return_upper_half(i64 inreg %pair) {
; ALL-LABEL: return_upper_half:
; ALL:       dsrl $[[R:[0-9]+]], $4, 32
; ALL:       sll $2, $[[R]], 0
  %hi = lshr i64 %pair, 32
  %t = trunc nuw i64 %hi to i32
  %p = inttoptr i32 %t to ptr
  ret ptr %p
}

; Integers without signext keep the cheaper any-extension.
declare void @take_i32(i32)

define void @pass_i32_upper_half(i64 inreg %pair) {
; ALL-LABEL: pass_i32_upper_half:
; ALL:       dsrl $4, $4, 32
  %hi = lshr i64 %pair, 32
  %t = trunc nuw i64 %hi to i32
  call void @take_i32(i32 %t)
  ret void
}
