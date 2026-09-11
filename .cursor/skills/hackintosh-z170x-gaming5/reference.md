# reference — 本机硬件与配置快照

权威来源：`OpCore-Simplify-main/SysReport/Report.json` + 当前 `config.plist`。

## 硬件表

| 项 | 值 |
|----|-----|
| 主板 | GIGABYTE Z170X-GAMING 5（Z170，BIOS F22f） |
| CPU | i7-7700K（Kaby Lake） |
| GPU | RX 580 2048SP **硬刷 v30** → `1002-67DF`（#212488 + SSID`2392` + 原版 PP）；PCI `PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)`，ACPI `\_SB.PCI0.PEG0.PEGP`；救援原版仍为 `6FDF` |
| 显示器 | HDMI 2560×1440（走独显） |
| 声卡 | Realtek ALC1150 `10EC-0900`，控制器 `8086-A170`，路径 `PciRoot(0x0)/Pci(0x1f,0x3)`（HDAS） |
| 有线网 | I219-V `8086-15B8` + Killer E2400 `1969-E0A1` |
| WiFi | Broadcom BCM4360 `14E4-43A0` @ `PciRoot(0x0)/Pci(0x1c,0x6)/Pci(0x0,0x0)` |
| 报告无核显条目 | 多半 BIOS 已关 iGPU（黑屏救援时需开 iGPU + 主板 HDMI） |

## DeviceProperties 期望值

### GPU — 硬刷后

**当前基线：不要写 GPU DeviceProperties。** 卡上已是 `67DF`，软伪装已移除。

仅当回退到原版 `6FDF`、临时软伪装时才加：

| Key | 值 |
|-----|-----|
| 路径 | `PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)` |
| `device-id` | data 小端 `67FF`（plist base64 `/2cAAA==`） |
| `model` | `AMD Radeon RX 570`（可选） |

不要仅为「显示成 RX 580」改回 `67DF` 伪装；2048SP 更接近 570。硬刷成功后身份由 VBIOS 提供。

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
keepsyms=1 npci=0x3000 alcid=5 alctcsel=1 alcdelay=1000
```

可选：

- `-radcodec`：软伪装时代改善 VA；硬刷后仍可试，对 Dock 动画未必明显
- `-v`：排障启动日志（稳定后去掉）

Polaris **不要**加 `agdpmod=pikera`（那是 Navi）。

## Output / Picker（GOP 安全基线）

| Key | 本机安全值 | 危险值（已踩坑） |
|-----|------------|------------------|
| `Resolution` | `Max` | 固定 `2560x1440` |
| `ForceResolution` | `false` | `true` |
| `UIScale` | `0` | `1` + NVRAM 写入 `UIScale` |

危险组合在本机 HDMI + Polaris GOP 上会导致黑屏 / 反复进不了系统；已回退并保留 `-radcodec` 不影响启动的结论。

Picker 文案 = 卷标；`Timeout=10`。

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

- Spoof 表可含 `"1002-6FDF": "1002-67FF"`（仅软伪装阶段）
- Polaris 机型优先 `iMac18,3`，不要默认成 iMacPro
- 硬刷后生成 EFI 时勿再强加 GPU `device-id` 伪装

## 审核 checklist

- [ ] GPU：硬刷态无 DeviceProperties 伪装；或软伪装路径与 Report.json 一致
- [ ] HDA DeviceProperties 路径与 Report.json 一致
- [ ] `alcid` 与 `layout-id` 同步
- [ ] SMBIOS 与 GPU 架构匹配（Polaris → iMac18,x）
- [ ] 无 Navi-only boot-args
- [ ] Output 未开危险 ForceResolution 组合
- [ ] Timeout / ShowPicker 符合预期
- [ ] WiFi：BCM4360 是否已加 AirportBrcm（若需要）
- [ ] USB：是否仍为空白 UTBDefault
- [ ] 改完后计划 Reset NVRAM

## Git 卫生

- 忽略 / 勿提交：OpCore 安装器 `.exe`、巨大 Results 缓存、大体积 ROM dump（按需）
- 推送被拒时检查**历史 blob**，不只看当前工作树
- 公开仓库注意 SMBIOS 序列号 / MLB / ROM 隐私

## 会话经验归属（避免重复开技能）

| 主题 | 归入 |
|------|------|
| 修驱动 / 流畅 / 伪装 / VBIOS / 黑屏救援 / 1244→1310 | `rx580-2048sp-macos` |
| 后置无声 / layout 试错 / 间歇音频 | `applealc-layout-tuning` |
| 双系统时间偏几小时 | `dualboot-rtc-utc` |
| Picker 文案、Timeout、GOP 黑屏、EFI 审核、部署 | 本技能 + 本 reference |
| YouTube/VP9 软解、`-radcodec` | 本技能（视频卡顿）+ `rx580` WhateverGreen |
