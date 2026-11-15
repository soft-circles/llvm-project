; RUN: llc < %s -mtriple=mips -relocation-model=static -mattr=+noabicalls \
; RUN:     -mgpopt -verify-machineinstrs | FileCheck %s --check-prefix=O32
; RUN: llc < %s -mtriple=mips64 -mcpu=mips3 -target-abi n64 \
; RUN:     -relocation-model=static -mattr=+noabicalls -mgpopt \
; RUN:     -verify-machineinstrs | FileCheck %s --check-prefix=N64

; A select between two small-data addresses is folded to $gp plus a select of
; their gp_rel offsets, which must still be selectable on their own.

@a = internal global i32 1, align 4
@b = internal global i32 2, align 4

declare void @take(ptr)

define void @select_global(i1 %c) nounwind {
; O32-LABEL: select_global:
; O32-DAG:     addiu ${{[0-9]+}}, $zero, %gp_rel(a)
; O32-DAG:     addiu ${{[0-9]+}}, $zero, %gp_rel(b)
; O32:         addu $4, $gp, ${{[0-9]+}}
; N64-LABEL: select_global:
; N64-DAG:     daddiu ${{[0-9]+}}, $zero, %gp_rel(a)
; N64-DAG:     daddiu ${{[0-9]+}}, $zero, %gp_rel(b)
; N64:         daddu $4, $gp, ${{[0-9]+}}
  %p = select i1 %c, ptr @a, ptr @b
  call void @take(ptr %p)
  ret void
}

define float @select_constant(i1 %c) nounwind {
; O32-LABEL: select_constant:
; O32-DAG:     addiu ${{[0-9]+}}, $zero, %gp_rel($CPI1_0)
; O32-DAG:     addiu ${{[0-9]+}}, $zero, %gp_rel($CPI1_1)
; O32:         addu $[[P:[0-9]+]], $gp, ${{[0-9]+}}
; O32:         lwc1 $f0, 0($[[P]])
; N64-LABEL: select_constant:
; N64-DAG:     daddiu ${{[0-9]+}}, $zero, %gp_rel(.LCPI1_0)
; N64-DAG:     daddiu ${{[0-9]+}}, $zero, %gp_rel(.LCPI1_1)
; N64:         daddu $[[P:[0-9]+]], $gp, ${{[0-9]+}}
; N64:         lwc1 $f0, 0($[[P]])
  %r = select i1 %c, float 1.5, float 2.5
  ret float %r
}
