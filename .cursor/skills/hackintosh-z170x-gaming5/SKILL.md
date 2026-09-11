---
name: hackintosh-z170x-gaming5
description: >-
  Guides OpenCore EFI work for this GIGABYTE Z170X-GAMING 5 + i7-7700K +
  RX 580 2048SP Ventura hackintosh. Use when editing this repo's EFI,
  config.plist, OpCore-Simplify outputs, ESP deploy, or board-specific
  boot/audio/GPU/picker issues.
---

# Z170X-GAMING 5 黑苹果工作流

## 何时使用

- 改本仓库 OpenCore EFI / `config.plist`
- 对照 SysReport 审核配置
- 部署到 U 盘 / ESP，或解释本机已知行为

## 技能地图（本仓库）

| 技能 | 管什么 |
|------|--------|
| `hackintosh-z170x-gaming5`（本文件 + `reference.md`） | 主板 EFI、路径、部署、Picker/GOP、审核清单 |
| `rx580-2048sp-macos` | 2048SP 软伪装 / VBIOS v00–v30 / 黑屏救援 |
| `applealc-layout-tuning` | ALC1150 layout、间歇无声 |
| `dualboot-rtc-utc` | 双系统时间（只改 Windows） |

跨项目副本在 `~/.cursor/skills/`（除本机板级技能外）。

## 权威路径

| 用途 | 路径 |
|------|------|
| EFI 根 | `OpenCore EFI/EFI-GIGABYTE Z170X-GAMING 5/EFI` |
| 配置 | `.../EFI/OC/config.plist` |
| 硬件报告 | `OpCore-Simplify-main/SysReport/Report.json` |
| VBIOS | `tools/vbios/`（见 `rx580-2048sp-macos`） |

硬件表、期望配置、审核清单见 [reference.md](reference.md)。

## 工作原则

1. 先读 `Report.json` 的 PCI Path，再改 DeviceProperties（禁止猜路径）
2. 改 NVRAM / boot-args / layout / device-id 后：覆盖 ESP → OpenCore **Reset NVRAM** → 再验证
3. 显卡问题加载 `rx580-2048sp-macos`
4. 音频 layout / 间歇无声加载 `applealc-layout-tuning`
5. 双系统时间偏移加载 `dualboot-rtc-utc`（不改 EFI）

## 本机已知正确基线（2026-09）

- SMBIOS：`iMac18,3`
- GPU：已硬刷 v30（TPU #212488 + SSID`2392` + 原版 PowerPlay）→ Device **`0x67DF`**。**无** GPU DeviceProperties 软伪装（刷成功后已去掉）
- Audio：`alcid=5` + `layout-id=5` + `alctcsel=1` + `alcdelay=1000` @ `PciRoot(0x0)/Pci(0x1f,0x3)`
- Output：`Resolution=Max`，`ForceResolution=false`，`UIScale=0`
- `Misc → Boot → Timeout`：`10`
- SSDT：EC / PLUG / SBUS / USBX

## Picker / GOP（本机踩坑）

- Picker 文案「Ventura」= **卷标**，不是 SMBIOS；`diskutil rename` 即可
- **禁止**本机组合：`Resolution=2560x1440` + `ForceResolution=true` + `UIScale=1`（+ NVRAM `UIScale`）→ HDMI/Polaris GOP 易黑屏、反复进不了系统
- 可启动基线：`Resolution=Max`，`ForceResolution=false`，`UIScale=0`，并删掉 NVRAM 里的 `UIScale`
- Picker 图标过大可先试 DisplayPort；勿再强推 ForceResolution 修 UI

## 启动日志

- 排障：boot-args 临时加 `-v`；需要更全日志时可开 `Misc → Debug → AppleDebug` / `Target`
- 稳定后可去掉 `-v`；本机曾因分辨率改坏启动，用 `-v` 确认卡点

## 视频卡顿（软伪装时代遗留）

- 可选 `-radcodec`（WhateverGreen）：改善伪装 ID 下 VA 路径
- YouTube 高码率 VP9/AV1 在 Polaris 上常无硬解 → CPU 软解；不是「RX580 不够」单因
- 硬刷后 Metal 完整仍可能软解 VP9/AV1

## 本机已知未完成 / 易误判

- `UEFI → Audio → AudioSupport` 仍为 `false` 时，UEFI 音频 quirks 全部无效（`AudioDevice` 已是 `1f.3`）
- WiFi BCM4360（`14E4-43A0`）在 Ventura 上可能需 AirportBrcmFixup（+ OCLP）
- `UTBDefault.kext` = 无真实 USB map
- 公开 git：勿提交超大 `.exe` / Results 缓存；注意 SMBIOS 序列号隐私

## 标准部署检查清单

- [ ] 只同步已验证的 EFI 树
- [ ] Reset NVRAM
- [ ] 关于本机 / 系统报告：VRAM≈8GB、GPU=`67DF`、Metal
- [ ] 声音：后置绿孔 + 「内建」输出（非 HDMI）
- [ ] 启动菜单 Timeout / 卷标符合预期；能进系统（非 ForceResolution 黑屏）
