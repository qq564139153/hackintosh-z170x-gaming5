@echo off
setlocal EnableExtensions
title FLASH v20 (TPU 212488 SSID 2392) - proven boot
color 0C

set "ROOT=%~dp0"
set "TOOLDIR=%ROOT%AMDVBFlash-classic-3.31"
set "ROM=%ROOT%roms\v20_tpu212488_ssid2392.rom"
set "STOCK=%ROOT%roms\v00_stock_6FDF_ssid2392.rom"
set "DUMP_BEFORE=%ROOT%roms\dump-before-v20.rom"
set "DUMP_AFTER=%ROOT%roms\dump-after-v20.rom"
set "LOG=%ROOT%flash-v20-ssid2392-log.txt"

if not exist "%TOOLDIR%\amdvbflash.exe" (
  echo ERROR: missing amdvbflash.exe
  pause
  exit /b 1
)
if not exist "%ROM%" (
  echo ERROR: missing %ROM%
  pause
  exit /b 1
)
if not exist "%STOCK%" (
  echo ERROR: missing stock backup
  pause
  exit /b 1
)

cd /d "%TOOLDIR%"
echo ==== flash v20 ssid2392 start %DATE% %TIME% ==== > "%LOG%"
echo ROM=%ROM%>> "%LOG%"

echo ============================================================
echo  FLASH v20: Dataland TPU #212488 with SSID forced to 2392
echo  Proven boot on this card. Default clock ~1244 MHz.
echo  Rescue: restore_v00_stock.bat
echo  ROM : %ROM%
echo ============================================================
echo.
echo Type YES to continue.
set /p CONFIRM=Confirm: 
if /I not "%CONFIRM%"=="YES" (
  echo Aborted.
  echo aborted>> "%LOG%"
  pause
  exit /b 2
)

echo === DRIVER ===>> "%LOG%"
start /wait "" "%TOOLDIR%\AMDVBFlashDriverInstaller.exe"

echo === LIST ===>> "%LOG%"
amdvbflash.exe -i >> "%LOG%" 2>&1
amdvbflash.exe -i
findstr /C:"3.31 EXTERNAL" "%LOG%" >nul
if errorlevel 1 (
  echo ERROR: not 3.31 EXTERNAL. Abort.
  pause
  exit /b 3
)

echo === DUMP BEFORE ===>> "%LOG%"
amdvbflash.exe -s 0 "%DUMP_BEFORE%" >> "%LOG%" 2>&1
amdvbflash.exe -s 0 "%DUMP_BEFORE%"

echo === UNLOCK ===>> "%LOG%"
amdvbflash.exe -unlockrom 0 >> "%LOG%" 2>&1
amdvbflash.exe -unlockrom 0

echo === FLASH no -f, SSID already 2392 ===>> "%LOG%"
echo Programming. DO NOT power off.
amdvbflash.exe -p 0 "%ROM%" >> "%LOG%" 2>&1
amdvbflash.exe -p 0 "%ROM%"
echo flash exit=%ERRORLEVEL%>> "%LOG%"

echo === DUMP AFTER ===>> "%LOG%"
amdvbflash.exe -s 0 "%DUMP_AFTER%" >> "%LOG%" 2>&1
amdvbflash.exe -s 0 "%DUMP_AFTER%"
echo ==== end %DATE% %TIME% ====>> "%LOG%"

echo.
echo If programmed+verified: shutdown, cut PSU 10s, boot.
echo If black screen: iGPU/RDP then restore_v00_stock.bat
echo Log: %LOG%
pause
exit /b 0
