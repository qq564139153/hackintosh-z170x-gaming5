# RX 580 2048SP VBIOS 刷机工具包

本目录保存刷机所需工具与 ROM，对应机型：PowerColor RX 580 2048SP（Device ID `1002:6FDF`，Hynix 8GB）。

## 目录

| 路径 | 用途 |
|------|------|
| `PolarisBiosEditor/` | 可选 GUI，打开 ROM 再 Save 可修校验 |
| `AMDVBFlash/` | `amdvbflash.exe` + 驱动安装器 |
| `roms/RX580-原版.rom` | GPU-Z 导出的原版备份（务必保留） |
| `roms/RX580_rx570_patched_fixed.rom` | 已改 ID→RX570 且校验和为 0，可刷入 |
| `../patch_rx580_2048sp_vbios.py` | 从原版生成 patched ROM |
| `../fix_vbios_checksum.py` | 修 Option ROM 8-bit 校验和 |

## 推荐：分步脚本（有中文提示）

右键以管理员运行：

`tools\vbios\flash_rx570_分步.bat`

会停在每一步等你回车；出现 UAC 点「是」。不要关掉看起来像黑窗的控制台——先把窗口拉大看字。

## 手动刷入（管理员 CMD）

优先用 3.31：

```bat
cd /d C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash-3.31
AMDVBFlashDriverInstaller.exe
amdvbflash -i
amdvbflash -p 0 ..\roms\RX580_rx570_patched_fixed.rom
```

刷完重启。成功后可去掉 OpenCore 里 GPU DeviceProperties 软伪装。

## 恢复原版

```bat
amdvbflash -p 0 ..\roms\RX580-原版.rom
```

## 风险

刷错可能黑屏；双 BIOS 卡可拨开关切另一份 BIOS 救援。操作前确认原版 `.rom` 仍在。
