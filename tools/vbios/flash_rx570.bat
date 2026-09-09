@echo off
setlocal EnableExtensions
title RX580 VBIOS Flash
color 0A
cd /d "%~dp0AMDVBFlash-3.31"
if not exist "amdvbflash.exe" (
  echo ERROR: amdvbflash.exe not found in:
  echo   %CD%
  pause
  exit /b 1
)

set "ROM=..\roms\RX580_rx570_patched_fixed.rom"
if not exist "%ROM%" (
  echo ERROR: missing flash ROM:
  echo   %ROM%
  pause
  exit /b 1
)

echo ============================================================
echo  RX 580 2048SP VBIOS flash - step by step
echo  Flash file: %ROM%
echo  Backup ROM: ..\roms\RX580-original.rom  (also in repo root)
echo ============================================================
echo.
echo If the window looks blank, maximize it.
echo If UAC appears, click Yes.
echo.
pause

echo.
echo [1/4] Install AMDVBFlash driver (another window may open).
echo       Close it after install finishes. Skip if already installed.
echo.
pause
start /wait "" "%~dp0AMDVBFlash-3.31\AMDVBFlashDriverInstaller.exe"

echo.
echo [2/4] List GPU adapters (expect AMD Radeon / Ellesmere).
echo.
amdvbflash.exe -i
echo.
echo Adapter number is usually 0.
pause

echo.
echo [3/4] Ready to flash adapter 0
echo      File: %ROM%
echo.
set /p CONFIRM=Type YES then Enter to flash: 
if /I not "%CONFIRM%"=="YES" (
  echo Aborted. Nothing flashed.
  pause
  exit /b 2
)

echo.
echo Programming VBIOS... DO NOT power off.
amdvbflash.exe -p 0 "%ROM%"
if errorlevel 1 (
  echo Normal flash failed, retry with force -f ...
  amdvbflash.exe -f -p 0 "%ROM%"
)

echo.
echo [4/4] Done. Reboot, then check GPU-Z Device ID (expect 67FF).
echo.
pause
