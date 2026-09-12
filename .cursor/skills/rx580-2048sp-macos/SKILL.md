---
name: rx580-2048sp-macos
description: >-
  Diagnoses macOS GPU issues for AMD RX 580 2048SP (device-id 0x6FDF):
  OpenCore DeviceProperties spoof, SMBIOS/AGPM, and VBIOS flash including
  SSID-patched TechPowerUp #212488 crossflash and pp1310 clock restore.
  Use when VRAM is ~5MB, Metal missing, UI stutter after spoof, black screen
  after flashing, 0FL01 SSID mismatch, 1244 vs 1310 MHz, or the user mentions
  2048SP / 6FDF / 212488 / amdvbflash / v20 / v30.
---

# RX 580 2048SP → macOS

本仓库机：PowerColor / 迪兰同板 `113-D000340_2048`，Device `1002:6FDF`，SSID `148C:2392`，Hynix `H5GQ8H24MJR` 8GB，原版 MD5 `8e88fa633cc6843d7e168c45b7878bae`。

## 诊断树

1. 系统报告 Device ID 仍为 `6FDF`？→ 未伪装，或 DeviceProperties 路径错误
2. 已是 `67FF`/`67DF` 但仅能出图、动画卡？→ 软伪装不完整（常见）；社区共识下一步是刷 VBIOS
3. Metal 无 / 显存约 5MB？→ spoof 未生效，或路径 / WhateverGreen 问题
4. `amdvbflash` 报 `0FL01` / `SSID mismatched`？→ EXTERNAL 无 `-f`，须改 ROM 的 SSID 与卡一致后再刷
5. GPU-Z 默认钟 1244？→ **正常（日常 v20）**；勿为追 1310 再刷完整 v30
6. 曾刷 v30 后 AMD 掉驱动 / GPU-Z 钟 0 MHz？→ 回退 v20（已验证恢复）
7. 刷后独显黑屏但远程桌面还能进？→ ROM/GOP 问题；核显救援 + `restore_v00_stock.bat`（须交互窗口）

## 软伪装（OpenCore）

- PCI 路径必须来自 SysReport（本机：`PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)`）
- **推荐** `device-id` → `67FF`（RX 570）；不要仅为显示名改回 `67DF`
- plist `device-id` 为 **小端 data**（`67FF` → base64 `/2cAAA==`）
- 改完：覆盖 ESP → **Reset NVRAM**
- **上限：** 软伪装常只能出分辨率；Dock/调度中心动画仍卡、Metal 不完整 → 必须硬刷，不是再改显示名
- **本机现状（v20）：** 卡上 `67DF` + SSID `2392`（#212488）；曾试 v30 后回退。EFI **已去掉** GPU DeviceProperties；勿再加回伪装除非还原了 v00

## SMBIOS / AGPM

- Polaris：优先与 CPU 匹配的 iMac（Kaby Lake → `iMac18,3`）
- 避免 `iMacPro1,1`（Vega AGPM 表 → UI stutter）

## WhateverGreen

- Polaris **不要** `agdpmod=pikera`
- 可选 `-radcodec`（伪装 ID 下补 VA；对 Dock 动画未必明显）
- YouTube 卡顿：常叠加 VP9/AV1 **无硬解**（CPU 软解），不完全是 GPU「性能不够」
- 连接优先 DisplayPort；HDMI 1440p 上勿用 ForceResolution 修 Picker（见 `hackintosh-z170x-gaming5`）

## VBIOS ROM 版本（`tools/vbios/roms/`）

| 文件 | MD5 | 角色 |
|---|---|---|
| `v00_stock_6FDF_ssid2392.rom` | `8e88fa633cc6843d7e168c45b7878bae` | 本机原版 / 救援 |
| `v10_tpu212488_upstream.rom` | `58569ccbdd5e896666225aa7026931ac` | TPU 原件（不可直刷） |
| `v20_tpu212488_ssid2392.rom` | `f97ab3dd3ffddee6151a66c3c11ccc3b` | **已验证亮机**（≈1244 MHz） |
| `v30_tpu212488_ssid2392_pp1310.rom` | `b669d2a6a74b095d73e15def6aad2597` | v20 + 原版 SCLK/TDP → 1310/145；**本机间歇掉驱动，已弃用日常** |

命名：`vNN_<来源>[_改动]`；数字越大叠改越多。

### 上游来源（v10）

- **URL：** https://www.techpowerup.com/vgabios/212488/212488  
- TechPowerUp #212488，页面标 RX570，PCI Device 实为 `67DF`  
- 颗粒表含 `H5GQ8H24MJR` + `MT51J256M32HFB`，同族 `D00034 Polaris20 XL A1` 8GB  
- TPU 公布 MD5 必须等于 `58569ccbdd5e896666225aa7026931ac`

## VBIOS：已验证成功路径

**障碍：** 原版 SSID `2392`，#212488 为 `2379`。classic **AMDVBFLASH 3.31 EXTERNAL** 不支持 `-f` → 直刷 `0FL01`。

**做法（2026-09-11/12：v20 写入成功 + HDMI 亮机）：**

1. 以 v10 为源：唯一一处 `148C:2379` → `148C:2392`（约 offset `586`）
2. `python tools/fix_vbios_checksum.py` → 得到 v20
3. 管理员运行 `tools/vbios/flash_v20_ssid2392.bat`，输入 `YES`
4. `-i` 必须 `3.31 EXTERNAL`；日志含 `programmed` + `verified`，`6FDF→67DF`
5. dump-after 与 v20 **0 字节差**
6. **关机 → 断电约 10 秒 → 再开**
7. GPU-Z：Device `67DF`，P/N 含 `113-D0003400_100`，默认钟 ≈1244

### 性能：v30 试过 → 弃用；日常用 v20（2026-09-12）

GPU-Z：v00 默认钟 **1310**，v20 **1244（≈-5%）**。填充率由核频推算：`Pixel=MHz×32/1000`，`Texture=MHz×128/1000`。

v30 = v20 + 拷贝 v00 的 SCLK P0–P7 与 PowerTune（TDP 145 等）；刷写 `programmed`+`verified`，dump MD5 一致。相对 v20 仅约 20 字节差——**不是漏改，是改太猛**。

### v30 间歇掉驱动 → 回退 v20 已恢复

**现象：** 刷 v30 后首启正常；再重启数次 → AMD「无法加载显示驱动程序」；GPU-Z 钟 **0 MHz**、仅 OpenGL 1.1；Default Clock 仍 **1310**。

**含义：** ROM 仍在（能读到 1310），是 **驱动初始化失败**，不是没刷上。外板 #212488 电压/供电标定 + 原版整条 SCLK/TDP145 不匹配。

**GPU-Z 显示 `148C:2379`：** 驱动挂时可能按 P/N 套 TPU 库；以 `dump_current.bat` MD5 为准（v20=`f97ab3dd…`，SSID 字节 `2392`）。

**已验证修复：** `flash_v20_ssid2392.bat` → 关机断电约 10 秒 → **驱动恢复正常**。本机日常停留 v20；勿再刷完整 v30。若再试性能：只改 P7、或 Windows 软超；不要整表拷 SCLK+TDP145。

工具：只用 `AMDVBFlash-classic-3.31/`（真 3.31 EXTERNAL）。

### 失败 / 高风险对照（勿重蹈）

| 操作 | 结果 |
|---|---|
| 未改 SSID 直刷 v10 | `0FL01`，未写入 |
| 本机 dump 改 ASIC→570（`F0 7D E6 0F`）+ ID | 写入成功，HDMI **黑屏**；已还原 |
| 本机 dump 仅改 PCIR `6FDF→67FF` | 写入成功；亮屏情况以当时断电验证为准 |
| TPU #208046 | 与原版哈希相同，刷了无收益 |
| TPU #207832 / #238313 | SSID=`2392` 但 **无 Hynix straps** → 高黑屏风险；且仍是 `6FDF` |
| v30（整表 SCLK + TDP145） | 刷入成功；首启正常，数次重启后 Windows 掉驱动；**回退 v20 恢复** |

远景等：ASIC 改成 570 易掉 GOP；成功路径是 **整份换 #212488 + 只改 SSID（v20）**，性能用 **v30 改 PowerPlay**，不要用原版改 ASIC。

### 功耗说明

- 功率/频率表在 PowerPlay，不在 Device ID。  
- 「叫 570」本身不掉钟；v20 掉钟是因为换了 #212488 的表。  
- 硅仍是 2048SP，CU 不靠改 ID 解锁。

### 选 ROM 清单（EXTERNAL）

1. 颗粒字符串含本机型号（`H5GQ8H24MJR`）
2. 8GB；频率不明显高于原卡
3. Device 目标为 `67DF` 或 `67FF`（#212488 为 `67DF`）
4. SSID ≠ 卡上时：先补丁 SSID 再刷，**不要**指望 EXTERNAL 的 `-f`
5. 避开仍为 `6FDF` 的「2048SP 原版同款」、以及无本机颗粒表的 ROM

### 还原

- `tools/vbios/restore_v00_stock.bat` → `v00_stock_6FDF_ssid2392.rom`
- 须管理员交互窗口；`.bat` 必须 **CRLF + ASCII**
- 无显示：清 CMOS → 主板 HDMI → 开 iGPU → 再还原
- 还原后 GPU-Z 应为 `6FDF`

## 验证

- Windows GPU-Z：Device `67DF`；VRAM 8GB；v30 时 Default Clock 1310
- macOS：关于本机 / 系统报告 Metal
- 可选 Geekbench Metal
