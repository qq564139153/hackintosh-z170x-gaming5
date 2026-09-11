# RX 580 2048SP VBIOS 刷机工具包

本机：PowerColor RX 580 2048SP（原 `1002:6FDF` / SSID `148C:2392`，Hynix `H5GQ8H24MJR` 8GB）。

**当前已刷入（2026-09-12 亮机正常）：** TPU #212488 经 SSID `2379→2392` 补丁后的整份 ROM → Device `67DF`。

详细诊断树见 `.cursor/skills/rx580-2048sp-macos/SKILL.md`。

## 保留的 ROM（MD5）

| 文件 | MD5 | 说明 |
|------|-----|------|
| `roms/RX580-original.rom` | `8e88fa633cc6843d7e168c45b7878bae` | 本机原版（`6FDF` / SSID `2392`） |
| `roms/RX570-212488.rom` | `58569ccbdd5e896666225aa7026931ac` | TPU #212488 原件（`67DF` / SSID `2379`，直刷会 `0FL01`） |
| `roms/RX570-212488_ssid2392_fixed.rom` | `f97ab3dd3ffddee6151a66c3c11ccc3b` | **已成功刷入**（SSID 已改 `2392`） |

## 目录

| 路径 | 用途 |
|------|------|
| `AMDVBFlash-classic-3.31/` | **唯一可用** flash 工具（真 3.31 EXTERNAL） |
| `amdvbflash_win_3.31_classic.zip` | 上述工具备份包 |
| `flash_rx570_212488_ssid2392.bat` | 刷入 SSID 补丁版 #212488 |
| `restore_original.bat` | 还原本机原版 |
| `dump_current.bat` | 从卡上 dump 当前 VBIOS |
| `../fix_vbios_checksum.py` | 修 Option ROM 校验和 |
| `../compare_vbios.py` | ROM 字节对比 |

EXTERNAL **无 `-f`**。跨 SSID 须先改 ROM，不能靠强制参数。勿用名为 3.31 实为 5.0.x 的包。

## 成功路径（SSID 补丁整刷）

1. 以 `#212488` 为源：`148C:2379` → `148C:2392`，再 `fix_vbios_checksum.py`
2. 管理员运行 `flash_rx570_212488_ssid2392.bat`，输入 `YES`
3. 日志须有 `programmed` + `verified`，`6FDF→67DF`
4. **关机 → 断电约 10 秒 → 再开**

## 还原原版

1. 管理员运行 `restore_original.bat`
2. 黑屏时：主板 HDMI + 开 iGPU / 远程桌面后再跑
3. `.bat` 必须 CRLF + ASCII
4. 还原后 Device 回到 `6FDF`
