#!/usr/bin/env python3
"""
Patch RX 580 2048SP (device-id 0x6FDF) VBIOS for native macOS drivers.

Preferred (this card, PowerColor 113-D000340_2048):
  python patch_rx580_2048sp_vbios.py original.rom --target 580 --id-only
  python tools/fix_vbios_checksum.py tools/vbios/roms/RX580-original_rx580_idonly.rom

That only changes PCI Device ID 6FDF→67DF in ATOM + GOP PCIR (the 机器码).
Do NOT change ASIC at 0xD4 unless a later flash still fails macOS ID checks.

Usage (Windows):
  1. GPU-Z: save original .rom (KEEP THIS BACKUP)
  2. Run this script, then fix_vbios_checksum.py
  3. Flash with AMDVBFLASH 3.31 EXTERNAL only
  4. Shut down and cut PSU ~10s. After success, remove OpenCore GPU spoof.

WARNING: Wrong flash can brick display (usually recoverable with iGPU / RDP).
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

# Device ID PCI descriptor: vendor 1002 + device
DEVICE_ID_2048SP = bytes.fromhex("0210DF6F")  # 1002:6FDF
DEVICE_ID_RX570 = bytes.fromhex("0210FF67")  # 1002:67FF
DEVICE_ID_RX580 = bytes.fromhex("0210DF67")  # 1002:67DF

# ASIC ID table (common Polaris ROM markers)
ASIC_2048SP = bytes.fromhex("F0FDE60F")
ASIC_RX570 = bytes.fromhex("F07DE60F")
ASIC_RX580 = bytes.fromhex("F07DE607")


def replace_all(data: bytearray, old: bytes, new: bytes) -> int:
    if len(old) != len(new):
        raise ValueError("old/new length mismatch")
    count = 0
    start = 0
    while True:
        idx = data.find(old, start)
        if idx < 0:
            break
        data[idx : idx + len(new)] = new
        count += 1
        start = idx + len(new)
    return count


def patch_rom(src: Path, target: str, id_only: bool) -> Path:
    raw = bytearray(src.read_bytes())
    if DEVICE_ID_2048SP not in raw and DEVICE_ID_RX570 not in raw and DEVICE_ID_RX580 not in raw:
        raise SystemExit(
            "ROM does not look like Polaris RX 570/580/2048SP (missing known device-id bytes). "
            "Aborting to avoid corrupting an unrelated file."
        )

    if target == "570":
        device_new, asic_new, label = DEVICE_ID_RX570, ASIC_RX570, "rx570"
    else:
        device_new, asic_new, label = DEVICE_ID_RX580, ASIC_RX580, "rx580"

    device_hits = replace_all(raw, DEVICE_ID_2048SP, device_new)
    asic_hits = 0 if id_only else replace_all(raw, ASIC_2048SP, asic_new)

    if device_hits == 0 and device_new in raw:
        print("Note: device-id already matches target (or was previously patched).")
    if not id_only and asic_hits == 0 and asic_new in raw:
        print("Note: ASIC id already matches target (or was previously patched).")

    if device_hits == 0 and asic_hits == 0 and DEVICE_ID_2048SP not in raw:
        raise SystemExit("Nothing to patch. Is this already a non-2048SP ROM?")

    suffix = "idonly" if id_only else "patched"
    out = src.with_name(f"{src.stem}_{label}_{suffix}{src.suffix or '.rom'}")
    out.write_bytes(raw)

    print(f"Input : {src}")
    print(f"Output: {out}")
    print(f"Replaced device-id 6FDF -> {label.upper()}: {device_hits} hit(s)")
    if id_only:
        print("ASIC at 0xD4 left unchanged (id-only / 机器码 mode)")
    else:
        print(f"Replaced ASIC 2048SP -> {label.upper()}: {asic_hits} hit(s)")
    print()
    print("Next:")
    print("  1) python tools/fix_vbios_checksum.py <output>")
    print("  2) Flash with AMDVBFLASH 3.31 EXTERNAL (keep original ROM backup)")
    print("  3) Prefer --target 580 --id-only first; 570 ASIC drops GOP signature")
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Patch RX 580 2048SP VBIOS for macOS")
    parser.add_argument("rom", type=Path, help="GPU-Z dumped .rom/.bin")
    parser.add_argument(
        "--target",
        choices=("570", "580"),
        default="580",
        help="PCI Device ID: 580=67DF (default, keeps WHQL/GOP better) or 570=67FF",
    )
    parser.add_argument(
        "--id-only",
        action="store_true",
        help="Only change Device ID (机器码). Do not touch ASIC at 0xD4.",
    )
    parser.add_argument(
        "--backup",
        action="store_true",
        help="Also copy original beside output as *.original.bak",
    )
    args = parser.parse_args()

    if not args.rom.is_file():
        raise SystemExit(f"File not found: {args.rom}")

    if args.backup:
        bak = args.rom.with_suffix(args.rom.suffix + ".original.bak")
        if not bak.exists():
            shutil.copy2(args.rom, bak)
            print(f"Backup: {bak}")

    patch_rom(args.rom, args.target, args.id_only)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
