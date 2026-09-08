---
name: dualboot-rtc-utc
description: >-
  Fixes macOS/Windows dual-boot clock skew from RTC UTC vs local-time
  mismatch. Use when Windows time jumps by timezone hours after leaving
  macOS, or the user mentions RealTimeIsUniversal / 双系统时间.
---

# 双系统 RTC 时间

## 根因

- macOS：硬件时钟按 **UTC**
- Windows 默认：硬件时钟按 **本地时**
- 来回切换会产生时区小时数的偏移

## 推荐修复（只改 Windows）

管理员 CMD / PowerShell：

```bat
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f
```

然后：

1. 重启 Windows
2. 打开「自动设置时间」
3. `w32tm /resync`（或手动同步一次）
4. 验证：

```bat
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal
```

看到 `0x1` 即已生效。

## 稳定化流程

第一次从 macOS 切回 Windows 仍可能有一次偏差。建议：Windows → 校时 → 重启 → macOS → 再回 Windows，之后应稳定。

## 不要做

- **不要**为此改 OpenCore / EFI / SSDT（除非有意采用另一套策略）
- 不要在 macOS 侧「改回本地时」作为默认方案（与生态不一致）
