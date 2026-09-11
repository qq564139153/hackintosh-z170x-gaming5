@echo off
setlocal EnableExtensions
title Dump current GPU VBIOS
color 0A

set "ROOT=%~dp0"
set "TOOLDIR=%ROOT%AMDVBFlash-classic-3.31"
set "OUT=%ROOT%roms\RX580-from-card.rom"

if not exist "%TOOLDIR%\amdvbflash.exe" (
  echo ERROR: missing amdvbflash.exe
  pause
  exit /b 1
)
if not exist "%ROOT%roms" mkdir "%ROOT%roms"

cd /d "%TOOLDIR%"
echo ============================================================
echo  Dump VBIOS currently stored on the GPU
echo  Tool: AMDVBFlash-classic-3.31 (3.31 EXTERNAL)
echo  Output: %OUT%
echo ============================================================
echo.
echo Run as Administrator. Type YES to continue.
set /p CONFIRM=Confirm: 
if /I not "%CONFIRM%"=="YES" (
  echo Aborted.
  pause
  exit /b 2
)

echo [1/2] Ensure AMDVBFlash driver is installed
start /wait "" "%TOOLDIR%\AMDVBFlashDriverInstaller.exe"

echo [2/2] List adapters, then save ROM from adapter 0
amdvbflash.exe -i
amdvbflash.exe -s 0 "%OUT%"

echo.
if exist "%OUT%" (
  echo Saved: %OUT%
) else (
  echo ERROR: dump file was not created.
)
pause
exit /b 0
