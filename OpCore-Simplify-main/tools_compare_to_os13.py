#!/usr/bin/env python3
"""Compare OpCore Simplify Results config vs current OS_13 EFI."""
from __future__ import annotations

import json
import os
import plistlib
import sys
from pathlib import Path

ROOT = Path(r"c:\Users\sean\project-code\hackintosh")
SIMPLIFY = ROOT / "OpCore-Simplify-main" / "Results" / "EFI" / "OC" / "config.plist"
CURRENT = (
    ROOT
    / "OpenCore EFI"
    / "EFI-GIGABYTE Z170X-GAMING 5"
    / "OS_13"
    / "EFI"
    / "OC"
    / "config.plist"
)
OUT = ROOT / "OpCore-Simplify-main" / "Results" / "_diff_vs_os13.json"


def load(p: Path):
    with open(p, "rb") as f:
        return plistlib.load(f)


def kext_names(cfg):
    return [e.get("BundlePath") for e in cfg.get("Kernel", {}).get("Add", []) if e.get("Enabled", True)]


def ssdt_names(cfg):
    return [e.get("Path") for e in cfg.get("ACPI", {}).get("Add", []) if e.get("Enabled", True)]


def boot_args(cfg):
    add = cfg.get("NVRAM", {}).get("Add", {})
    block = add.get("7C436110-AB2A-4BBB-A880-FE41995C9F82", {})
    return block.get("boot-args", "")


def smbios(cfg):
    return cfg.get("PlatformInfo", {}).get("Generic", {}).get("SystemProductName")


def get_quirks(cfg, section):
    return cfg.get(section, {}).get("Quirks", {})


def device_props(cfg):
    return cfg.get("DeviceProperties", {}).get("Add", {})


def summarize_props(props: dict):
    out = {}
    for path, keys in props.items():
        out[path] = sorted(keys.keys())
    return out


def quirk_diff(a: dict, b: dict):
    keys = sorted(set(a) | set(b))
    diffs = {}
    for k in keys:
        va, vb = a.get(k, "<missing>"), b.get(k, "<missing>")
        if va != vb:
            diffs[k] = {"simplify": va, "os13": vb}
    return diffs


def main():
    if not SIMPLIFY.exists():
        raise SystemExit(f"missing simplify config: {SIMPLIFY}")
    if not CURRENT.exists():
        raise SystemExit(f"missing current config: {CURRENT}")

    s, c = load(SIMPLIFY), load(CURRENT)

    sk, ck = set(kext_names(s)), set(kext_names(c))
    sa, ca = set(ssdt_names(s)), set(ssdt_names(c))

    report = {
        "smbios": {"simplify": smbios(s), "os13": smbios(c)},
        "boot-args": {"simplify": boot_args(s), "os13": boot_args(c)},
        "kexts_only_in_simplify": sorted(sk - ck),
        "kexts_only_in_os13": sorted(ck - sk),
        "kexts_common": sorted(sk & ck),
        "acpi_only_in_simplify": sorted(sa - ca),
        "acpi_only_in_os13": sorted(ca - sa),
        "acpi_common": sorted(sa & ca),
        "DeviceProperties_simplify": summarize_props(device_props(s)),
        "DeviceProperties_os13": summarize_props(device_props(c)),
        "Kernel_Quirks": quirk_diff(get_quirks(s, "Kernel"), get_quirks(c, "Kernel")),
        "Booter_Quirks": quirk_diff(get_quirks(s, "Booter"), get_quirks(c, "Booter")),
        "UEFI_Quirks": quirk_diff(get_quirks(s, "UEFI"), get_quirks(c, "UEFI")),
        "Misc_Debug": {
            "simplify": s.get("Misc", {}).get("Debug", {}),
            "os13": c.get("Misc", {}).get("Debug", {}),
        },
        "Misc_Security_SecureBootModel": {
            "simplify": s.get("Misc", {}).get("Security", {}).get("SecureBootModel"),
            "os13": c.get("Misc", {}).get("Security", {}).get("SecureBootModel"),
        },
        "UEFI_Audio": {
            "simplify": s.get("UEFI", {}).get("Audio", {}),
            "os13": c.get("UEFI", {}).get("Audio", {}),
        },
        "UEFI_Output": {
            "simplify": {
                k: s.get("UEFI", {}).get("Output", {}).get(k)
                for k in ("Resolution", "ForceResolution", "UIScale")
            },
            "os13": {
                k: c.get("UEFI", {}).get("Output", {}).get(k)
                for k in ("Resolution", "ForceResolution", "UIScale")
            },
        },
    }

    # AirportBrcmFixup bug probe
    import importlib.util

    pci_path = ROOT / "OpCore-Simplify-main" / "Scripts" / "datasets" / "pci_data.py"
    spec = importlib.util.spec_from_file_location("pci_data", pci_path)
    pci = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(pci)
    ids = pci.BroadcomWiFiIDs
    idx = ids.index("14E4-43A0")
    report["opcore_bug_AirportBrcm_43A0"] = {
        "index": idx,
        "in_slice_0_15": "14E4-43A0" in ids[:15],
        "equals_index_15": ids[15] == "14E4-43A0",
        "in_slice_16_18": "14E4-43A0" in ids[16:18],
        "would_select_AirportBrcmFixup": (
            ("14E4-43A0" in ids[:15])
            or (ids[15] == "14E4-43A0")
            or ("14E4-43A0" in ids[16:18])
        ),
        "ids_16_to_end": ids[16:],
    }

    # PM991 / A809 note
    report["opcore_nvme_note"] = {
        "report_device": "144D-A809 / MZ9LQ128HBHQ (PM991)",
        "unsupported_list_has_A808_only": "144D-A808" in pci.UnsupportedNVMeSSDIDs,
        "unsupported_list_has_A809": "144D-A809" in pci.UnsupportedNVMeSSDIDs,
    }

    # SATA A102 skip
    report["opcore_sata_note"] = {
        "A102_in_UnsupportedSATA": "8086-A102" in pci.UnsupportedSATAControllerIDs,
        "auto_select_skipped_because_name_contains_AHCI": True,
        "CtlnaAHCIPort_in_simplify_kexts": any("CtlnaAHCI" in x for x in sk),
        "CtlnaAHCIPort_in_os13_kexts": any("CtlnaAHCI" in x for x in ck),
    }

    OUT.write_text(json.dumps(report, indent=2, ensure_ascii=False, default=str), encoding="utf-8")
    print(json.dumps(report, indent=2, ensure_ascii=False, default=str))
    print("\nWrote", OUT)


if __name__ == "__main__":
    main()
