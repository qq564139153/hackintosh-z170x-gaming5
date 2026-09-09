#!/usr/bin/env python3
"""Compare dumped / original / patched RX 580 2048SP ROMs."""
from __future__ import annotations

from pathlib import Path

DEVICE_2048SP = bytes.fromhex("0210DF6F")
DEVICE_RX570 = bytes.fromhex("0210FF67")
DEVICE_RX580 = bytes.fromhex("0210DF67")
ASIC_2048SP = bytes.fromhex("F0FDE60F")
ASIC_RX570 = bytes.fromhex("F07DE60F")


def info(path: Path) -> None:
    data = path.read_bytes()
    length = data[2] * 512
    if length == 0 or length > len(data):
        length = len(data)
    checksum = sum(data[:length]) & 0xFF
    print(f"=== {path.name} ===")
    print(f"size={len(data)} checksum={checksum:#04x}")
    print(f"6FDF(2048SP)={DEVICE_2048SP in data}  67FF(RX570)={DEVICE_RX570 in data}  67DF(RX580)={DEVICE_RX580 in data}")
    print(f"ASIC 2048SP={ASIC_2048SP in data}  ASIC RX570={ASIC_RX570 in data}")


def diffs(a: Path, b: Path) -> int:
    x, y = a.read_bytes(), b.read_bytes()
    n = min(len(x), len(y))
    return sum(i != j for i, j in zip(x[:n], y[:n])) + abs(len(x) - len(y))


def main() -> None:
    base = Path(__file__).resolve().parent / "vbios" / "roms"
    files = [
        base / "RX580-original.rom",
        base / "RX580_idonly_67df_fixed.rom",
        base / "RX580_rx570_patched_fixed.rom",
        base / "RX580-from-card.rom",
        base / "RX580-now.rom",
    ]
    existing = [p for p in files if p.is_file()]
    if not existing:
        raise SystemExit(f"No ROM files in {base}")
    for p in existing:
        info(p)
        print()
    orig = base / "RX580-original.rom"
    card = next((p for p in (base / "RX580-from-card.rom", base / "RX580-now.rom") if p.is_file()), None)
    patched = base / "RX580_rx570_patched_fixed.rom"
    idonly = base / "RX580_idonly_67df_fixed.rom"
    if orig.is_file() and card is not None:
        print(f"byte diffs  original vs {card.name}: {diffs(orig, card)}")
    if idonly.is_file() and orig.is_file():
        print(f"byte diffs  original vs {idonly.name}: {diffs(orig, idonly)}")
    if patched.is_file() and card is not None:
        print(f"byte diffs  patched  vs {card.name}: {diffs(patched, card)}")


if __name__ == "__main__":
    main()
