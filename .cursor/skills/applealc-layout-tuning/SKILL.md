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

## 间歇有声 / Windows 切过来才异常

- 加 `alctcsel=1`（DeviceProperties data + boot-args）
- 加 `alcdelay=1000`（可试到 `2000`）；DeviceProperties 用 `alc-delay`
- 跨 Windows→macOS 优先 **冷启动**，避免热重启残留 Realtek 状态
- 可选 `No-hda-gfx`，避免绑到 GPU HDMI 音频

## UEFI.Audio（易误判）

仅当同时满足才有意义：

- `AudioSupport` = `true`
- `AudioDevice` = **HDA 控制器**路径（本机 `1f.3`），不是 Root Port（如曾误写的 `1b.0`）

`AudioSupport=false` 时，ResetTrafficClass / SetupDelay 等开关全部无效。

## 反模式

- 只改 UEFI 音频 quirks 却不开 `AudioSupport`
- `AudioDevice` 写成 Root Port
- `alcid` 与 `layout-id` 不一致
- 测音频时插错孔或选 HDMI 输出
