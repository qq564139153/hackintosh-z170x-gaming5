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

## 权威路径

| 用途 | 路径 |
|------|------|
| EFI 根 | `OpenCore EFI/EFI-GIGABYTE Z170X-GAMING 5/EFI` |
| 配置 | `.../EFI/OC/config.plist` |
| 硬件报告 | `OpCore-Simplify-main/SysReport/Report.json` |
| VBIOS 工具 | `tools/patch_rx580_2048sp_vbios.py` |

硬件表、期望配置、审核清单见 [reference.md](reference.md)。

## 工作原则

1. 先读 `Report.json` 的 PCI Path，再改 DeviceProperties（禁止猜路径）
2. 改 NVRAM / boot-args / layout / device-id 后：覆盖 ESP → OpenCore **Reset NVRAM** → 再验证
3. 显卡问题加载 `rx580-2048sp-macos`
4. 音频 layout / 间歇无声加载 `applealc-layout-tuning`
5. 双系统时间偏移加载 `dualboot-rtc-utc`（不改 EFI）

## 本机已知正确基线

- SMBIOS：`iMac18,3`
- GPU：`0x6FDF` → DeviceProperties `device-id` `0x67FF`（RX 570）@ `PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)`
- Audio：`alcid=5` + `layout-id=5` + `alctcsel=1` + `alcdelay=1000` @ `PciRoot(0x0)/Pci(0x1f,0x3)`
- boot-args 含 `-radcodec`（伪装 ID 视频加速）
- Picker：`Resolution=2560x1440` + `ForceResolution` + `UIScale=1`（及 NVRAM `UIScale=01`）
- `Misc → Boot → Timeout`：`10`
- SSDT：EC / PLUG / SBUS / USBX

## 本机已知未完成 / 易误判

- `UEFI → Audio → AudioSupport` 仍为 `false` 时，UEFI 音频 quirks 全部无效（`AudioDevice` 已是 `1f.3`）
- WiFi BCM4360（`14E4-43A0`）在 Ventura 上可能需 AirportBrcmFixup（+ OCLP）
- `UTBDefault.kext` = 无真实 USB map
- Picker 显示「Ventura」= **卷标**，不是 SMBIOS / 识别失败；用 `diskutil rename` 改名即可
- 公开 git：勿提交超大 `.exe` / Results 缓存；注意 SMBIOS 序列号隐私

## 标准部署检查清单

- [ ] 只同步已验证的 EFI 树
- [ ] Reset NVRAM
- [ ] 关于本机 / 系统报告：VRAM≈8GB、GPU 设备 ID、Metal
- [ ] 声音：后置绿孔 + 「内建」输出（非 HDMI）
- [ ] 启动菜单 Timeout / 卷标符合预期

## 相关技能

- `rx580-2048sp-macos`
- `applealc-layout-tuning`
- `dualboot-rtc-utc`
