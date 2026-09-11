@echo off
setlocal EnableExtensions
title RX580 restore v00 STOCK VBIOS
color 0C

set ROOT=%~dp0
set TOOLDIR=%ROOT%AMDVBFlash-classic-3.31
set LOG=%ROOT%restore-v00-log.txt
set DUMP_AFTER=%ROOT%roms\dump-after-v00-restore.rom
set ROM=%ROOT%roms\v00_stock_6FDF_ssid2392.rom

if not exist "%TOOLDIR%\amdvbflash.exe" (
  echo ERROR: missing amdvbflash.exe
  pause
  exit /b 1
)
if not exist "%ROM%" (
  echo ERROR: missing stock ROM
  echo %ROM%
  pause
  exit /b 1
)

cd /d "%TOOLDIR%"
echo ==== restore v00 start %DATE% %TIME% ==== > "%LOG%"
echo TOOLDIR=%TOOLDIR%>> "%LOG%"
echo ROM=%ROM%>> "%LOG%"

echo ============================================================
echo  RESTORE v00 stock RX 580 2048SP VBIOS
echo  ROM : %ROM%
echo  Log : %LOG%
echo ============================================================
echo First line of -i MUST say: AMDVBFLASH version 3.31 EXTERNAL
echo If you see 5.0.xxx, STOP.
echo After restore, Device ID should be 6FDF again.
pause

echo [1/4] Install AMDVBFlash driver
echo === DRIVER ===>> "%LOG%"
start /wait "" "%TOOLDIR%\AMDVBFlashDriverInstaller.exe"
echo driver installer finished>> "%LOG%"

echo [2/4] List adapters
echo === LIST ===>> "%LOG%"
amdvbflash.exe -i >> "%LOG%" 2>&1
amdvbflash.exe -i
echo Adapter is usually 0. Confirm Polaris20 row.
pause

echo [3/4] Unlock + flash STOCK ROM
set /p CONFIRM=Type YES then Enter: 
if /I not "%CONFIRM%"=="YES" (
  echo Aborted. Nothing flashed.>> "%LOG%"
  echo Aborted.
  pause
  exit /b 2
)

echo === UNLOCK ===>> "%LOG%"
echo Unlocking ROM...
amdvbflash.exe -unlockrom 0 >> "%LOG%" 2>&1
amdvbflash.exe -unlockrom 0

echo === FLASH STOCK ===>> "%LOG%"
echo Programming stock VBIOS. DO NOT power off.
amdvbflash.exe -p 0 "%ROM%" >> "%LOG%" 2>&1
amdvbflash.exe -p 0 "%ROM%"
echo flash exit=%ERRORLEVEL%>> "%LOG%"

echo [4/4] Dump after restore
echo === DUMP AFTER ===>> "%LOG%"
amdvbflash.exe -s 0 "%DUMP_AFTER%" >> "%LOG%" 2>&1
amdvbflash.exe -s 0 "%DUMP_AFTER%"
echo Saved: %DUMP_AFTER%
echo ==== restore end %DATE% %TIME% ====>> "%LOG%"
echo Next: shut down, cut PSU power 10 seconds, then boot.
echo Plug monitor back into the GPU. GPU-Z Device ID should be 6FDF.
echo Log saved to: %LOG%
pause
