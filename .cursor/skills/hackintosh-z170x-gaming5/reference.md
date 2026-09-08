# reference — 本机硬件与配置快照

权威来源：`OpCore-Simplify-main/SysReport/Report.json` + 当前 `config.plist`。

## 硬件表

| 项 | 值 |
|----|-----|
| 主板 | GIGABYTE Z170X-GAMING 5（Z170，BIOS F22f） |
| CPU | i7-7700K（Kaby Lake） |
| GPU | RX 580 2048SP，`1002-6FDF`，PCI `PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)`，ACPI `\_SB.PCI0.PEG0.PEGP` |
| 显示器 | HDMI 2560×1440（走独显） |
| 声卡 | Realtek ALC1150 `10EC-0900`，控制器 `8086-A170`，路径 `PciRoot(0x0)/Pci(0x1f,0x3)`（HDAS） |
| 有线网 | I219-V `8086-15B8` + Killer E2400 `1969-E0A1` |
| WiFi | Broadcom BCM4360 `14E4-43A0` @ `PciRoot(0x0)/Pci(0x1c,0x6)/Pci(0x0,0x0)` |
| 报告无核显条目 | 多半 BIOS 已关 iGPU |

## DeviceProperties 期望值

### GPU — `PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)`

| Key | 值 |
|-----|-----|
| `device-id` | data 小端 `67FF`（plist base64 `/2cAAA==`） |
| `model` | `AMD Radeon RX 570`（可选显示名） |

不要仅为「显示成 RX 580」改回 `67DF`；2048SP 更接近 570。

### HDA — `PciRoot(0x0)/Pci(0x1f,0x3)`

| Key | 值 |
|-----|-----|
| `layout-id` | `5`（与 `alcid=5` 一致） |
| `alc-delay` | `1000` |
| `alctcsel` | data `01 00 00 00` |
| `No-hda-gfx` | 阻止绑到 HDMI 音频 |

### iGPU（冗余但无害）— `PciRoot(0x0)/Pci(0x2,0x0)`

- headless `ig-platform-id` `59120003`（`AwASWQ==`）

## boot-args 期望值

```
keepsyms=1 npci=0x3000 alcid=5 alctcsel=1 alcdelay=1000 -radcodec
```

`-radcodec`：2048SP 软伪装下启用 VA 编解码路径。Polaris **不要**加 `agdpmod=pikera`（那是 Navi）。

## UEFI.Output / Picker 分辨率（本机 2560×1440 HDMI）

| Key | 期望 |
|-----|------|
| `Resolution` | `2560x1440`（比 `Max` 更稳；GOP 报错再改回 `Max`） |
| `ForceResolution` | `true` |
| `UIScale` | `1`（不要 `0` Auto；HiDPI 才用 `2`） |
| NVRAM `UIScale` | data `01`（`AQ==`），并加入 Delete 以便每次覆盖 |

仍异常时优先试 DisplayPort；再 Reset NVRAM。

## PlatformInfo

- `SystemProductName`：`iMac18,3`（Polaris AGPM；避免 iMacPro Vega 功耗表导致 UI stutter）

## Kext / SSDT / 驱动基线

常见启用：Lilu、AppleALC、WhateverGreen、VirtualSMC(+SMC*)、IntelMausi、AtherosE2200、NVMeFix、USBToolBox + UTBDefault。

SSDT：EC、PLUG、SBUS、USBX。

## UEFI.Audio 注意

| Key | 当前/期望 |
|-----|-----------|
| `AudioDevice` | 必须是 HDA 控制器：`PciRoot(0x0)/Pci(0x1f,0x3)`（不是 Root Port `1b.0`） |
| `AudioSupport` | 仅在为 `true` 时，ResetTrafficClass / SetupDelay 等才生效 |

## OpCore-Simplify 注意

- Spoof 表应含 `"1002-6FDF": "1002-67FF"`
- Polaris 机型优先 `iMac18,3`，不要默认成 iMacPro

## 审核 checklist

- [ ] GPU / HDA DeviceProperties 路径与 Report.json 一致
- [ ] `alcid` 与 `layout-id` 同步
- [ ] SMBIOS 与 GPU 架构匹配（Polaris → iMac18,x）
- [ ] 无 Navi-only boot-args
- [ ] Timeout / ShowPicker 符合预期
- [ ] WiFi：BCM4360 是否已加 AirportBrcm（若需要）
- [ ] USB：是否仍为空白 UTBDefault
- [ ] 改完后计划 Reset NVRAM

## Git 卫生

- 忽略 / 勿提交：OpCore 安装器 `.exe`、巨大 Results 缓存
- 推送被拒时检查**历史 blob**，不只看当前工作树
- 公开仓库注意 SMBIOS 序列号 / MLB / ROM 隐私

## Picker UX（并入总技能，不单独拆）

- 菜单文案 = 卷标（Volume Name），不是机型
- `Misc → Boot → Timeout`：本机已设为 `10`
