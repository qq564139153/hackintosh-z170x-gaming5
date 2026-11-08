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
   - 先查是否真关了：`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power` → `HiberbootEnabled` 应为 `0`；`powercfg /a` 不应再列「快速启动」（本机 2026-10 复查时仍为 `1`，即从未生效）
4. 仍不行：冷启动对比确认；勿乱改已验证的 `alcid=5`；走下方「COEF 根治」

### 根因：Realtek Windows 驱动清 vendor node 系数

- acidanthera bugtracker #547 / #1934：Realtek Windows 驱动关机时把 vendor widget（NID `0x20`）的 COEF 清零防噪；AppleHDA 不初始化该节点 → 滑块正常但无声
- `alctcsel` / `ResetTrafficClass` 只改 TCSEL，**修不了** COEF 问题；`DisconnectHda` 同理
- 本机 Windows 驱动：`Realtek High Definition Audio` 6.0.1.7727（`oem16.inf`，`HDAUDIO\FUNC_01&VEN_10EC&DEV_0900&SUBSYS_1458A0B2`）
- 开机卡死 → 按 Reset 重启 = 同样是**热复位**（HDA 不断电），无声机理相同；先治卡死

### ALC1150 已知现成 verb（先试这个，省掉采样）

社区在 ALC1150 上验证过（Dolnor/EAPD-Codec-Commander #9、tonymacx86「ALC1150 dual boot no sound (solved)」、bugtracker #547；源自 Linux bugzilla 87771）：
NID `0x20` 写 COEF `0x07 = 0x7CB0`，打包 `02050007 02047CB0`。

1. Windows 重启进 macOS（无声状态）手动验证：`alc-verb 0x20 0x5 0x7` → `alc-verb 0x20 0x4 0x7cb0` → 放音
2. 出声 → `python tools/audio/alc_coef_patch.py apply ".../AppleALC.kext/Contents/Info.plist" --verbs 0x07=0x7CB0 --wake`
3. 不出声 → 走下方完整 COEF 采样（其他板子常见差异位：`0x10` 位9 静音位、`0x1A`）
   - 本机 OS_13 已于 2026-11 写入（layout 5 `ConfigData`/`WakeConfigData` 末尾 `02050007 02047CB0`），**待真机验证**；原文件备份在 `tools/audio/backup/`
   - `apply` 会在 `Contents/` 下生成 `.bak`：部署前移出 kext，别拷进 ESP
4. 旧方案 CodecCommander 自定义命令同效，但 AppleALC `ConfigData` 已能做，不必再加 kext

### COEF 根治流程（本仓库 `tools/audio/`）

前置：boot-args 含 `alcverbs=1`（OS_13 已加）；把 AppleALC release zip 里的 `alc-verb` 拷到 `/usr/local/bin` 并 `chmod +x`。

1. **关机断电**再开机进 macOS（有声）：`./alc_coef_dump.sh cold`
2. 进 Windows 用一次声卡 → **重启**进 macOS（无声）：`./alc_coef_dump.sh warm-win`
3. `python alc_coef_patch.py diff coef-cold-*.txt coef-warm-win-*.txt`
   - 无差异 → 不是 COEF，回头查 Windows 快速启动 / 卡死
4. 在无声状态下逐对执行输出的 `alc-verb ... SET_COEF_INDEX / SET_PROC_COEF`，找**最小**能出声的集合（常 1–2 个）
5. 写入 EFI 里的 kext：`python alc_coef_patch.py apply ".../Kexts/AppleALC.kext/Contents/Info.plist" --verbs 0xIDX=0xVAL --wake`
   - 默认 `--codec 0x10EC0900 --layout 5 --node 0x20`；首次写 `.bak`；重复执行幂等
   - `show` 子命令查看当前 `ConfigData` / `WakeConfigData`
6. 覆盖 ESP → Reset NVRAM → 再测 Windows 热重启；稳定后可去掉 `alcverbs=1`
7. 升级 AppleALC 会覆盖补丁 → 重新 `apply`

打包规则：`0x0{nn}5{iiii}` + `0x0{nn}4{vvvv}`（例 coef `0x10=0x0020` → `02050010 02040020`，与 AppleALC PR #959 一致）。

临时救急（未写 kext 前）：热重启无声时直接跑第 4 步的 `alc-verb` 命令；或关机断电 10 秒冷启动。

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
- 以为 `alctcsel` 能修 Realtek Windows 驱动清 COEF（两回事）
- 没核对 `HiberbootEnabled` 就认定「已关快速启动」
- `AudioDevice` 写成 Root Port
- `alcid` 与 `layout-id` 不一致
- 测音频时插错孔或选 HDMI 输出
