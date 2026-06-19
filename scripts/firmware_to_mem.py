from pathlib import Path
import argparse


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert a raw RISC-V binary to byte hex and readmemh word files.")
    parser.add_argument("bin", type=Path, help="Input raw little-endian firmware binary")
    parser.add_argument("--hex", type=Path, default=Path("firmware/final_project.hex"))
    parser.add_argument("--mem", type=Path, default=Path("firmware/final_project.mem"))
    args = parser.parse_args()

    data = args.bin.read_bytes()
    args.hex.parent.mkdir(parents=True, exist_ok=True)
    args.mem.parent.mkdir(parents=True, exist_ok=True)
    args.hex.write_text("\n".join(f"{byte:02x}" for byte in data) + "\n", encoding="ascii")

    words = []
    for offset in range(0, len(data), 4):
        chunk = data[offset:offset + 4].ljust(4, b"\x00")
        words.append(int.from_bytes(chunk, "little"))
    args.mem.write_text("\n".join(f"{word:08x}" for word in words) + "\n", encoding="ascii")
    print(f"Wrote {len(data)} bytes and {len(words)} 32-bit words.")


if __name__ == "__main__":
    main()
