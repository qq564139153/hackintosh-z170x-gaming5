@echo off
rem 双击运行：先选 EFI 源，再确认目标盘；也可传参，如 deploy-efi.cmd -Build OS_26
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy-efi.ps1" -Pause %*
