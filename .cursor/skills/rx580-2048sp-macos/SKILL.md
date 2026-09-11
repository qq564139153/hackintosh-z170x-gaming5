---
name: rx580-2048sp-macos
description: >-
  Diagnoses macOS GPU issues for AMD RX 580 2048SP (device-id 0x6FDF):
  OpenCore DeviceProperties spoof, SMBIOS/AGPM, and VBIOS flash including
  SSID-patched TechPowerUp #212488 crossflash. Use when VRAM is ~5MB, Metal
  missing, UI stutter after spoof, black screen after flashing, 0FL01 SSID
  mismatch, or the user mentions 2048SP / 6FDF / 212488 / amdvbflash.
---

# RX 580 2048SP → macOS

本仓库机：PowerColor / 迪兰同板 `113-D000340_2048`，Device `1002:6FDF`，SSID `148C:2392`，Hynix `H5GQ8H24MJR` 8GB，原版 MD5 `8e88fa633cc6843d7e168c45b7878bae`。

## 诊断树

1. 系统报告 Device ID 仍为 `6FDF`？→ 未伪装，或 DeviceProperties 路径错误
2. 已是 `67FF`/`67DF` 但仅能出图、动画卡？→ 软伪装不完整（常见）
3. Metal 无 / 显存约 5MB？→ spoof 未生效，或路径 / WhateverGreen 问题
4. `amdvbflash` 报 `0FL01` / `SSID mismatched`？→ EXTERNAL 无 `-f`，须改 ROM 的 SSID 与卡一致后再刷

## 软伪装（OpenCore）

- PCI 路径必须来自 SysReport（本机：`PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)`）
- **推荐** `device-id` → `67FF`（RX 570）；不要仅为显示名改回 `67DF`
- plist `device-id` 为 **小端 data**（`67FF` → base64 `/2cAAA==`）
- 改完：覆盖 ESP → **Reset NVRAM**
- VBIOS 已硬改成 `67DF` 后，可去掉 GPU DeviceProperties 伪装再测

## SMBIOS / AGPM

- Polaris：优先与 CPU 匹配的 iMac（Kaby Lake → `iMac18,3`）
- 避免 `iMacPro1,1`（Vega AGPM 表 → UI stutter）

## WhateverGreen

- Polaris **不要** `agdpmod=pikera`
- 可选 `-radcodec`
- 连接优先 DisplayPort

## VBIOS：本机已验证成功路径（推荐硬刷）

**目标 ROM：** TechPowerUp [#212488](https://www.techpowerup.com/vgabios/212488/212488)（页面标 RX570，PCI Device 实为 `67DF`），颗粒表含 `H5GQ8H24MJR` + `MT51J256M32HFB`，与原版同族 `D00034 Polaris20 XL A1` 8GB。

**障碍：** 原版 SSID `2392`，#212488 为 `2379`。classic **AMDVBFLASH 3.31 EXTERNAL** 不支持 `-f` → 直接刷报 `SSID mismatched` / `0FL01`，芯片不变。

**做法（2026-09-11/12 本机验证：写入成功 + HDMI 亮机正常）：**

1. 保留原版：`tools/vbios/roms/RX580-original.rom`（务必备份）
2. 将 #212488 中唯一一处 `148C:2379`（约 offset `586`）改为 `148C:2392`
3. `python tools/fix_vbios_checksum.py …` → 得到 `roms/RX570-212488_ssid2392_fixed.rom`（MD5 `f97ab3dd3ffddee6151a66c3c11ccc3b`）
4. 管理员运行 `tools/vbios/flash_rx570_212488_ssid2392.bat`，输入 `YES`
5. `-i` 必须显示 `3.31 EXTERNAL`；成功日志含：
   - `Old/New SSID: 2392`
   - `DeviceID 6FDF → 67DF`
   - `P/N …_2048 → …_100`
   - `40000/40000h bytes programmed` + `verified`
6. dump-after 应与目标 ROM **0 字节差**
7. **关机 → 断电约 10 秒 → 再开**（不要只重启）
8. GPU-Z：Device `67DF`，P/N 含 `113-D0003400_100`

控制台若出现 `Flash already programmed`：多为 bat 对 `amdvbflash` 的第二次调用（芯片已与目标一致），以日志 programmed/verified 与 dump 哈希为准。

工具目录：只用 `AMDVBFlash-classic-3.31/`（真 3.31 EXTERNAL）。名为 3.31 实为 5.0.x 的包勿用。

### 失败 / 高风险对照（勿重蹈）

| 操作 | 结果 |
|---|---|
| 未改 SSID 直刷 `RX570-212488.rom` | `0FL01`，dump 前后 checksum 同为 `0xB600`，未写入 |
| 本机 dump 改 ASIC→570（`F0 7D E6 0F`）+ ID | 写入成功，HDMI **黑屏**；已还原 |
| 本机 dump 仅改 PCIR `6FDF→67FF` | 写入成功；亮屏情况以当时断电验证为准 |
| TPU #208046 | 与原版哈希相同，刷了无收益 |
| TPU #207832 / #238313 | SSID=`2392` 但 **无 Hynix straps** → 对本机高黑屏风险；且仍是 `6FDF` |

远景等：ASIC 改成 570 易掉 GOP；本机成功路径是 **整份换 #212488 表 + 只改 SSID**，未单独改 ASIC 字节。

### 选 ROM 清单（EXTERNAL）

1. 颗粒字符串含本机型号（`H5GQ8H24MJR`）
2. 8GB；频率不明显高于原卡
3. Device 目标为 `67DF` 或 `67FF`（#212488 为 `67DF`）
4. SSID ≠ 卡上时：先补丁 SSID 再刷，**不要**指望 EXTERNAL 的 `-f`
5. 避开仍为 `6FDF` 的「2048SP 原版同款」、以及无本机颗粒表的 ROM

### 网上教程可学点

- zzmac / 蓝宝石帖：整刷靠颗粒匹配 + 常带 `-f`；同品牌也可能黑，需试错
- 成功帖颗粒多为 `H5GC8H24AJR_PARTNER_SAPPHIRE`，**≠** 本机 `H5GQ8H24MJR`
- 本机 EXTERNAL 无 `-f` → 用 **SSID 补丁** 等价于过门禁，而不是换内部版强刷工具

### 还原

- 脚本：`tools/vbios/restore_original.bat` → `roms/RX580-original.rom`
- 须管理员交互窗口；Agent 后台跑常失败
- `.bat` 必须 **CRLF + ASCII**
- 无显示：清 CMOS → 主板 HDMI → 开 iGPU → 再还原
- 还原后 GPU-Z 应为 `6FDF`；macOS 需再加软伪装（若尚未硬刷成功）

## 验证

- Windows GPU-Z：Device `67DF`；VRAM 8GB；输出正常
- macOS：关于本机 / 系统报告 Metal；可去掉硬伪装后的 DeviceProperties 再确认
- 可选 Geekbench Metal
