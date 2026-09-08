---
name: rx580-2048sp-macos
description: >-
  Diagnoses macOS GPU issues for AMD RX 580 2048SP (device-id 0x6FDF):
  OpenCore DeviceProperties spoof, SMBIOS/AGPM choices, soft-spoof limits,
  and VBIOS patching. Use when VRAM is ~5MB, Metal missing, UI animations
  stutter after spoof, or the user mentions 2048SP / 6FDF.
---

# RX 580 2048SP → macOS

## 诊断树

1. 系统报告 Device ID 仍为 `6FDF`？→ 未伪装，或 DeviceProperties 路径错误
2. 已是 `67FF`/`67DF` 但仅能出图、动画卡？→ 软伪装不完整（常见）
3. Metal 无 / 显存约 5MB？→ spoof 未生效，或路径 / WhateverGreen 问题

## 软伪装（OpenCore）

- PCI 路径必须来自 SysReport（本仓库机：`PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)`）
- **推荐** `device-id` → `67FF`（RX 570）；不要仅为显示名改回 `67DF`（满血 580）
- `model` 字符串可选；`IOName` 非必须（曾加后清理）
- plist `device-id` 为 **小端 data**（`67FF` → base64 `/2cAAA==`）
- 改完：覆盖 ESP → **Reset NVRAM**

## SMBIOS / AGPM

- Polaris：优先与 CPU 匹配的 iMac（Kaby Lake → `iMac18,3`）
- 避免 `iMacPro1,1`（Vega AGPM 表 → UI stutter）

## WhateverGreen

- Polaris **不要** `agdpmod=pikera`（Navi 专用）
- 可选 `-radcodec`（伪装 ID 下视频加速）
- 连接优先 DisplayPort；HDMI 可用但偶发不如 DP 稳

## VBIOS 根治（软伪装到头后）

本仓库脚本：`tools/patch_rx580_2048sp_vbios.py`

1. GPU-Z 导出原始 `.rom`（务必备份）
2. `python tools/patch_rx580_2048sp_vbios.py original.rom`（默认改向 RX 570）
3. PolarisBiosEditor 打开 patched ROM 再保存一次（修校验）
4. `amdvbflash` 刷入 → 重启
5. 成功后可去掉 OpenCore GPU DeviceProperties 伪装

风险：刷错可能变砖（双 BIOS / 主板 PCI-E 救援通常可恢复）。脚本会改 Device ID + ASIC 标记。

## 验证

- 关于本机 / 系统报告：VRAM ≈ 8GB；Device ID；Metal Supported
- 可选：Geekbench Metal 对照同档 RX 570/580
