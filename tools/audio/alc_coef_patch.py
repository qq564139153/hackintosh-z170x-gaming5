"""Diff two alc_coef_dump.sh outputs and optionally append fix verbs to AppleALC ConfigData.

Usage:
  python alc_coef_patch.py diff  <good.txt> <bad.txt> [--node 0x20]
  python alc_coef_patch.py apply <Info.plist> --verbs 0x10=0x0020,0x37=0x0101
                                 [--codec 0x10EC0900] [--layout 5] [--node 0x20] [--wake]
  python alc_coef_patch.py show  <Info.plist> [--codec 0x10EC0900] [--layout 5]

`diff` prints differing coefficients plus alc-verb test commands and packed verbs.
`apply` appends SET_COEF_INDEX/SET_PROC_COEF pairs to ConfigData (and WakeConfigData
with --wake) of the matching HDAConfigDefault entry; a .bak copy is written first.
"""

import argparse
import base64
import plistlib
import re
import shutil
import sys
from pathlib import Path

COEF_RE = re.compile(r"Coeff\s+(0x[0-9a-fA-F]+):\s+(0x[0-9a-fA-F]+)")


def load_dump(path):
    coefs = {}
    for line in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
        m = COEF_RE.search(line)
        if m:
            coefs[int(m.group(1), 16)] = int(m.group(2), 16)
    if not coefs:
        sys.exit(f"no 'Coeff 0xNN: 0xVVVV' lines in {path}")
    return coefs


def pack_pair(node, index, value):
    return [
        (node << 20) | (0x5 << 16) | (index & 0xFFFF),
        (node << 20) | (0x4 << 16) | (value & 0xFFFF),
    ]


def verbs_to_bytes(verbs):
    return b"".join(v.to_bytes(4, "big") for v in verbs)


def parse_verbs(spec):
    pairs = []
    for item in spec.split(","):
        idx, val = item.split("=")
        pairs.append((int(idx, 0), int(val, 0)))
    return pairs


def find_entry(info, codec, layout):
    for pers in info.get("IOKitPersonalities", {}).values():
        for entry in pers.get("HDAConfigDefault", []):
            if entry.get("CodecID") == codec and entry.get("LayoutID") == layout:
                return entry
    sys.exit(f"HDAConfigDefault entry CodecID={codec:#x} LayoutID={layout} not found")


def cmd_diff(args):
    good, bad = load_dump(args.good), load_dump(args.bad)
    node = int(args.node, 0)
    diffs = [(i, good[i], bad[i]) for i in sorted(good) if i in bad and good[i] != bad[i]]
    if not diffs:
        print("No coefficient differences: the vendor node is not the cause (or dumps were taken in the same state).")
        return
    print(f"{len(diffs)} differing coefficient(s) on node {node:#04x} (good -> bad):")
    for i, g, b in diffs:
        print(f"  coef {i:#04x}: good={g:#06x} bad={b:#06x} xor={g ^ b:#06x}")
    print("\nTest live on the broken (warm) boot, one pair at a time:")
    for i, g, _ in diffs:
        print(f"  alc-verb {node:#04x} SET_COEF_INDEX {i:#04x}; alc-verb {node:#04x} SET_PROC_COEF {g:#06x}")
    print("\nPacked verbs (append to ConfigData once the minimal set is known):")
    for i, g, _ in diffs:
        print("  " + " ".join(f"{v:08X}" for v in pack_pair(node, i, g)) + f"   # coef {i:#04x}={g:#06x}")
    spec = ",".join(f"{i:#04x}={g:#06x}" for i, g, _ in diffs)
    print(f"\napply all: python alc_coef_patch.py apply <Info.plist> --verbs {spec}")


def cmd_show(args):
    info = plistlib.loads(Path(args.plist).read_bytes())
    entry = find_entry(info, int(args.codec, 0), args.layout)
    for key in ("ConfigData", "WakeConfigData"):
        data = entry.get(key, b"")
        words = [data[i:i + 4].hex().upper() for i in range(0, len(data), 4)]
        print(f"{key} ({len(data)} bytes): {' '.join(words)}")
    print(f"WakeVerbReinit: {entry.get('WakeVerbReinit')}")


def cmd_apply(args):
    path = Path(args.plist)
    info = plistlib.loads(path.read_bytes())
    entry = find_entry(info, int(args.codec, 0), args.layout)
    node = int(args.node, 0)
    verbs = []
    for idx, val in parse_verbs(args.verbs):
        verbs += pack_pair(node, idx, val)
    blob = verbs_to_bytes(verbs)

    keys = ["ConfigData"] + (["WakeConfigData"] if args.wake else [])
    for key in keys:
        old = entry.get(key, b"")
        if old.endswith(blob):
            print(f"{key}: verbs already present, skipped")
            continue
        entry[key] = old + blob
        print(f"{key}: {len(old)} -> {len(entry[key])} bytes, base64={base64.b64encode(entry[key]).decode()}")
    if args.wake:
        entry["WakeVerbReinit"] = True

    backup = path.with_suffix(path.suffix + ".bak")
    if not backup.exists():
        shutil.copy2(path, backup)
        print(f"backup: {backup}")
    path.write_bytes(plistlib.dumps(info, sort_keys=False))
    print(f"patched: {path}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    d = sub.add_parser("diff")
    d.add_argument("good")
    d.add_argument("bad")
    d.add_argument("--node", default="0x20")
    d.set_defaults(func=cmd_diff)

    for name, func in (("apply", cmd_apply), ("show", cmd_show)):
        p = sub.add_parser(name)
        p.add_argument("plist")
        p.add_argument("--codec", default="0x10EC0900")
        p.add_argument("--layout", type=int, default=5)
        if name == "apply":
            p.add_argument("--verbs", required=True, help="idx=value pairs, e.g. 0x10=0x0020,0x37=0x0101")
            p.add_argument("--node", default="0x20")
            p.add_argument("--wake", action="store_true", help="also append to WakeConfigData")
        p.set_defaults(func=func)

    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
