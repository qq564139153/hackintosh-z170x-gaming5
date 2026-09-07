#!/usr/bin/env python3
"""
Patch RX 580 2048SP (device-id 0x6FDF) VBIOS for native macOS drivers.

Usage (Windows):
  1. In GPU-Z: Graphics Card -> BIOS Version -> click arrow -> "Save to file"
     Save as e.g. original_6fdf.rom  (KEEP THIS BACKUP)
  2. python patch_rx580_2048sp_vbios.py original_6fdf.rom
  3. Open the *_patched.rom in PolarisBiosEditor and save once (fixes checksum)
  4. Flash with amdvbflash (admin CMD), e.g.:
       amdvbflash -i
       amdvbflash -unlockrom 0
       amdvbflash -p 0 your_patched_fixed.rom
  5. Reboot. After success, you can remove GPU DeviceProperties spoof from OpenCore.

WARNING: Wrong flash can brick the GPU (usually recoverable with dual-BIOS or
motherboard PCI-E recovery). Always keep the original .rom.
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


def patch_rom(src: Path, target: str) -> Path:
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
    asic_hits = replace_all(raw, ASIC_2048SP, asic_new)

    # Already partially patched ROM support
    if device_hits == 0 and device_new in raw:
        print("Note: device-id already matches target (or was previously patched).")
    if asic_hits == 0 and asic_new in raw:
        print("Note: ASIC id already matches target (or was previously patched).")

    if device_hits == 0 and asic_hits == 0 and DEVICE_ID_2048SP not in raw:
        raise SystemExit("Nothing to patch. Is this already a non-2048SP ROM?")

    out = src.with_name(f"{src.stem}_{label}_patched{src.suffix or '.rom'}")
    out.write_bytes(raw)

    print(f"Input : {src}")
    print(f"Output: {out}")
    print(f"Replaced device-id 6FDF -> {label.upper()}: {device_hits} hit(s)")
    print(f"Replaced ASIC 2048SP -> {label.upper()}: {asic_hits} hit(s)")
    print()
    print("Next:")
    print("  1) Open output in PolarisBiosEditor -> Save (fix checksum)")
    print("  2) Flash with amdvbflash (keep original ROM backup)")
    print("  3) Prefer target RX 570 for most Chinese 2048SP cards")
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Patch RX 580 2048SP VBIOS for macOS")
    parser.add_argument("rom", type=Path, help="GPU-Z dumped .rom/.bin")
    parser.add_argument(
        "--target",
        choices=("570", "580"),
        default="570",
        help="Spoof as RX 570 (default, recommended) or RX 580",
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

    patch_rom(args.rom, args.target)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
