# RX 580 2048SP VBIOS 刷机工具包

本目录保存刷机所需工具与 ROM，对应机型：PowerColor RX 580 2048SP（Device ID `1002:6FDF`，Hynix 8GB）。

## 目录

| 路径 | 用途 |
|------|------|
| `PolarisBiosEditor/` | 可选 GUI，打开 ROM 再 Save 可修校验 |
| `AMDVBFlash/` | `amdvbflash.exe` + 驱动安装器 |
| `roms/RX580-原版.rom` | GPU-Z 导出的原版备份（务必保留） |
| `roms/RX580_idonly_67df_fixed.rom` | **下次应刷这个**：原版只改机器码 `6FDF→67DF`，ASIC 未动 |
| `roms/RX580_rx570_patched_fixed.rom` | 上次黑屏那份：ID→`67FF` 且 ASIC→570，勿再刷 |
| `../patch_rx580_2048sp_vbios.py` | 从原版生成 patched ROM（`--target 580 --id-only`） |
| `../fix_vbios_checksum.py` | 修 Option ROM 8-bit 校验和 |

## 工具版本说明

| 路径 | 实际版本 | 是否可用 |
|------|----------|----------|
| `AMDVBFlash-classic-3.31/` | **3.31.0.0 EXTERNAL**（正确） | 是，含 `-unlockrom` |
| `amdvbflash_win_3.31_classic.zip` | SHA256 `89B921B1…C20406` | 正确源包 |
| `AMDVBFlash-3.31/` / `amdvbflash_win_3.31.zip` | 实为 **5.0.567** | 否，勿用 |
| `AMDVBFlash/` / `amdvbflash_win_5.0.874.zip` | **5.0.874** | 否，勿用 |

## 刷入（只改机器码）

上次刷 `RX580_rx570_patched_fixed.rom` 写入成功但 HDMI 黑屏，已还原。原因是连 ASIC 一起改成了 RX570（`F0 7D E6 0F`），GOP 签名失效。

右键管理员运行：`flash_idonly_67df.bat`（不要用旧的 `flash_rx570.bat`）

1. `-i` 必须显示 `AMDVBFLASH version 3.31 EXTERNAL`
2. 输入 `YES` 才会 `unlockrom` + 刷入 `RX580_idonly_67df_fixed.rom`
3. 成功后：**关机 → 切断电源约 10 秒 → 再开**（不要只点重启）
4. GPU-Z Device ID 应变为 `67DF`

## 恢复原版（刷完黑屏时用这个）

原版 ROM（与 GPU-Z 导出、刷前 dump 字节完全一致）：

- `C:\Users\sean\project-code\hackintosh\RX580-原版.rom`
- `roms\RX580-original.rom` / `roms\RX580-from-card.rom`

本机 BIOS 里核显多半是关的，独显 GOP 挂了会整机不亮屏。先让 Windows 能看见画面，再刷回原版：

1. 关机，拔电源。显示器改插**主板后置 HDMI**（不要插显卡）。
2. 清 CMOS（主板上 CLR_CMOS 跳线/按钮），开机按 Del 进 BIOS。
3. 打开 Intel Processor Graphics / iGPU，Initial Display Output 选 **IGFX**，保存退出。
4. 进 Windows 后，右键管理员运行：`restore_original.bat`
5. `-i` 必须是 `AMDVBFLASH version 3.31 EXTERNAL`，确认 Polaris20 那一行，输入 `YES`
6. 刷完：**关机 → 断电约 10 秒**。显示器改回插显卡 HDMI。GPU-Z 应为 `6FDF`

也可以不拔卡：核显出图 + 独显仍插在槽里，`amdvbflash -i` 仍应能看到 adapter 0。若 adapter 编号不是 0，先停下来。

卡上若有双 BIOS 拨杆，可先拨到另一份再开机。

## 风险

刷错可能黑屏；双 BIOS 卡可拨开关切另一份 BIOS 救援。操作前确认原版 `.rom` 仍在。
