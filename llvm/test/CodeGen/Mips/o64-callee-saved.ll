; RUN: llc -mtriple=mips64-unknown-elf -mcpu=mips3 -target-abi=o64 \
; RUN:   -mattr=+noabicalls -relocation-model=static < %s | FileCheck %s

; O64 uses the old-ABI callee-save set, with the 64-bit views of its GPRs.

define void @gpr_clobber() nounwind {
entry:
  call void asm sideeffect "# Clobber", "~{$16},~{$17},~{$18},~{$19},~{$20},~{$21},~{$22},~{$23},~{$28},~{$30},~{$31}"()
  ret void
}

; CHECK-LABEL: gpr_clobber:
; CHECK:       addiu $sp, $sp, -80
; CHECK-NOT:   sd $gp,
; CHECK-NOT:   sd $28,
; CHECK-DAG:   sd [[S0:\$16]], [[S0OFF:[0-9]+]]($sp)
; CHECK-DAG:   sd [[S1:\$17]], [[S1OFF:[0-9]+]]($sp)
; CHECK-DAG:   sd [[S2:\$18]], [[S2OFF:[0-9]+]]($sp)
; CHECK-DAG:   sd [[S3:\$19]], [[S3OFF:[0-9]+]]($sp)
; CHECK-DAG:   sd [[S4:\$20]], [[S4OFF:[0-9]+]]($sp)
; CHECK-DAG:   sd [[S5:\$21]], [[S5OFF:[0-9]+]]($sp)
; CHECK-DAG:   sd [[S6:\$22]], [[S6OFF:[0-9]+]]($sp)
; CHECK-DAG:   sd [[S7:\$23]], [[S7OFF:[0-9]+]]($sp)
; CHECK-DAG:   sd [[FP:\$fp]], [[FPOFF:[0-9]+]]($sp)
; CHECK-DAG:   sd [[RA:\$ra]], [[RAOFF:[0-9]+]]($sp)
; CHECK-DAG:   ld [[S0]], [[S0OFF]]($sp)
; CHECK-DAG:   ld [[S1]], [[S1OFF]]($sp)
; CHECK-DAG:   ld [[S2]], [[S2OFF]]($sp)
; CHECK-DAG:   ld [[S3]], [[S3OFF]]($sp)
; CHECK-DAG:   ld [[S4]], [[S4OFF]]($sp)
; CHECK-DAG:   ld [[S5]], [[S5OFF]]($sp)
; CHECK-DAG:   ld [[S6]], [[S6OFF]]($sp)
; CHECK-DAG:   ld [[S7]], [[S7OFF]]($sp)
; CHECK-DAG:   ld [[FP]], [[FPOFF]]($sp)
; CHECK-DAG:   ld [[RA]], [[RAOFF]]($sp)
; CHECK:       addiu $sp, $sp, 80

define void @fpu_clobber() nounwind {
entry:
  call void asm sideeffect "# Clobber", "~{$f20},~{$f21},~{$f22},~{$f23},~{$f24},~{$f25},~{$f26},~{$f27},~{$f28},~{$f29},~{$f30},~{$f31}"()
  ret void
}

; CHECK-LABEL: fpu_clobber:
; CHECK:       addiu $sp, $sp, -96
; CHECK-DAG:   sdc1 [[F20:\$f20]], [[F20OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F21:\$f21]], [[F21OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F22:\$f22]], [[F22OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F23:\$f23]], [[F23OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F24:\$f24]], [[F24OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F25:\$f25]], [[F25OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F26:\$f26]], [[F26OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F27:\$f27]], [[F27OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F28:\$f28]], [[F28OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F29:\$f29]], [[F29OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F30:\$f30]], [[F30OFF:[0-9]+]]($sp)
; CHECK-DAG:   sdc1 [[F31:\$f31]], [[F31OFF:[0-9]+]]($sp)
; CHECK-DAG:   ldc1 [[F20]], [[F20OFF]]($sp)
; CHECK-DAG:   ldc1 [[F21]], [[F21OFF]]($sp)
; CHECK-DAG:   ldc1 [[F22]], [[F22OFF]]($sp)
; CHECK-DAG:   ldc1 [[F23]], [[F23OFF]]($sp)
; CHECK-DAG:   ldc1 [[F24]], [[F24OFF]]($sp)
; CHECK-DAG:   ldc1 [[F25]], [[F25OFF]]($sp)
; CHECK-DAG:   ldc1 [[F26]], [[F26OFF]]($sp)
; CHECK-DAG:   ldc1 [[F27]], [[F27OFF]]($sp)
; CHECK-DAG:   ldc1 [[F28]], [[F28OFF]]($sp)
; CHECK-DAG:   ldc1 [[F29]], [[F29OFF]]($sp)
; CHECK-DAG:   ldc1 [[F30]], [[F30OFF]]($sp)
; CHECK-DAG:   ldc1 [[F31]], [[F31OFF]]($sp)
; CHECK:       addiu $sp, $sp, 96
