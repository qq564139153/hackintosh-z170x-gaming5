# 本仓库 Agent Skills 索引

经验来自本机黑苹果相关会话；改配置后按 `.cursor/rules/experience-to-skills.mdc` 继续沉淀。

| 技能 | 触发场景 | 主要来源会话（标题） |
|------|----------|----------------------|
| [hackintosh-z170x-gaming5](hackintosh-z170x-gaming5/) | EFI / config / ESP / Picker / 审核 | 修复RX580显卡驱动、再次审核EFI、启动项显示Ventura、System selection timeout、优化视频与分辨率、修复启动与日志显示、刷机后改EFI配置、会话沉淀技能 |
| [rx580-2048sp-macos](rx580-2048sp-macos/) | 6FDF/Metal/5MB、动画卡、刷 BIOS、黑屏、0FL01、1244→1310 | 修复RX580、显卡驱动流畅优化、继续刷RX580BIOS、核对刷机工具、显卡刷完不亮屏、再刷机器码、Restore original ROM、分析RX570 ROM、整理VBIOS工具与ROM、Flashing performance、生成VBIOS提交记录 |
| [applealc-layout-tuning](applealc-layout-tuning/) | 后置无声、layout、间歇音频 | 音频与显卡型号排查、再次审核EFI |
| [dualboot-rtc-utc](dualboot-rtc-utc/) | 双系统时间偏时区小时 | 双系统时间偏移修复 |

## 存放约定

- **板级 / 本仓库路径**：只放 `.cursor/skills/`（如 `hackintosh-z170x-gaming5`）
- **可复用排障**：同步一份到 `~/.cursor/skills/`（`rx580` / `applealc` / `dualboot`）
- **勿**写入 `~/.cursor/skills-cursor/`（Cursor 内置）

## 不单独拆技能

- Picker 卷标 / Timeout / GOP ForceResolution 黑屏 → 并入 `hackintosh-z170x-gaming5`
- Git 大文件 / SMBIOS 隐私 → `reference.md`「Git 卫生」
- VBIOS 工具路径与 MD5 → `tools/vbios/README.md` + `rx580-2048sp-macos`
