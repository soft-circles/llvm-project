// RUN: %clang_cc1 -triple mips64-unknown-elf -target-cpu mips3 \
// RUN:   -target-abi o64 -emit-llvm -o - %s | FileCheck %s

void clobber_t0(void) {
  // O64 retains the old ABI register names: t0 is $8, not the N32/N64 $12.
  __asm__ volatile("" ::: "t0");
}

// CHECK-LABEL: define{{.*}} void @clobber_t0()
// CHECK: call void asm sideeffect "", "~{$8},{{.*}}"

// Unlike N32/N64, aggregates never carry doubles as FPU pieces on O64.
struct SD { double d; long long l; };
double sd_d(struct SD s) { return s.d; }
// CHECK-LABEL: define{{.*}} double @sd_d(i64 inreg %s.coerce0, i64 inreg %s.coerce1)

double cd_re(_Complex double c) { return __real__ c; }
// CHECK-LABEL: define{{.*}} double @cd_re(i64 inreg{{.*}} %c.coerce0, i64 inreg{{.*}} %c.coerce1)
