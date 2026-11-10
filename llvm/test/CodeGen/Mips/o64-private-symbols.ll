; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static < %s | FileCheck %s
; RUN: llc -mtriple=mips64el-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static < %s | FileCheck %s
; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static -filetype=obj < %s \
; RUN:   | llvm-readelf -s - | FileCheck %s --check-prefix=SYM

; o64 uses o32's "m:m" mangling, so private globals and constant-pool entries
; take the '$' private prefix that MipsMCAsmInfo uses for o64, instead of
; ".L", which the o64 assembler does not treat as private.

@.str = private unnamed_addr constant [4 x i8] c"abc\00", align 1

define ptr @get_str() {
; CHECK-LABEL: get_str:
; CHECK:       lui $1, %hi($.str)
; CHECK:       addiu $2, $1, %lo($.str)
  ret ptr @.str
}

define double @get_const() {
; CHECK-LABEL: get_const:
; CHECK:       %hi($CPI1_0)
; CHECK:       %lo($CPI1_0)
  ret double 1.234500e+00
}

; CHECK:       $.str:
; CHECK-NOT:   .L.str
; CHECK-NOT:   .LCPI

; SYM:         Symbol table '.symtab'
; SYM-NOT:     .L
; SYM:         $.str
; SYM-NOT:     .L
; SYM:         $CPI1_0
; SYM-NOT:     .L
