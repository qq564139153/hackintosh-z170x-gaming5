---
name: applealc-layout-tuning
description: >-
  Tunes AppleALC layout-id and related boot-args for Realtek codecs when
  macOS has no sound or intermittent audio after reboot/Windows. Use for
  rear-jack silence (Windows OK), flaky built-in audio, alcid/layout-id,
  or ALC1150 issues.
---

# AppleALC Layout 与间歇音频

## 前置

- 确认 codec（本仓库机：ALC1150 = `10EC-0900`）与 HDA 控制器 PCI 路径（本机：`PciRoot(0x0)/Pci(0x1f,0x3)`）
- 插正确物理孔：后置 **绿色 Line Out**，不是 5.1 Rear Speaker
- 输出设备选「内建」，不要选显示器 HDMI

## Layout 试错

1. `boot-args` 的 `alcid=N` 与 DeviceProperties `layout-id` **必须一致**
2. 每次只改一个 layout；覆盖 ESP → **Reset NVRAM** → 测绿孔
3. ALC1150 建议顺序：`1` → `7` → `5` → `2` / `3` / `99`
4. 本机已验证可用：`5`

## 间歇有声 / Windows 热重启 → macOS 无声

现象：Windows **重启**进 macOS 无声；**关机再开机**进 macOS 正常 → Codec/HDA 残留，不是缺 kext。

本机（Z170X + ALC1150）已验证基线：`alcid=5` + `layout-id=5` + `alctcsel=1` + `alcdelay=1000` + `No-hda-gfx`。

OpenCore 侧（Clover `ResetHDA` 的对应物，**没有** `UEFI→Quirks→ResetHDA` 这个键）：

1. 确认已有：`alctcsel=1` + `alc-delay`/`alcdelay` + 正确 `alcid`（Dortania 官方热重启修复）
2. **本机实测无效（2026-09）**：仅开 `AudioSupport` + `DisconnectHda` + `ResetTrafficClass` + `SetupDelay=1500` **未能**修复 Windows 热重启无声 → 已还原；勿再当作本机首选
3. Windows 侧优先：关快速启动；管理员 `powercfg -h off`；声卡电源管理取消「允许计算机关闭此设备」
4. 仍不行：冷启动对比确认；勿乱改已验证的 `alcid=5`；深层可走 AppleALC coef dump（wiki Dumping processing coefficients）

## UEFI.Audio（易误判）

仅当同时满足才有意义：

- `AudioSupport` = `true`
- `AudioDevice` = **HDA 控制器**路径（本机 `1f.3`），不是 Root Port（如曾误写的 `1b.0`）

`AudioSupport=false` 时，ResetTrafficClass / DisconnectHda / SetupDelay 全部无效。

勿信「OpenCore UEFI Quirks 里开 ResetHDA」——现代 sample 无此键。本机 OS_13 基线仍为 `AudioSupport=false`（热重启方案未验证成功）。

## 反模式

- 只改 UEFI 音频 quirks 却不开 `AudioSupport`
- 把 Clover `ResetHDA` 当成 OC Quirks 键硬加
- 已验证 layout=5 却因热重启无声去乱试 alcid=1
- 本机再推 `DisconnectHda` 当「必杀」（已测无效）
- `AudioDevice` 写成 Root Port
- `alcid` 与 `layout-id` 不一致
- 测音频时插错孔或选 HDMI 输出
