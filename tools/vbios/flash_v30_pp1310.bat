@echo off
setlocal EnableExtensions
title FLASH v30 pp1310 (212488 ssid2392 + stock clocks/TDP)
color 0C

set "ROOT=%~dp0"
set "TOOLDIR=%ROOT%AMDVBFlash-classic-3.31"
set "ROM=%ROOT%roms\v30_tpu212488_ssid2392_pp1310.rom"
set "STOCK=%ROOT%roms\v00_stock_6FDF_ssid2392.rom"
set "DUMP_BEFORE=%ROOT%roms\dump-before-v30.rom"
set "DUMP_AFTER=%ROOT%roms\dump-after-v30.rom"
set "LOG=%ROOT%flash-v30-pp1310-log.txt"

if not exist "%TOOLDIR%\amdvbflash.exe" (
  echo ERROR: missing amdvbflash.exe
  pause
  exit /b 1
)
if not exist "%ROM%" (
  echo ERROR: missing %ROM%
  echo Run: python build_v30_pp1310.py
  pause
  exit /b 1
)
if not exist "%STOCK%" (
  echo ERROR: missing stock backup
  pause
  exit /b 1
)

cd /d "%TOOLDIR%"
echo ==== flash v30 pp1310 start %DATE% %TIME% ==== > "%LOG%"
echo ROM=%ROM%>> "%LOG%"

echo ============================================================
echo  FLASH v30: TPU #212488 + SSID 2392 + stock SCLK/TDP
echo  Target: GPU default clock 1310 MHz, TDP 145 W
echo  Base still 67DF / foreign board tables - risk of black screen
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

echo === FLASH no -f ===>> "%LOG%"
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
echo GPU-Z should show Default Clock 1310 MHz, Device 67DF.
echo If black screen: iGPU/RDP then restore_v00_stock.bat
echo Log: %LOG%
pause
exit /b 0
