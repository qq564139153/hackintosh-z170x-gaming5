# RX 580 2048SP VBIOS 刷机工具包

本机：PowerColor RX 580 2048SP（原 `1002:6FDF` / SSID `148C:2392`，Hynix `H5GQ8H24MJR` 8GB）。

详细诊断树见 `.cursor/skills/rx580-2048sp-macos/SKILL.md`。

## ROM 命名（`roms/`）

版本号越大 = 在上一版上叠的改动越多。只保留这一套文件名。

| 文件 | MD5 | 说明 |
|------|-----|------|
| `v00_stock_6FDF_ssid2392.rom` | `8e88fa633cc6843d7e168c45b7878bae` | 本机原版 dump（救援用） |
| `v10_tpu212488_upstream.rom` | `58569ccbdd5e896666225aa7026931ac` | [TechPowerUp #212488](https://www.techpowerup.com/vgabios/212488/212488) 原件（SSID `2379`，**不可直刷**） |
| `v20_tpu212488_ssid2392.rom` | `f97ab3dd3ffddee6151a66c3c11ccc3b` | v10 + SSID→`2392`；**已验证亮机**（默认钟 ≈1244 MHz） |
| `v30_tpu212488_ssid2392_pp1310.rom` | `b669d2a6a74b095d73e15def6aad2597` | v20 + 原版 SCLK/TDP→1310/145；刷入成功但本机**间歇掉驱动**，已回退 v20；**勿作日常** |

### 上游来源

- **v10 下载页：** https://www.techpowerup.com/vgabios/212488/212488  
- 页面标题：Dataland RX 570 8 GB（PCI Device 实为 `67DF`）  
- TPU MD5（须与 `v10` 一致）：`58569ccbdd5e896666225aa7026931ac`

### 命名规则

`vNN_<来源>[_改动…]`

- `v00` 本机 stock  
- `v10` 未改的上游 TPU  
- `v20` 最小可刷改动（仅 SSID）  
- `v30` 在可刷基础上恢复性能（PowerPlay）

## 目录

| 路径 | 用途 |
|------|------|
| `AMDVBFlash-classic-3.31/` | **唯一可用** flash 工具（真 3.31 EXTERNAL） |
| `amdvbflash_win_3.31_classic.zip` | 上述工具备份包 |
| `build_v30_pp1310.py` | 从 v00+v20 生成 v30 |
| `flash_v20_ssid2392.bat` | 刷入 v20（已验证路径） |
| `flash_v30_pp1310.bat` | 刷入 v30（性能修复） |
| `restore_v00_stock.bat` | 还原本机原版 |
| `dump_current.bat` | 从卡上 dump → `roms/dump-from-card.rom` |
| `../fix_vbios_checksum.py` | 修 Option ROM 校验和 |
| `../compare_vbios.py` | ROM 字节对比 |

EXTERNAL **无 `-f`**。跨 SSID 须先改 ROM。勿用名为 3.31 实为 5.0.x 的包。

## 推荐刷机顺序

1. **日常推荐 v20**（`flash_v20_ssid2392.bat`）；v30 本机已验证会间歇掉 Windows 驱动，勿再作默认  
2. 管理员运行 bat，输入 `YES`；日志须有 `programmed` + `verified`  
3. **关机 → 断电约 10 秒 → 再开**  
4. GPU-Z：Device `67DF`；v20 时 Default Clock ≈**1244 MHz**  
5. 若误刷 v30 后掉驱动：再刷回 v20 即可（已验证恢复）

重新生成 v30：

```text
python tools/vbios/build_v30_pp1310.py
```

## 还原原版

1. 管理员运行 `restore_v00_stock.bat`  
2. 黑屏时：主板 HDMI + 开 iGPU / 远程桌面后再跑  
3. `.bat` 必须 CRLF + ASCII  
4. 还原后 Device 回到 `6FDF`
