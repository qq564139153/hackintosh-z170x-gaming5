# RX 580 2048SP VBIOS 刷机工具包

本机：PowerColor RX 580 2048SP（原 `1002:6FDF` / SSID `148C:2392`，Hynix `H5GQ8H24MJR` 8GB）。

**当前已刷入（2026-09-12 亮机正常）：** TPU #212488 经 SSID `2379→2392` 补丁后的整份 ROM → Device `67DF`。

详细诊断树见 `.cursor/skills/rx580-2048sp-macos/SKILL.md`。

## 目录

| 路径 | 用途 |
|------|------|
| `AMDVBFlash-classic-3.31/` | **唯一可用** flash 工具（3.31 EXTERNAL） |
| `roms/RX580-original.rom` | 原版备份（务必保留） |
| `roms/RX570-212488.rom` | TPU #212488 原件（SSID `2379`，直刷会 `0FL01`） |
| `roms/RX570-212488_ssid2392_fixed.rom` | **已成功刷入的那份**（SSID 已改 `2392`） |
| `roms/RX580-after-212488ssid.rom` | 刷后 dump（应与上一份 0 字节差） |
| `flash_rx570_212488_ssid2392.bat` | 刷入 SSID 补丁版 #212488 |
| `restore_original.bat` | 还原原版 |
| `../fix_vbios_checksum.py` | 修 Option ROM 校验和 |

## 工具版本

| 路径 | 实际版本 | 可用 |
|------|----------|------|
| `AMDVBFlash-classic-3.31/` | **3.31 EXTERNAL** | 是 |
| `AMDVBFlash-3.31/` / `AMDVBFlash/` | 实为 5.0.x | 否 |

EXTERNAL **无 `-f`**。跨 SSID 须先改 ROM，不能靠强制参数。

## 成功路径（SSID 补丁整刷）

1. `#212488` 中 `148C:2379` → `148C:2392`，再修 checksum
2. 管理员运行 `flash_rx570_212488_ssid2392.bat`，输入 `YES`
3. 日志须有 `programmed` + `verified`，`6FDF→67DF`
4. **关机 → 断电约 10 秒 → 再开**

勿再刷：`RX580_rx570_patched_fixed.rom`（改 ASIC→570 曾黑屏）、未改 SSID 的 `RX570-212488.rom`。

## 还原原版

1. 管理员运行 `restore_original.bat`
2. 黑屏时：主板 HDMI + 开 iGPU / 远程桌面后再跑
3. `.bat` 必须 CRLF + ASCII
4. 还原后 Device 回到 `6FDF`
