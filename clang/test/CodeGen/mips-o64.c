// RUN: %clang_cc1 -triple mips64-unknown-elf -target-cpu mips3 \
// RUN:   -target-abi o64 -emit-llvm -o - %s | FileCheck %s

void clobber_t0(void) {
  // O64 retains the old ABI register names: t0 is $8, not the N32/N64 $12.
  __asm__ volatile("" ::: "t0");
}

// CHECK-LABEL: define{{.*}} void @clobber_t0()
// CHECK: call void asm sideeffect "", "~{$8},{{.*}}"
