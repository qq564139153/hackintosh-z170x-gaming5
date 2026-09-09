@echo off
setlocal EnableExtensions
title Dump current GPU VBIOS
color 0A
cd /d "%~dp0AMDVBFlash-3.31"
if not exist "amdvbflash.exe" (
  echo ERROR: amdvbflash.exe not found
  pause
  exit /b 1
)

set "OUT=%~dp0roms\RX580-from-card.rom"
if not exist "%~dp0roms" mkdir "%~dp0roms"

echo ============================================================
echo  Dump VBIOS currently stored on the GPU
echo  Output: %OUT%
echo ============================================================
echo.
echo Run this as Administrator. If UAC appears, click Yes.
echo If EULA appears, type Y then Enter.
echo.
pause

echo.
echo [1/2] Ensure AMDVBFlash driver is installed
start /wait "" "%~dp0AMDVBFlash-3.31\AMDVBFlashDriverInstaller.exe"

echo.
echo [2/2] List adapters, then save ROM from adapter 0
echo.
amdvbflash.exe --accept-EULA -i
echo.
echo Saving with classic syntax...
amdvbflash.exe --accept-EULA -s 0 "%OUT%"
if not exist "%OUT%" (
  echo Classic -s failed, trying 5.x syntax...
  amdvbflash.exe --accept-EULA --save --device 0 --vbios-file "%OUT%"
)

echo.
if exist "%OUT%" (
  echo Saved: %OUT%
) else (
  echo ERROR: dump file was not created.
)
echo.
echo Leave this window open and send a screenshot, or continue in chat.
pause
