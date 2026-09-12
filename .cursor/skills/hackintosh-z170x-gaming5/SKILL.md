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
  - Windows 热重启无声：`AudioSupport`+`DisconnectHda` 本机实测无效已还原；优先 Windows 关快速启动 / `powercfg -h off`
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

- Windows→macOS 热重启无声：`AudioSupport`+`DisconnectHda` 本机无效；见 `applealc-layout-tuning`（先 Windows 快速启动，勿再推该 EFI 组合）
- WiFi BCM4360（`14E4-43A0`）在 Ventura 上可能需 AirportBrcmFixup（+ OCLP）
- `UTBDefault.kext` = 无真实 USB map
- 公开 git：勿提交超大 `.exe` / Results 缓存；注意 SMBIOS 序列号隐私

## OS_13 → OS_26（OpCore Simplify）对照

路径：`OS_13/EFI`（已验证）vs `OS_26/EFI-GIGABYTE Z170X-GAMING 5/EFI`（生成后需补本机改动）。

### 「需要 OpenCore Legacy Patcher」含义

- 本机 **Kaby Lake + BCM4360** 在 Sonoma/Sequoia/**Tahoe** 已不在 Apple 原生支持范围
- OpCore 提示：进系统后还要用 **OCLP 做 root patch**（常见：旧无线、部分音频/驱动签名）
- **不是**「只靠 OCLP 就能装」；仍要先有可启动 EFI + 安装介质
- **风险（2026-09）：** 官方 OCLP 对 Tahoe 仍不稳定/未完整；RX 580 Polaris 在 Tahoe 上可能卡在图形安装界面。优先保证 Ventura 可回退

### Simplify 生成的 OS26 会多出什么（应保留）

| 项 | 作用 |
|----|------|
| `AMFIPass` + `amfi=0x80` | 放宽 AMFI，配合 root patch |
| `RestrictEvents` + NVRAM `revpatch=sbvmm` | 更新/机型相关 |
| `IOSkywalkFamily` + `IO80211FamilyLegacy` + Block 系统 IOSkywalk | Sonoma+ 旧 Broadcom Wi‑Fi |
| `apfs_aligned.efi` + `APFS.EnableJumpstart=false` | Tahoe APFS 对齐 |
| SMBIOS `MacPro7,1` | dGPU-only / 新系统常见选择（勿盲目改回 `iMac18,3` 除非验证可装） |

### 必须从 OS13 迁到 OS26 的本机改动

1. **补 kext：** `AppleALC`、`WhateverGreen`（Simplify 的 OS26 包常缺）
2. **DeviceProperties：** HDA `1f.3` 的 `layout-id=5` / `alc-delay` / `alctcsel` / `No-hda-gfx`；可选 iGPU headless `2.0`
3. **boot-args 合并：** 保留 OS26 的 `-v debug=0x100 amfi=0x80`，加上 OS13 的 `npci=0x3000 alcid=5 alctcsel=1 alcdelay=1000`
4. **UEFI.Audio：** `AudioDevice` 必须是 `PciRoot(0x0)/Pci(0x1f,0x3)`（Simplify 常错写成 `1b.0`）；`ResetTrafficClass`/`SetupDelay` 对齐 OS13
5. **Output：** 保持 `Resolution=Max` / `ForceResolution=false` / `UIScale=0`（勿搬 ForceResolution 坑）
6. **Timeout：** 可改 `10`（本机习惯）
7. **勿加** GPU DeviceProperties（本机已硬刷 `67DF`）
8. **勿删** OS26 的 AMFI / Skywalk / RestrictEvents / `apfs_aligned`

### 安装顺序建议

1. 改好的 OS26 EFI 写到独立 U 盘 ESP（保留 OS13 EFI / 系统盘不动）
2. Reset NVRAM → 试启动安装器
3. 装完进桌面后再考虑 OCLP root patch（Wi‑Fi / AppleHDA 等）
4. 失败则仍用 OS13 EFI 回 Ventura

## 标准部署检查清单

- [ ] 只同步已验证的 EFI 树
- [ ] Reset NVRAM
- [ ] 关于本机 / 系统报告：VRAM≈8GB、GPU=`67DF`、Metal
- [ ] 声音：后置绿孔 + 「内建」输出（非 HDMI）
- [ ] 启动菜单 Timeout / 卷标符合预期；能进系统（非 ForceResolution 黑屏）
