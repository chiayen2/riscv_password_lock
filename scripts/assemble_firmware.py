from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

REG = {
    "zero": 0, "x0": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7, "s0": 8, "fp": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15,
    "a6": 16, "a7": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21,
    "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28, "t4": 29, "t5": 30, "t6": 31,
}


def imm_value(token: str) -> int:
    return int(token, 0)


def sign_range(value: int, bits: int) -> int:
    lo = -(1 << (bits - 1))
    hi = (1 << (bits - 1)) - 1
    if not lo <= value <= hi:
        raise ValueError(f"immediate {value} does not fit signed {bits}")
    return value & ((1 << bits) - 1)


def r_type(funct7, rs2, rs1, funct3, rd, opcode=0x33):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def i_type(imm, rs1, funct3, rd, opcode=0x13):
    imm = sign_range(imm, 12)
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def load_type(imm, rs1, funct3, rd):
    return i_type(imm, rs1, funct3, rd, 0x03)


def s_type(imm, rs2, rs1, funct3, opcode=0x23):
    imm = sign_range(imm, 12)
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm & 0x1F) << 7) | opcode


def b_type(imm, rs2, rs1, funct3, opcode=0x63):
    imm = sign_range(imm, 13)
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | opcode


def u_type(imm20, rd, opcode=0x37):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | opcode


def j_type(imm, rd, opcode=0x6F):
    imm = sign_range(imm, 21)
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12) | (rd << 7) | opcode


def clean_lines(path: Path):
    out = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if not line or line.startswith("."):
            continue
        out.append(line)
    return out


def expand(line: str):
    if line.endswith(":"):
        return [line]
    op, *rest = re.split(r"\s+", line, maxsplit=1)
    args = []
    if rest:
        args = [a.strip() for a in rest[0].split(",")]
    if op == "li":
        rd, imm_s = args
        imm = imm_value(imm_s)
        if -2048 <= imm <= 2047:
            return [f"addi {rd}, zero, {imm}"]
        hi = (imm + 0x800) >> 12
        lo = imm - (hi << 12)
        seq = [f"lui {rd}, {hi}"]
        if lo:
            seq.append(f"addi {rd}, {rd}, {lo}")
        return seq
    if op == "j":
        return [f"jal zero, {args[0]}"]
    return [line]


def parse_mem(arg: str):
    m = re.match(r"(-?\d+|0x[0-9a-fA-F]+)\(([^)]+)\)", arg)
    if not m:
        raise ValueError(f"bad memory operand {arg}")
    return imm_value(m.group(1)), REG[m.group(2)]


def assemble(src: Path):
    expanded = []
    for line in clean_lines(src):
        expanded.extend(expand(line))
    labels = {}
    pc = 0
    insts = []
    for line in expanded:
        if line.endswith(":"):
            labels[line[:-1]] = pc
        else:
            insts.append((pc, line))
            pc += 4
    words = []
    for pc, line in insts:
        op, *rest = re.split(r"\s+", line, maxsplit=1)
        args = [a.strip() for a in rest[0].split(",")] if rest else []
        if op == "lui":
            word = u_type(imm_value(args[1]), REG[args[0]])
        elif op == "addi":
            word = i_type(imm_value(args[2]), REG[args[1]], 0x0, REG[args[0]])
        elif op == "andi":
            word = i_type(imm_value(args[2]), REG[args[1]], 0x7, REG[args[0]])
        elif op == "slli":
            word = i_type(imm_value(args[2]), REG[args[1]], 0x1, REG[args[0]])
        elif op == "srli":
            word = i_type(imm_value(args[2]), REG[args[1]], 0x5, REG[args[0]])
        elif op == "lw":
            imm, rs1 = parse_mem(args[1])
            word = load_type(imm, rs1, 0x2, REG[args[0]])
        elif op == "sw":
            imm, rs1 = parse_mem(args[1])
            word = s_type(imm, REG[args[0]], rs1, 0x2)
        elif op == "beq":
            word = b_type(labels[args[2]] - pc, REG[args[1]], REG[args[0]], 0x0)
        elif op == "bne":
            word = b_type(labels[args[2]] - pc, REG[args[1]], REG[args[0]], 0x1)
        elif op == "jal":
            word = j_type(labels[args[1]] - pc, REG[args[0]])
        else:
            raise ValueError(f"unsupported op {op} in {line}")
        words.append(word)
    return words


def main():
    words = assemble(ROOT / "firmware" / "final_project.s")
    data = b"".join(w.to_bytes(4, "little") for w in words)
    (ROOT / "firmware" / "final_project.bin").write_bytes(data)
    (ROOT / "firmware" / "final_project.mem").write_text("\n".join(f"{w:08x}" for w in words) + "\n", encoding="ascii")
    (ROOT / "firmware" / "final_project.hex").write_text("\n".join(f"{b:02x}" for b in data) + "\n", encoding="ascii")
    print(f"Wrote {len(words)} instructions, {len(data)} bytes")


if __name__ == "__main__":
    main()
