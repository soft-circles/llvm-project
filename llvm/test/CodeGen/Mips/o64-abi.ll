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

; ELF: Class: ELF32
; ELF: Data: 2's complement, big endian
; ELF: Flags: {{.*}}o64{{.*}}mips3
; ELF: GPR size: 64
; ELF: CPR1 size: 64
; ELF: FP ABI: Hard float (double precision)
