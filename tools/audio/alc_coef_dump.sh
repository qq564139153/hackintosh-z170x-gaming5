#!/bin/bash
# Dump Realtek vendor-node processing coefficients via AppleALC alc-verb.
#
# Usage: ./alc_coef_dump.sh <label> [device-index] [node-id] [count]
#   label         cold | warm-win | warm-reset ... (used in output filename)
#   device-index  default 0 (see `alc-verb -l`)
#   node-id       default 0x20 (ALC1150 vendor widget)
#   count         default 0x80
#
# Requires: alc-verb on PATH (from the AppleALC release zip) and
# `alcverbs=1` in boot-args.

set -u

label="${1:-}"
dev="${2:-0}"
node="${3:-0x20}"
count="${4:-0x80}"

if [ -z "$label" ]; then
  echo "Usage: $0 <label> [device-index] [node-id] [count]"
  exit 1
fi

if ! command -v alc-verb >/dev/null 2>&1; then
  echo "alc-verb not found in PATH (copy it from the AppleALC release zip to /usr/local/bin)"
  exit 1
fi

if ! alc-verb -d "$dev" "$node" GET_COEF_INDEX 0 >/dev/null 2>&1; then
  echo "alc-verb failed: check boot-args contains alcverbs=1 and device index ($(alc-verb -l 2>&1 | tr '\n' ' '))"
  exit 1
fi

out="coef-${label}-$(date +%Y%m%d-%H%M%S).txt"
{
  echo "# label=$label device=$dev node=$node count=$count"
  echo "# boot-args=$(nvram boot-args 2>/dev/null | cut -f2-)"
  echo "# os=$(sw_vers -productVersion) date=$(date)"
  echo "Node $node"
  for (( i = 0; i < $((count)); i++ )); do
    alc-verb -d "$dev" "$node" SET_COEF_INDEX "$i" >/dev/null 2>&1
    value=$(alc-verb -d "$dev" "$node" GET_PROC_COEF 0 2>/dev/null | tail -n 1)
    printf " Coeff 0x%02x: 0x%04x\n" "$i" "$value"
  done
} > "$out"

echo "Saved $out"
