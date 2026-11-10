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

// o64 has 64-bit GPRs, so lld/scd are available as with n32/n64 (GCC
// defines this macro for -mabi=o64 too).
// RUN: %clang_cc1 -triple mips64-unknown-elf -target-cpu mips3 \
// RUN:   -target-abi o64 -E -dM %s | FileCheck -check-prefix=SYNC8 %s
// SYNC8: #define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 1

// o64 needs a 64-bit triple; the driver picks one for -mabi=o64.
// RUN: not %clang_cc1 -triple mips-unknown-elf -target-cpu mips3 \
// RUN:   -target-abi o64 -E -dM %s 2>&1 \
// RUN:   | FileCheck -check-prefix=TRIPLE32 %s
// RUN: not %clang_cc1 -triple mipsel-unknown-elf -target-cpu mips3 \
// RUN:   -target-abi o64 -E -dM %s 2>&1 \
// RUN:   | FileCheck -check-prefix=TRIPLE32EL %s
// TRIPLE32: error: ABI 'o64' is not supported for 'mips-unknown-unknown-elf'
// TRIPLE32EL: error: ABI 'o64' is not supported for 'mipsel-unknown-unknown-elf'

// Like n32/n64 (and GCC), o64 rejects FPXX and 32-bit FPRs, which the
// backend cannot handle with 64-bit GPRs.
// RUN: not %clang_cc1 -triple mips64-unknown-elf -target-cpu mips3 \
// RUN:   -target-abi o64 -target-feature +fpxx -E -dM %s 2>&1 \
// RUN:   | FileCheck -check-prefix=FPXX %s
// FPXX: error: '-mfpxx' can only be used with the 'o32' ABI
// RUN: not %clang_cc1 -triple mips64-unknown-elf -target-cpu mips3 \
// RUN:   -target-abi o64 -target-feature -fp64 -E -dM %s 2>&1 \
// RUN:   | FileCheck -check-prefix=FP32 %s
// FP32: error: option '-mfpxx' cannot be specified with 'mips3'

// The backend has no microMIPS64, so o64 rejects microMIPS like n32/n64.
// RUN: not %clang_cc1 -triple mips64-unknown-elf -target-cpu mips3 \
// RUN:   -target-abi o64 -target-feature +micromips -E -dM %s 2>&1 \
// RUN:   | FileCheck -check-prefix=MICROMIPS %s
// MICROMIPS: error: micromips is not supported for target CPU 'mips3'
