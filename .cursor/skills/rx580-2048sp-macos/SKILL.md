---
name: rx580-2048sp-macos
description: >-
  Diagnoses macOS GPU issues for AMD RX 580 2048SP (device-id 0x6FDF):
  OpenCore DeviceProperties spoof, SMBIOS/AGPM choices, soft-spoof limits,
  and VBIOS patching/restore. Use when VRAM is ~5MB, Metal missing, UI
  animations stutter after spoof, black screen after flashing VBIOS, or
  the user mentions 2048SP / 6FDF / amdvbflash.
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

本仓库：`tools/patch_rx580_2048sp_vbios.py`、`tools/vbios/`

**先只改原版 ROM 的机器码（PCI Device ID），不要换别人的 RX570 ROM，也不要先改 ASIC。**

本机（PowerColor `113-D000340_2048`，Hynix 8GB）已验证：

| 刷入文件 | 实际改动 | 结果 |
|---|---|---|
| `RX580_rx570_patched_fixed.rom` | `6FDF→67FF` **且** `0xD4` ASIC `F0 FD E6 0F→F0 7D E6 0F` | 写入校验成功，Windows 可 RDP，独显 HDMI **黑屏**；已还原 |
| `RX580_idonly_67ff_fixed.rom` | 仅两处 PCIR `6FDF→67FF`，ASIC 仍为 `F0 FD E6 0F` | 2026-09-09 再次刷入成功：`programmed+verified`，dump-after 与目标 ROM 0 字节差。须关机断电后看 HDMI |

黑屏原因不是 `amdvbflash` 没写进去（dump 与 patched 0 字节差）。远景/Overclock.net：把 ASIC 改成 **570**（`F0 7D E6 0F`）会掉 GOP 签名；改成 **580**（`F0 7D E6 07`）通常不掉。只改 Device ID 时 GOP 二进制未动，Windows 仍能加载（故能远程），但 GOP/出图失败就会 HDMI 不亮。

1. 只用卡上备份的原版 `.rom`
2. `python tools/patch_rx580_2048sp_vbios.py original.rom --target 580 --id-only`
3. `python tools/fix_vbios_checksum.py <output>`（或 PBE 打开再 Save）
4. 只用 **AMDVBFLASH 3.31 EXTERNAL**。名为 3.31 实为 5.0.x 的包会“刷成功”但芯片未改
5. 刷 RX570：`flash_idonly_67ff.bat`（`6FDF→67FF`，不动 ASIC）。`-i` 第一行必须是 `3.31 EXTERNAL`。成功后**关机断电约 10 秒**
6. 若仍黑屏：再考虑 GOP 1.69 签名补丁，或 ASIC 改 `F0 7D E6 07`（580 而非 570）。不要刷其他品牌/其他颗粒的整份 RX570 VBIOS
7. 成功后可去掉 OpenCore GPU DeviceProperties 伪装

### 刷完黑屏 / 还原

- 原版：`RX580-原版.rom`（与 `tools/vbios/roms/RX580-original.rom`、刷前 dump 字节相同，仍为 `6FDF`）
- Windows 若能远程桌面：在**远程会话里**管理员运行 `tools/vbios/restore_original.bat`（Agent 后台跑 `amdvbflash` 会报需要交互式窗口）
- `.bat` 必须 **CRLF + ASCII**；LF 或 UTF-8 中文会导致 `'cho'` / `'ause'` / 命令被拆碎
- 本机 BIOS 多半关核显；无远程时：清 CMOS → 显示器插主板 HDMI → 开 iGPU/IGFX → 再还原
- 还原后 GPU-Z 应为 `6FDF`，OpenCore 需重新加上 `67FF` 软伪装

风险：刷错可能变砖；双 BIOS 拨杆 / 核显 / 远程桌面通常可救。

## 验证

- 关于本机 / 系统报告：VRAM ≈ 8GB；Device ID；Metal Supported
- 可选：Geekbench Metal 对照同档 RX 570/580
