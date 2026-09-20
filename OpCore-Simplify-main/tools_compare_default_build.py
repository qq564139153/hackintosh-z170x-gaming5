#!/usr/bin/env python3
"""Non-interactive OpCore Simplify build for Ventura, then dump selection summary."""
from __future__ import annotations

import importlib.util
import json
import os
import sys
import traceback

ROOT = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, ROOT)

import Scripts.utils as utils_mod


def _auto_input(self, prompt="Press Enter to continue..."):
    p = prompt.lower()
    if "force load" in p:
        ans = "no"
    elif "continue with opencore legacy patcher" in p:
        ans = "no"
    elif "build efi for uefi" in p:
        ans = "yes"
    elif "(yes/no)" in p or "yes/no" in p:
        ans = "no"
    elif "select" in p and "default" in p:
        ans = ""
    elif "select a" in p or "select which" in p or "select your option" in p:
        ans = "1"
    else:
        ans = ""
    print(f"[auto] {prompt.strip()} -> {ans!r}")
    return ans


utils_mod.Utils.request_input = _auto_input


def main():
    spec = importlib.util.spec_from_file_location(
        "opcore_simplify", os.path.join(ROOT, "OpCore-Simplify.py")
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    OCPE = mod.OCPE

    o = OCPE()
    report_path = os.path.join(ROOT, "SysReport", "Report.json")
    acpi_dir = os.path.join(ROOT, "SysReport", "ACPI")

    hardware_report = o.u.read_file(report_path)
    o.ac.read_acpi_tables(acpi_dir)

    hardware_report, native_macos_version, ocl_patched_macos_version = o.c.check_compatibility(
        hardware_report
    )

    # Match user's daily OS_13 / Ventura.
    macos_version = "22.99.99"
    print(f"native={native_macos_version} oclp={ocl_patched_macos_version} target={macos_version}")

    customized_hardware, disabled_devices, needs_oclp = o.h.hardware_customization(
        hardware_report, macos_version
    )
    smbios_model = o.s.select_smbios_model(customized_hardware, macos_version)
    print(f"smbios={smbios_model} needs_oclp={needs_oclp} disabled={list(disabled_devices)}")

    if not o.ac.ensure_dsdt():
        raise SystemExit("DSDT missing after read_acpi_tables")

    o.ac.select_acpi_patches(customized_hardware, disabled_devices)
    needs_oclp = o.k.select_required_kexts(
        customized_hardware, macos_version, needs_oclp, o.ac.patches
    )
    o.s.smbios_specific_options(
        customized_hardware, smbios_model, macos_version, o.ac.patches, o.k
    )

    selected_patches = [p.name for p in o.ac.patches if p.checked]
    selected_kexts = [k.name for k in o.k.kexts if k.checked]
    print("ACPI:", selected_patches)
    print("Kexts:", selected_kexts)

    os.makedirs(os.path.join(ROOT, "Results"), exist_ok=True)
    out_summary = os.path.join(ROOT, "Results", "_compare_summary.json")
    summary = {
        "macos_version": macos_version,
        "smbios_model": smbios_model,
        "needs_oclp": needs_oclp,
        "disabled_devices": list(disabled_devices.keys()),
        "acpi_patches": selected_patches,
        "kexts": selected_kexts,
        "native_macos_version": list(native_macos_version) if native_macos_version else None,
        "ocl_patched_macos_version": list(ocl_patched_macos_version)
        if ocl_patched_macos_version
        else None,
    }
    with open(out_summary, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)

    print("Gathering bootloader/kexts (may use cache / network)...")
    o.o.gather_bootloader_kexts(o.k.kexts, macos_version)
    o.build_opencore_efi(
        customized_hardware, disabled_devices, smbios_model, macos_version, needs_oclp
    )
    print("Built EFI at:", o.result_dir)
    print("Summary:", out_summary)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        traceback.print_exc()
        sys.exit(1)
