#!/usr/bin/env python3
"""Compare versioned RX 580 2048SP / TPU #212488 ROMs under tools/vbios/roms/."""
from __future__ import annotations

from pathlib import Path

DEVICE_2048SP = bytes.fromhex("0210DF6F")
DEVICE_RX570 = bytes.fromhex("0210FF67")
DEVICE_RX580 = bytes.fromhex("0210DF67")
ASIC_2048SP = bytes.fromhex("F0FDE60F")
ASIC_RX570 = bytes.fromhex("F07DE60F")

ROM_ORDER = (
    "v00_stock_6FDF_ssid2392.rom",
    "v10_tpu212488_upstream.rom",
    "v20_tpu212488_ssid2392.rom",
    "v30_tpu212488_ssid2392_pp1310.rom",
    "dump-from-card.rom",
)


def info(path: Path) -> None:
    data = path.read_bytes()
    length = data[2] * 512
    if length == 0 or length > len(data):
        length = len(data)
    checksum = sum(data[:length]) & 0xFF
    print(f"=== {path.name} ===")
    print(f"size={len(data)} checksum={checksum:#04x}")
    print(
        f"6FDF(2048SP)={DEVICE_2048SP in data}  "
        f"67FF(RX570)={DEVICE_RX570 in data}  "
        f"67DF(RX580)={DEVICE_RX580 in data}"
    )
    print(f"ASIC 2048SP={ASIC_2048SP in data}  ASIC RX570={ASIC_RX570 in data}")


def diffs(a: Path, b: Path) -> int:
    x, y = a.read_bytes(), b.read_bytes()
    n = min(len(x), len(y))
    return sum(i != j for i, j in zip(x[:n], y[:n])) + abs(len(x) - len(y))


def main() -> None:
    base = Path(__file__).resolve().parent / "vbios" / "roms"
    existing = [base / name for name in ROM_ORDER if (base / name).is_file()]
    if not existing:
        raise SystemExit(f"No ROM files in {base}")
    for p in existing:
        info(p)
        print()

    v00 = base / "v00_stock_6FDF_ssid2392.rom"
    v20 = base / "v20_tpu212488_ssid2392.rom"
    v30 = base / "v30_tpu212488_ssid2392_pp1310.rom"
    dump = base / "dump-from-card.rom"
    if v00.is_file() and v20.is_file():
        print(f"byte diffs  v00 vs v20: {diffs(v00, v20)}")
    if v20.is_file() and v30.is_file():
        print(f"byte diffs  v20 vs v30: {diffs(v20, v30)}")
    if v30.is_file() and dump.is_file():
        print(f"byte diffs  v30 vs dump-from-card: {diffs(v30, dump)}")


if __name__ == "__main__":
    main()
