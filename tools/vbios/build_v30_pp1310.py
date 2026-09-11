#!/usr/bin/env python3
"""Build v30: v20 (#212488 + SSID 2392) with stock PowerPlay clocks/TDP restored.

Copies SCLK P0–P7 and PowerTune TDP/TDC/limits from v00 stock into v20,
then fixes the Option ROM checksum. Does not change Device ID / SSID / memory straps.
"""
from __future__ import annotations

import hashlib
import struct
import sys
from pathlib import Path

ROMS = Path(__file__).resolve().parent / "roms"
V00 = ROMS / "v00_stock_6FDF_ssid2392.rom"
V20 = ROMS / "v20_tpu212488_ssid2392.rom"
V30 = ROMS / "v30_tpu212488_ssid2392_pp1310.rom"


def u16(data: bytes | bytearray, off: int) -> int:
    return struct.unpack_from("<H", data, off)[0]


def u32(data: bytes | bytearray, off: int) -> int:
    return struct.unpack_from("<I", data, off)[0]


def pp_tables(data: bytes | bytearray) -> tuple[int, int, int]:
    rom_hdr = u16(data, 0x48)
    master = u16(data, rom_hdr + 32)
    pp = u16(data, master + 4 + 15 * 2)
    sclk = pp + u16(data, pp + 45)
    pt = pp + u16(data, pp + 57)
    return pp, sclk, pt


def fix_checksum(data: bytearray) -> int:
    if data[0:2] != b"\x55\xaa":
        raise SystemExit("Not a PCI Option ROM (missing 55 AA)")
    length = data[2] * 512
    if length == 0 or length > len(data):
        length = len(data)
    before = sum(data[0:length]) & 0xFF
    if before:
        data[0x21] = (data[0x21] - before) & 0xFF
    after = sum(data[0:length]) & 0xFF
    if after != 0:
        raise SystemExit(f"Checksum still non-zero: {after:#04x}")
    return after


def main() -> None:
    if not V00.is_file() or not V20.is_file():
        raise SystemExit(f"Need {V00.name} and {V20.name}")

    stock = V00.read_bytes()
    base = bytearray(V20.read_bytes())
    _, ssclk, spt = pp_tables(stock)
    _, bsclk, bpt = pp_tables(base)

    n = base[bsclk + 1]
    if n != stock[ssclk + 1]:
        raise SystemExit(f"SCLK entry count mismatch: stock={stock[ssclk+1]} base={n}")

    entry = 15
    print("SCLK:")
    for i in range(n):
        so = ssclk + 2 + i * entry + 3
        bo = bsclk + 2 + i * entry + 3
        old, new = u32(base, bo), u32(stock, so)
        struct.pack_into("<I", base, bo, new)
        print(f"  P{i}: {old / 100:.0f} -> {new / 100:.0f} MHz")

    print("PowerTune:")
    for off, label in (
        (1, "TDP"),
        (5, "TDC"),
        (7, "Battery"),
        (9, "Small"),
        (15, "MaxPowerDelivery"),
    ):
        old, new = u16(base, bpt + off), u16(stock, spt + off)
        struct.pack_into("<H", base, bpt + off, new)
        print(f"  {label}: {old} -> {new}")

    fix_checksum(base)
    V30.write_bytes(base)
    print(f"Wrote {V30}")
    print(f"MD5   {hashlib.md5(base).hexdigest()}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
