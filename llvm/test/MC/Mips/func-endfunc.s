# RUN: llvm-mc -triple=mips %s | FileCheck %s --implicit-check-not=func
# RUN: not llvm-mc -triple=mips --defsym ERR=1 %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefix=ERR --implicit-check-not=error:

## GAS emits debug information for .func and .endfunc only with --gstabs, so
## they're accepted and ignored. Its errors for unbalanced ones are kept.

# CHECK:      foo:
# CHECK-NEXT:   nop
# CHECK-NEXT: bar:
# CHECK-NEXT:   nop
	.text
	.func foo
foo:
	nop
	.endfunc
	.func bar, bar
bar:
	nop
	.endfunc
	.func
	.endfunc

.ifdef ERR
	.func a
# ERR: :[[#@LINE+1]]:2: error: .endfunc missing for previous .func
	.func b
	.endfunc
# ERR: :[[#@LINE+1]]:2: error: missing .func
	.endfunc
# ERR: :[[#@LINE+1]]:8: error: expected identifier
	.func 1
# ERR: :[[#@LINE+1]]:11: error: expected identifier
	.func e, 1
# ERR: :[[#@LINE+1]]:10: error: expected newline
	.func c d
.endif
