#!/usr/bin/env python3
"""Fix PC Option ROM / AtomBIOS 8-bit checksum at offset 0x21."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def fix_checksum(data: bytearray) -> tuple[int, int]:
    if data[0:2] != b"\x55\xaa":
        raise SystemExit("Not a PCI Option ROM (missing 55 AA)")
    blocks = data[2]
    length = blocks * 512
    if length == 0 or length > len(data):
        length = len(data)
    before = sum(data[0:length]) & 0xFF
    if before:
        data[0x21] = (data[0x21] - before) & 0xFF
    after = sum(data[0:length]) & 0xFF
    return before, after


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args()
    data = bytearray(args.rom.read_bytes())
    before, after = fix_checksum(data)
    out = args.output or args.rom.with_name(args.rom.stem + "_fixed" + args.rom.suffix)
    out.write_bytes(data)
    print(f"Input : {args.rom}")
    print(f"Output: {out}")
    print(f"Checksum before={before:#04x} after={after:#04x}")
    if after != 0:
        raise SystemExit("Checksum still non-zero")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
