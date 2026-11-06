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

### Reset NVRAM 怎么做（本机）

- 已加载 `ResetNvramEntry.efi` 且 `HideAuxiliary=false` → OpenCore 菜单最右侧直接有 **Reset NVRAM** 图标；看不到就按空格显示辅助项
- 选中回车 → 黑屏自动重启 → 回菜单选 macOS 卷；只做一次
- `PollAppleHotKeys=false` → 白苹果 `Cmd+Opt+P+R` 无效
- 重置会清 BIOS 启动顺序：若直接进 Windows，去 BIOS 把 PM991（OC 所在盘）设回第一启动
- 本机实测（2026-11）：Reset 后直接不进 OC 菜单 → 开机狂按 **F12** 选 `UEFI OS / SAMSUNG MZ9LQ128` 项（靠 `EFI\BOOT\BOOTx64.efi` 兜底）；再 **Del** 进 BIOS 设 Boot Option #1；CSM 须 Disabled
- 根治可选：`Misc→Boot→LauncherOption` 由 `Disabled` 改 `Full`（OC 每次自注册为首启项，防 Reset/Windows 更新抢启动）

## 本机已知正确基线（2026-09）

- SMBIOS：`iMac18,3`
- GPU：日常 **v20**（TPU #212488 + SSID`2392`，≈1244 MHz）→ Device **`0x67DF`**；v30（+原版 PowerPlay）间歇掉驱动已回退，见 `rx580-2048sp-macos`。**无** GPU DeviceProperties 软伪装（刷成功后已去掉）
- Audio：`alcid=5` + `layout-id=5` + `alctcsel=1` + `alcdelay=1000` @ `PciRoot(0x0)/Pci(0x1f,0x3)`；2026-11 COEF verbs 写入 AppleALC layout 5 后声卡已验证正常，调试用 `alcverbs=1` 已去掉
  - Windows 热重启无声：`AudioSupport`+`DisconnectHda` 本机实测无效已还原；优先 Windows 关快速启动 / `powercfg -h off`；根治走 `applealc-layout-tuning` 的 COEF 流程（`tools/audio/`）
- NVMe（PM991）：`ps-max-latency-us=0`；`SetApfsTrimTimeout` 保持 **`-1`**（`0` 疑致卡在 AHCI 之后，见下）
- Output：`Resolution=Max`，`ForceResolution=false`，`UIScale=0`
- `Misc → Boot → Timeout`：`10`
- SSDT：EC / PLUG / SBUS / USBX

## Picker / GOP（本机踩坑）

- Picker 文案「Ventura」= **卷标**，不是 SMBIOS；`diskutil rename` 即可
- **禁止**本机组合：`Resolution=2560x1440` + `ForceResolution=true` + `UIScale=1`（+ NVRAM `UIScale`）→ HDMI/Polaris GOP 易黑屏、反复进不了系统
- 可启动基线：`Resolution=Max`，`ForceResolution=false`，`UIScale=0`，并删掉 NVRAM 里的 `UIScale`
- Picker 图标过大可先试 DisplayPort；勿再强推 ForceResolution 修 UI

## 启动日志

- 排障基线（OS_13 / OS_26 可同开）：`Misc → Debug` 设 `AppleDebug=true`、`ApplePanic=true`、`Target=67`（屏幕+串口+文件）；boot-args 加 `-v`
- `Target=67`：OpenCore 阶段屏上可见 DEBUG；ESP 根目录会写 `opencore-YYYY-MM-DD-hhmmss.txt`（预分配 **256KB**，尾部大量 `0x00` 正常）
- 判读（本机 2026-09 `Documents/黑苹果log` 实测）：
  - **有用**：含 `AAPL: #[EB|` 且以 `LOG:EXITBS:START` 结尾 → `boot.efi` 已成功交接内核；可核对 `MBA:OUT`（boot-args）、`BRD:NV`（`Mac-BE088AF8C5EB4FA2`=iMac18,3）、`CSR:OUT`
  - **几乎无用**：整文件非零字节为 0（仅占位）→ 多半选了 Windows / Reset NVRAM / 未走到 AppleDebug，可删
  - **覆盖范围**：`AppleDebug` 文件日志主要是 **boot.efi 早启**，通常 **没有** `OC:` 行，也 **没有** 内核 `-v` 之后的内容 → 查 GPU/声卡/kext panic 不够，需屏上 `-v` 或系统日志
  - `Err(0xE) <- RT.GV boot-signature/boot-image*` 等缺 NVRAM 项：黑苹果常见，**不是**故障
- 稳定后：关掉 `AppleDebug`/`ApplePanic`，`Target` 改回 `0` 或 `3`，并去掉 `-v`
- 本机曾因分辨率改坏启动，用 `-v` 确认卡点

## OpCore Simplify 默认 vs 本机 OS_13（2026-09 实测）

用 `SysReport` + Ventura `22.99.99` 非交互生成默认包（`tools_compare_default_build.py`），再对 `OS_13`（`tools_compare_to_os13.py`）。

### 确认是工具 BUG / 缺口

1. **`AirportBrcmFixup` 漏选：** `14E4-43A0` 在 `BroadcomWiFiIDs` 索引 18，但选择逻辑只用 `[:15]`/`[15]`/`[16:18]` → **默认包无 Wi‑Fi 修复 kext**；本机 OS_13 已手工补上，正确
2. **`UEFI.Audio.AudioDevice` 写成 `PciRoot(0x0)/Pci(0x1b,0x0)`（Root Port）**，本机正确为 HDA `1f.3`
3. **SysReport 仍为 `6FDF` 时默认加 GPU `device-id→67FF` 软伪装**；本机已硬刷 `67DF`，OS_13 **无** GPU DeviceProperties——勿把默认伪装盖回去
4. **PM991（`MZ9LQ`/`A809`）不告警**；只加 `NVMeFix`。偶发重启优先换盘，不是再对齐 Simplify 默认

### 默认合理、与 OS_13 一致或可忽略

- SMBIOS `iMac18,3`；SSDT：EC/PLUG/SBUS/USBX（Simplify 多 `SSDT-MCHC`，可留）
- 共用 kext：Lilu / VirtualSMC(+SMC*) / WEG / AppleALC / NVMeFix / 双网卡 / USBToolBox+UTBDefault
- `layout-id=5`；Output `Max` / 无 ForceResolution
- Kernel/Booter/UEFI Quirks 与 OS_13 无关键

### 本机相对默认的有意改动（勿当 BUG 回退）

| 项 | Simplify 默认 | OS_13 |
|----|---------------|-------|
| boot-args | `-v debug=0x100 keepsyms=1 -radcodec` | `npci=0x3000 alcid=5 alctcsel=1 alcdelay=1000`（无 `-radcodec` 亦可） |
| HDA props | 仅 `layout-id` | + `alc-delay` / `alctcsel` / `No-hda-gfx` |
| SecureBootModel | `Default` | `Disabled` |
| Debug Target | `3` | `67`（排障） |

本机 SysReport 存储：`8086-A102` SATA（GLOWAY STK240GS3-S7）+ Samsung NVMe `144D-A809` / 型号 **`MZ9LQ128HBHQ-00000`（PM991 OEM；Report 常误标成 980）**。  
**macOS 在该 NVMe 上**（用户确认）。日志里 `Rome…D22…Cryptex` = Ventura（Darwin 22）。

### 优先怀疑：PM991 系统盘

- Dortania Anti-Hackintosh Buyers Guide：**PM981 / PM991** 在 macOS 上易卡顿、TRIM 异常、不稳定；NVMeFix 对 PM981 仅部分缓解，**PM991 官方「Not planned」**
- OpCore `UnsupportedNVMeSSDIDs` 只列了 `144D-A808`（PM981 等），**不含** `A809`/PM991 → Simplify **不会**拦这盘，只会照常加 `NVMeFix`
- 本机已有 `NVMeFix`，对 PM991 **不足以**当根治；偶发重启/启动晚期挂起与盘侧超时很吻合
- 日志里 `disk1` TRIM ~9s、以及 SATA Port5 空口噪声：在「系统在 NVMe」前提下，**降级为次要**；Port5 仍可忽略

缓解（一次改一项；暂不换盘时）：

1. 已有：`NVMeFix` + Lilu
2. **已加（2026-09）：** `PciRoot(0x0)/Pci(0x1d,0x0)/Pci(0x0,0x0)` → `ps-max-latency-us=0`（PM991 临时降 APST；需覆盖 ESP + Reset NVRAM）
3. ~~`SetApfsTrimTimeout=0`~~ **已回退为 `-1`（2026-11）：** 改 `0` 后 OS_13 `-v` 停在 `[AHCI][HBA] start::512: Successfully initialized AHCI controller` 不再前进（下一步就是挂 APFS 根盘）；该值从未在真机验证过。改回 `-1` 前勿再碰；如仍想关 TRIM，单独一项改、单独验证
4. **可靠方案仍是换盘**（WD SN750 / 多数 Phison 等）

### 日志噪声（通常不是根因）

| 行 | 含义 |
|----|------|
| `ASP: port is not ready for callouts` | 无 T2/SEP 时常见；单独不能定论 |
| `AMFI: …dyld_shared_cache… is adhoc signed` | SIP/`csr` 放宽后常见 |
| `shared_region … vm_shared_region_start_address() failed` | 多见于 launchd/dyld；常为伴随症状 |
| `AHCI … Port 5 … COMRESET` / `PxSSTS: 0x4` | 空口；AHCI 仍会成功初始化 |
| `failed to load virtual random: (-147) (-536870212)` | `prng_seedctl` 尝试加载 **VirtIO/虚拟熵源**（真机无此设备）→ `kIOReturnError`；黑苹果/无 SEP 常见，**非 panic** |
| `kern.prng.user_reseed_count: … No such file` / `tzinit: … No such file` | 同上阶段噪声；tz 数据小差异可忽略 |
| `Couldn't build index … Not eligible for acceleration` | launchd 早期任务加速索引；可忽略 |

**屏拍停在 `virtual random`、随后卡 ~30s 再进桌面（本机 2026-09）：**  
可见日志只到 `launchd` 的 `prng_seedctl`（用户态早期，FIPS/endpointsecurity 已过）。最后一行是噪声，真正拖延多半发生在**之后且不再刷屏**——优先对照 PM991 盘侧超时 / APFS，其次再看是否仍偶发。勿为这条去改 RNG / SecureBoot / 加无用 kext。

**屏拍最后一行是 `[AHCI][HBA] … Successfully initialized AHCI controller` 且不动：** Port2–5 的 COMRESET 是空口噪声；真正卡在随后的 APFS 挂根盘。先对比最近改过的存储相关项（`SetApfsTrimTimeout`、NVMe DeviceProperties、NVMeFix），回退到最后可启动值；等 ~2 分钟若出现 `Still waiting for root device` = 根盘没挂上（NVMe 未识别）。OC 二进制升级只影响到内核交接前，能跑到 AHCI 说明 OC 本身没问题。

屏拍停在 ASP、无 `panic` / `Kernel trap` → 日志不完整。查 ESP `opencore-*.txt` 与 DiagnosticReports。

### OpCore SATA 旁注（次要）

`8086-A102` 在 `UnsupportedSATAControllerIDs`，但 `kext_maestro` 因名含 `[AHCI Mode]` 跳过 `CtlnaAHCIPort`。系统不在该 SATA 上时，不必先为偶发重启加该 kext。

### 排障顺序

1. 分清：启动中 vs 进桌面后偶发重启
   - 「开机卡死 → 按 Reset → 能进但无声」：卡死是主问题，无声是热复位副作用（见 `applealc-layout-tuning`）；先治卡死
2. `Target=67` + `-v keepsyms=1` → ESP 拷 `opencore-*.txt`；进系统查 panic 报告
3. 先做 PM991 缓解（`ps-max-latency-us=0`；勿用 `SetApfsTrimTimeout=0`，见上），观察是否减少
4. 仍复发 → **换系统盘**（根本解）
5. 进桌面后重启：另查 USB map（`UTBDefault`）、睡眠、GPU（日常 **v20**，勿用 v30）

## 视频卡顿（软伪装时代遗留）

- 可选 `-radcodec`（WhateverGreen）：改善伪装 ID 下 VA 路径
- YouTube 高码率 VP9/AV1 在 Polaris 上常无硬解 → CPU 软解；不是「RX580 不够」单因
- 硬刷后 Metal 完整仍可能软解 VP9/AV1

## 本机已知未完成 / 易误判

- Windows→macOS 热重启无声：`AudioSupport`+`DisconnectHda` 本机无效；见 `applealc-layout-tuning`（先 Windows 快速启动，勿再推该 EFI 组合）
- WiFi BCM4360（`14E4-43A0`）子系统 `0111106B` = **Apple 原装卡**，Ventura 原生免驱；AirportBrcmFixup 可留可删（Sonoma+ 才需 OCLP）
- `UTBDefault.kext` = 无真实 USB map，且**不解除 15 端口上限**：Z170 XHC（`8086-A12F`）HS 口排在前面 → 板载 USB3 口大概率只跑 USB2 速度。修法：Windows 用 USBToolBox 建 `UTBMap.kext`，删 `UTBDefault`
- DSDT 原生 `H_EC` 的 `_STA` 恒返回 0 → 用假 `SSDT-EC` 正确，勿去禁用/改名 H_EC
- DMAR 有 Reserved Memory Region（BIOS 开 VT-d），但 `DisableIoMapper=true` 已关 AppleVTD → `DisableIoMapperMapping` 不需要
- CFG Lock：网上 Z170X-Gaming 5 F20–F22 偏移 `setup_var 0x4EF 0x00`；本机 F22f 先用 `ControlMsrE2.efi` 验证再改，成功后可关 `AppleXcpmCfgLock`

## 校验 config（ocvalidate 版本必须与 OpenCore 一致）

1. 下载对应版 `OpenCore-<ver>-RELEASE.zip` 到 `%TEMP%`，用 `Utilities/ocvalidate/ocvalidate.exe <config.plist>`
2. 新版只报 `Missing key …` = schema 旧（如 1.0.8 新增 `Drivers[].HideVerbose`），不是逻辑错误
3. 识别 EFI 版本：对比 `X64/EFI/OC/OpenCore.efi` 哈希；都不匹配 = Simplify 拉的夜间构建
4. 2026-11：OS_13 原为夜间构建（1.0.7 schema）→ 已换 **1.0.8 正式版**（`BOOTx64`/`OpenCore`/`OpenRuntime`/`OpenCanopy`/`ResetNvramEntry`，`HfsPlus` 非 OCPkg 不换）+ 驱动补 `HideVerbose=false`，ocvalidate 1.0.8 **0 问题**；**2026-11-06 已真机进桌面**（同时 COEF 声卡正常、出现窗口阴影残影）
   - 随后去 `alcverbs=1` + Reset NVRAM 后：`-v` 过 cryptex/dyld/`spaceman_scan_free_blocks` TRIM 后停住（无 panic）
   - **2026-11-07 已回退：** 部署回退件（5 个 OC 二进制取旧夜间构建 + 去 `HideVerbose`，其余含声卡修复一致）后真机可进系统 → `OS_13` 已恢复为该版本并删除 `OS_13_oc-rollback`。**当前 OS_13 = 夜间构建（1.0.7 schema）+ AppleALC COEF 修复**；再升 1.0.8 须单独一项改、单独验证
5. 升级 OC 只换上述二进制 + 补新键；Resources 图标来自 OcBinaryData，可不动
6. OS_26 仍是夜间构建（1.0.7 校验 0 问题，1.0.8 报 5 个 `HideVerbose`：含 `apfs_aligned.efi`）；升级同上，`apfs_aligned`/`HfsPlus` 不换
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
9. **PM991 缓解：** NVMe `1d.0/0.0` 的 `ps-max-latency-us=0`；`SetApfsTrimTimeout` 保持 `-1`（`0` 在 OS_13 疑致启动卡住）
10. 有 `AMFIPass` 时 `amfi=0x80` 多余（会影响权限弹窗/部分 App）；能启动后去掉

### 2026-11 联网版本基线（审核时对照）

- OpenCore **1.0.8** 正式版（1.0.9 开发中）；AppleALC **1.9.8**；Lilu 1.7.2 / WEG 1.7.1 / VirtualSMC 1.3.8 / NVMeFix 1.1.3+ / AirportBrcmFixup 2.2.0 / AMFIPass 1.4.1 均为最新
- OCLP：稳定版 **2.5.1 只到 Sequoia**；Tahoe 仅 **3.0.0-rc**（官方警告不稳定）
- Ventura 已停更；iMac18,3 最后支持 Ventura。想升级又求稳：Sequoia + `MacPro7,1`（同 OS_26 套件）+ OCLP 2.5.1 修 BCM4360
- 更新 OC 后用同版本 `ocvalidate` 校验 config schema

### 安装顺序建议

1. 改好的 OS26 EFI 写到独立 U 盘 ESP（保留 OS13 EFI / 系统盘不动）
2. Reset NVRAM → 试启动安装器
3. 装完进桌面后再考虑 OCLP root patch（Wi‑Fi / AppleHDA 等）
4. 失败则仍用 OS13 EFI 回 Ventura

## AI 工具链评估（2026-10）

- **没有**成熟的黑苹果专用 MCP；本仓库已有 Cursor 文件/终端能力 = Filesystem MCP 的作用，不必再装
- 有用：`lzhoang2801/OpCore-Simplify`（~7.6k★，已在用）、OCAT（GUI 校验/同步 kext）、Dortania 指南、`5T33Z0/OC-Little-Translated` 的 `Config_Tweaks_AI.md`（DEBUG 日志 → LLM 分析 → 一次改一项）
- 不适合本机：Peekaboo / mcp-x-mac-seed 要求 macOS 15+（本机 Ventura 13）；cua / otto 偏桌面自动化，对 EFI/内核排障无增益
- 真正起作用的是本仓库技能 + `tools/` 脚本（vbios、audio COEF），而非多装 MCP

## 部署到 ESP（Windows 一键）

- `tools\deploy-efi.cmd`（双击，自动 UAC）或 `tools\deploy-efi.ps1 [-Build OS_26] [-WhatIf] [-CollectLogs] [-Yes]`
- 不带 `-Build` 时自动扫描 `OpenCore EFI\**\EFI\OC\config.plist` 列出源（修改时间 / kext 数 / 大小）供选号；新加的 EFI 目录无需改脚本
- 确认前打印全部硬盘（型号/序列号/容量/总线/健康/启动盘标记）及各分区（类型/大小/盘符/剩余），目标盘与分区绿色标出
- 目标 = macOS 所在 PM991（型号含 `MZ9LQ128`，Windows 下为磁盘 1，ESP 300MB 无盘符）；Windows 盘 GLOWAY 的 ESP 是 Windows 引导，**勿写**
- 保险：型号唯一匹配 + 拒绝 `IsBoot/IsSystem` 盘 + 必须有 APFS 分区 + 写前输入 Y
- 流程：临时盘符 → 备份旧 EFI 到 `_esp_backup\<时间戳>`（gitignore）→ `robocopy /MIR` 只镜像 `EFI\`（根目录 opencore 日志不动）→ 校验 config.plist 哈希 → 移除盘符
- 脚本含中文须存 **UTF-8 BOM**（PS 5.1）；`.cmd` 存 GBK；参数勿叫 `$Profile`（撞自动变量）

## 标准部署检查清单

- [ ] 只同步已验证的 EFI 树（用 `tools\deploy-efi.cmd`）
- [ ] Reset NVRAM
- [ ] 关于本机 / 系统报告：VRAM≈8GB、GPU=`67DF`、Metal
- [ ] 声音：后置绿孔 + 「内建」输出（非 HDMI）
- [ ] 启动菜单 Timeout / 卷标符合预期；能进系统（非 ForceResolution 黑屏）
