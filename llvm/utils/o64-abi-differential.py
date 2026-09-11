#!/usr/bin/env python3
"""Differentially validate LLVM's O64 ABI against GCC's machine code.

The probes are deliberately straight-line leaf functions.  Their generated MIPS
is executed with identical register and stack inputs, then ABI-visible outputs
are compared.  This avoids comparing optimizer choices (or merely mentioning a
register) while keeping GCC -mabi=o64 as the oracle.
"""

import argparse
import os
import random
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


SOURCE = r"""
#include <stdarg.h>

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long u64;

struct S3 { u8 a, b, c; };
struct S5 { u8 a, b, c, d, e; };
struct S12 { u32 a, b, c; };
struct Big { u32 a, b, c, d, e, f; };
struct SF { float a, b; };
struct SD { double d; };
struct SDL { double d; long long l; };
union U8 { u64 q; u32 w[2]; u8 b[8]; };

#define FIELD(ret, name, params, expr) ret name params { return (expr); }

FIELD(u8, s3_a, (struct S3 s), s.a)
FIELD(u8, s3_b, (struct S3 s), s.b)
FIELD(u8, s3_c, (struct S3 s), s.c)
FIELD(u8, s3_after_c, (u32 x, struct S3 s), s.c)
FIELD(u8, s3_edge_a, (u32 a, u32 b, u32 c, struct S3 s), s.a)
FIELD(u8, s3_edge_c, (u32 a, u32 b, u32 c, struct S3 s), s.c)
FIELD(u8, s3_stack_a, (u32 a, u32 b, u32 c, u32 d, struct S3 s), s.a)
FIELD(u8, s3_stack_c, (u32 a, u32 b, u32 c, u32 d, struct S3 s), s.c)
FIELD(u8, s5_a, (struct S5 s), s.a)
FIELD(u8, s5_e, (struct S5 s), s.e)
FIELD(u32, s12_a, (struct S12 s), s.a)
FIELD(u32, s12_b, (struct S12 s), s.b)
FIELD(u32, s12_c, (struct S12 s), s.c)
FIELD(u32, s12_edge_c, (u32 a, u32 b, u32 c, struct S12 s), s.c)
FIELD(u64, u8_q, (union U8 u), u.q)
FIELD(u32, u8_w0, (union U8 u), u.w[0])
FIELD(u32, u8_w1, (union U8 u), u.w[1])
FIELD(u8, u8_b0, (union U8 u), u.b[0])
FIELD(u8, u8_b7, (union U8 u), u.b[7])
FIELD(float, sf_a, (struct SF s), s.a)
FIELD(float, sf_b, (struct SF s), s.b)
FIELD(double, sd_d, (struct SD s), s.d)
FIELD(double, sd_after, (u32 x, struct SD s), s.d)
FIELD(double, sdl_d, (struct SDL s), s.d)
FIELD(u64, sdl_l, (struct SDL s), s.l)
FIELD(double, cd_re, (_Complex double c), __real__ c)
FIELD(double, cd_im, (_Complex double c), __imag__ c)

double va_d0(int n, ...) {
  va_list a; va_start(a, n); double x = va_arg(a, double); va_end(a); return x;
}
int va_i1(int n, ...) {
  va_list a; va_start(a, n); (void)va_arg(a, double);
  int x = va_arg(a, int); va_end(a); return x;
}
double va_d2(int n, ...) {
  va_list a; va_start(a, n); (void)va_arg(a, double); (void)va_arg(a, int);
  double x = va_arg(a, double); va_end(a); return x;
}
long long va_l3(int n, ...) {
  va_list a; va_start(a, n); (void)va_arg(a, double); (void)va_arg(a, int);
  (void)va_arg(a, double); long long x = va_arg(a, long long);
  va_end(a); return x;
}
double va_named(int i, double d, ...) {
  va_list a; va_start(a, d); double x = va_arg(a, double); va_end(a); return x;
}

extern long long sink(int, ...);
extern long long sink_named(int, double, ...);
long long call_var(double a, int b, double c, long long d) {
  return sink(4, a, b, c, d);
}
long long call_named(int a, double b, double c, int d) {
  return sink_named(a, b, c, d);
}

signed char ret_i8(signed char x) { return x; }
unsigned char ret_u8(unsigned char x) { return x; }
short ret_i16(short x) { return x; }
unsigned short ret_u16(unsigned short x) { return x; }
int ret_i32(int x) { return x; }
unsigned ret_u32(unsigned x) { return x; }
long long ret_i64(long long x) { return x; }
void *ret_ptr(void *x) { return x; }
float ret_f32(float x) { return x; }
double ret_f64(double x) { return x; }

struct S3 ret_s3(u32 x) {
  struct S3 r = {(u8)x, (u8)(x + 1), (u8)(x + 2)}; return r;
}
struct S12 ret_s12(u32 x) {
  struct S12 r = {x, x + 1, x + 2}; return r;
}
struct Big ret_big(u32 x) {
  struct Big r = {x, x + 1, x + 2, x + 3, x + 4, x + 5}; return r;
}
union U8 ret_u8_agg(u64 x) { union U8 r; r.q = x; return r; }
struct SF ret_sf(float x) { struct SF r = {x, x}; return r; }
"""


ALIASES = {
    "zero": 0, "at": 1, "v0": 2, "v1": 3,
    "a0": 4, "a1": 5, "a2": 6, "a3": 7,
    "t0": 8, "t1": 9, "t2": 10, "t3": 11,
    "t4": 12, "t5": 13, "t6": 14, "t7": 15,
    "s0": 16, "s1": 17, "s2": 18, "s3": 19,
    "s4": 20, "s5": 21, "s6": 22, "s7": 23,
    "t8": 24, "t9": 25, "k0": 26, "k1": 27,
    "gp": 28, "sp": 29, "fp": 30, "s8": 30, "ra": 31,
}
MASK64 = (1 << 64) - 1


def sx(value, bits):
    value &= (1 << bits) - 1
    return value - (1 << bits) if value & (1 << (bits - 1)) else value


def reg_number(token):
    name = token.strip().lstrip("$")
    return int(name) if name.isdigit() else ALIASES[name]


def fpr_number(token):
    return int(token.strip().lstrip("$f"))


def split_args(text):
    return [part.strip() for part in text.split(",")]


class Machine:
    def __init__(self, seed, sret=False):
        rng = random.Random(seed)
        self.gpr = [rng.getrandbits(64) for _ in range(32)]
        self.fpr = [rng.getrandbits(64) for _ in range(32)]
        self.mem = {}
        self.gpr[0] = 0
        self.gpr[29] = 0x100000
        if sret:
            self.gpr[4] = 0x200000
        for address in range(0x0FFF00, 0x100200):
            self.mem[address] = rng.getrandbits(8)
        for address in range(0x200000, 0x200040):
            self.mem[address] = 0xA5

    def r(self, token):
        return self.gpr[reg_number(token)]

    def w(self, token, value):
        number = reg_number(token)
        if number:
            self.gpr[number] = value & MASK64

    def load(self, address, size, signed=False):
        value = 0
        for offset in range(size):
            value = (value << 8) | self.mem.get(address + offset, 0)
        return sx(value, size * 8) if signed else value

    def store(self, address, size, value):
        for offset in range(size):
            shift = 8 * (size - 1 - offset)
            self.mem[address + offset] = (value >> shift) & 0xFF

    def address(self, operand):
        match = re.fullmatch(r"(-?\d+)\((\$\w+)\)", operand.replace(" ", ""))
        if not match:
            raise ValueError(f"unsupported address {operand}")
        return (self.r(match.group(2)) + int(match.group(1))) & MASK64

    def execute(self, instruction):
        fields = instruction.split(None, 1)
        op = fields[0]
        args = split_args(fields[1]) if len(fields) == 2 else []

        if op in {"nop", "jr", "jal", "j"}:
            return
        if op == "move":
            self.w(args[0], self.r(args[1])); return
        if op in {"mov.s", "mov.d"}:
            bits = self.fpr[fpr_number(args[1])]
            self.fpr[fpr_number(args[0])] = bits & (0xFFFFFFFF if op == "mov.s" else MASK64)
            return
        if op == "li":
            self.w(args[0], int(args[1], 0)); return
        if op == "lui":
            self.w(args[0], sx(int(args[1], 0) << 16, 32)); return
        if op in {"addiu", "addu", "subu"}:
            right = int(args[2], 0) if op == "addiu" else self.r(args[2])
            value = self.r(args[1]) + right if op != "subu" else self.r(args[1]) - right
            self.w(args[0], sx(value, 32)); return
        if op in {"daddiu", "daddu", "dsubu"}:
            right = int(args[2], 0) if op == "daddiu" else self.r(args[2])
            value = self.r(args[1]) + right if op != "dsubu" else self.r(args[1]) - right
            self.w(args[0], value); return
        if op in {"and", "or", "xor"}:
            fn = {"and": lambda a, b: a & b, "or": lambda a, b: a | b,
                  "xor": lambda a, b: a ^ b}[op]
            self.w(args[0], fn(self.r(args[1]), self.r(args[2]))); return
        if op in {"andi", "ori", "xori"}:
            imm = int(args[2], 0) & 0xFFFF
            fn = {"andi": lambda a: a & imm, "ori": lambda a: a | imm,
                  "xori": lambda a: a ^ imm}[op]
            self.w(args[0], fn(self.r(args[1]))); return
        if op in {"sll", "srl", "sra", "dsll", "dsrl", "dsra",
                  "dsll32", "dsrl32", "dsra32"}:
            shift = int(args[2], 0) + (32 if op.endswith("32") else 0)
            value = self.r(args[1])
            if op.startswith("ds"):
                if "sll" in op: result = value << shift
                elif "sra" in op: result = sx(value, 64) >> shift
                else: result = value >> shift
                self.w(args[0], result)
            else:
                value &= 0xFFFFFFFF
                if op == "sll": result = value << shift
                elif op == "sra": result = sx(value, 32) >> shift
                else: result = value >> shift
                self.w(args[0], sx(result, 32))
            return
        if op in {"seb", "seh"}:
            self.w(args[0], sx(self.r(args[1]), 8 if op == "seb" else 16)); return
        if op in {"lb", "lbu", "lh", "lhu", "lw", "lwu", "ld"}:
            size = {"lb": 1, "lbu": 1, "lh": 2, "lhu": 2,
                    "lw": 4, "lwu": 4, "ld": 8}[op]
            signed = op in {"lb", "lh", "lw"}
            self.w(args[0], self.load(self.address(args[1]), size, signed)); return
        if op in {"sb", "sh", "sw", "sd"}:
            size = {"sb": 1, "sh": 2, "sw": 4, "sd": 8}[op]
            self.store(self.address(args[1]), size, self.r(args[0])); return
        if op in {"lwc1", "ldc1"}:
            size = 4 if op == "lwc1" else 8
            self.fpr[fpr_number(args[0])] = self.load(self.address(args[1]), size)
            return
        if op in {"swc1", "sdc1"}:
            size = 4 if op == "swc1" else 8
            self.store(self.address(args[1]), size, self.fpr[fpr_number(args[0])]); return
        if op == "mtc1":
            self.fpr[fpr_number(args[1])] = self.r(args[0]) & 0xFFFFFFFF; return
        if op == "dmtc1":
            self.fpr[fpr_number(args[1])] = self.r(args[0]); return
        if op == "mfc1":
            self.w(args[0], sx(self.fpr[fpr_number(args[1])], 32)); return
        if op == "dmfc1":
            self.w(args[0], self.fpr[fpr_number(args[1])]); return
        raise ValueError(f"unsupported instruction: {instruction}")


def functions(assembly):
    result = {}
    current = None
    for raw in assembly.splitlines():
        line = re.sub(r"#.*", "", raw).strip()
        match = re.fullmatch(r"([A-Za-z_]\w*):", line)
        if match:
            current = match.group(1)
            result.setdefault(current, [])
            continue
        if current and line.startswith(".end"):
            current = None
            continue
        if current and line and not line.startswith(".") and not line.endswith(":"):
            result[current].append(re.sub(r"\s+", " ", line))
    return result


def run_leaf(code, seed, sret=False, pointer=False):
    machine = Machine(seed, sret)
    if pointer:
        machine.gpr[4] = sx(machine.gpr[4], 32) & MASK64
    stop_after = None
    for index, instruction in enumerate(code):
        machine.execute(instruction)
        if stop_after == index:
            break
        if instruction.split(None, 1)[0] == "jr":
            stop_after = index + 1
    return machine


def run_to_call(code, seed, stack_bytes):
    machine = Machine(seed)
    stop_after = None
    for index, instruction in enumerate(code):
        machine.execute(instruction)
        if stop_after == index:
            sp = machine.gpr[29]
            return (tuple(machine.gpr[4:8]), tuple(machine.fpr[12:20]),
                    bytes(machine.mem.get(sp + i, 0)
                          for i in range(32, 32 + stack_bytes)))
        if instruction.split(None, 1)[0] in {"jal", "j"}:
            stop_after = index + 1
    raise ValueError("probe contains no call")


def compile_asm(compiler, source, gcc):
    common = ["-mno-abicalls", "-fno-pic", "-fomit-frame-pointer", "-O2", "-S"]
    target = ["-march=vr4300", "-mabi=o64"] if gcc else [
        "--target=mips64-elf", "-march=mips3", "-mabi=o64"]
    result = subprocess.run([compiler, *target, *common, "-o", "-", source],
                            capture_output=True, text=True)
    if result.returncode:
        sys.stderr.write(result.stderr)
        raise SystemExit(f"{compiler} failed")
    return functions(result.stdout)


GPR_RETURNS = {
    "s3_a", "s3_b", "s3_c", "s3_after_c", "s3_edge_a", "s3_edge_c",
    "s3_stack_a", "s3_stack_c", "s5_a", "s5_e", "s12_a", "s12_b",
    "s12_c", "s12_edge_c", "u8_q", "u8_w0", "u8_w1", "u8_b0", "u8_b7", "sdl_l",
    "va_i1", "va_l3", "ret_i8", "ret_u8", "ret_i16", "ret_u16",
    "ret_i32", "ret_u32", "ret_i64", "ret_ptr",
}
F32_RETURNS = {"sf_a", "sf_b", "ret_f32"}
F64_RETURNS = {"va_d0", "va_d2", "va_named", "ret_f64",
               "sd_d", "sd_after", "sdl_d", "cd_re", "cd_im"}
SRET_RETURNS = {"ret_s3", "ret_s12", "ret_big", "ret_u8_agg", "ret_sf"}
CALLS = {"call_var", "call_named"}


def output(machine, name):
    if name in GPR_RETURNS:
        return machine.gpr[2]
    if name in F32_RETURNS:
        return machine.fpr[0] & 0xFFFFFFFF
    if name in F64_RETURNS:
        return machine.fpr[0]
    if name in SRET_RETURNS:
        return (machine.gpr[2], bytes(machine.mem[0x200000 + i] for i in range(32)))
    raise AssertionError(name)


def default_compiler(env_name, executable, fallback):
    return os.environ.get(env_name) or shutil.which(executable) or str(fallback)


def main():
    project = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gcc", default=default_compiler(
        "MIPS_O64_GCC", "mips64-elf-gcc", Path.home() / "n64_toolchain/bin/mips64-elf-gcc"))
    builds = [parent / "build/bin/clang" for parent in project.parents[:2]]
    parser.add_argument("--clang", default=os.environ.get("MIPS_O64_CLANG") or
                        str(next((b for b in builds if b.is_file()), builds[0])))
    args = parser.parse_args()
    for compiler in (args.gcc, args.clang):
        if not Path(compiler).is_file() and not shutil.which(compiler):
            parser.error(f"compiler not found: {compiler}")

    with tempfile.TemporaryDirectory(prefix="o64-abi-") as directory:
        source = Path(directory) / "probes.c"
        source.write_text(SOURCE)
        gcc = compile_asm(args.gcc, source, True)
        clang = compile_asm(args.clang, source, False)

    groups = [
        ("aggregate arguments / big-endian packing",
         GPR_RETURNS - {n for n in GPR_RETURNS if n.startswith("ret_") or n.startswith("va_")}
         | {"sf_a", "sf_b", "sd_d", "sd_after", "sdl_d", "cd_re", "cd_im"}),
        ("mixed integer/FP varargs", {"va_d0", "va_i1", "va_d2", "va_l3", "va_named"}),
        ("scalar return locations", {n for n in GPR_RETURNS if n.startswith("ret_")}
         | {"ret_f32", "ret_f64"}),
        ("struct/union return locations", SRET_RETURNS),
    ]

    failures = []
    for title, names in groups:
        print(f"\n{title}")
        for name in sorted(names):
            try:
                matches = all(output(run_leaf(gcc[name], seed, name in SRET_RETURNS,
                                              name == "ret_ptr"), name)
                              == output(run_leaf(clang[name], seed, name in SRET_RETURNS,
                                                name == "ret_ptr"), name)
                              for seed in range(16))
            except (KeyError, ValueError) as error:
                matches = False
                failures.append(f"{name}: {error}")
            else:
                if not matches:
                    failures.append(f"{name}: ABI-visible output differs")
            print(f"  {'ok  ' if matches else 'DIFF'} {name}")

    print("\nvariadic call locations")
    call_stack_bytes = {"call_named": 0, "call_var": 8}
    for name in sorted(CALLS):
        try:
            matches = all(run_to_call(gcc[name], seed, call_stack_bytes[name]) ==
                          run_to_call(clang[name], seed, call_stack_bytes[name])
                          for seed in range(16))
        except (KeyError, ValueError) as error:
            matches = False
            failures.append(f"{name}: {error}")
        else:
            if not matches:
                failures.append(f"{name}: call-state differs")
        print(f"  {'ok  ' if matches else 'DIFF'} {name}")

    total = sum(len(names) for _, names in groups) + len(CALLS)
    print(f"\n{total - len(failures)}/{total} GCC differentials match")
    if failures:
        print("\nFailures:")
        for failure in failures:
            print(f"  {failure}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
