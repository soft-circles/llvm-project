// RUN: %clang_cc1 -triple mips64-unknown-elf -target-cpu mips3 \
// RUN:   -target-abi o64 -E -dM %s | FileCheck %s

// CHECK: #define _ABIO64 4
// CHECK: #define _MIPS_ISA _MIPS_ISA_MIPS3
// CHECK: #define _MIPS_SIM _ABIO64
// CHECK: #define _MIPS_SZINT 32
// CHECK: #define _MIPS_SZLONG 32
// CHECK: #define _MIPS_SZPTR 32
// CHECK: #define __BIGGEST_ALIGNMENT__ 8
// CHECK: #define __SIZEOF_INT128__ 16
// CHECK: #define __mips 3
// CHECK: #define __mips64 1
// CHECK: #define __mips_o64 1
