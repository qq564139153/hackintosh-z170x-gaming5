@echo off
setlocal EnableExtensions
title RX580 VBIOS flash ID-only 67FF
color 0A

set "ROOT=%~dp0"
set "TOOLDIR=%ROOT%AMDVBFlash-classic-3.31"
set "ROM=%ROOT%roms\RX580_idonly_67ff_fixed.rom"
set "DUMP_BEFORE=%ROOT%roms\RX580-from-card.rom"
set "DUMP_AFTER=%ROOT%roms\RX580-after-flash.rom"
set "LOG=%ROOT%flash-log.txt"

if not exist "%TOOLDIR%\amdvbflash.exe" (
  echo ERROR: missing %TOOLDIR%\amdvbflash.exe
  exit /b 1
)
if not exist "%ROM%" (
  echo ERROR: missing %ROM%
  exit /b 1
)

cd /d "%TOOLDIR%"
echo ==== flash start %DATE% %TIME% ==== > "%LOG%"
echo TOOLDIR=%TOOLDIR%>> "%LOG%"
echo ROM=%ROM%>> "%LOG%"

echo ============================================================
echo  Classic AMDVBFlash 3.31 EXTERNAL - ID-only RX570 67FF
echo  Flash: %ROM%
echo ============================================================

echo.>> "%LOG%"
echo === DRIVER ===>> "%LOG%"
start /wait "" "%TOOLDIR%\AMDVBFlashDriverInstaller.exe"
echo driver installer finished>> "%LOG%"

echo.>> "%LOG%"
echo === LIST ===>> "%LOG%"
amdvbflash.exe -i >> "%LOG%" 2>&1
amdvbflash.exe -i
findstr /C:"3.31 EXTERNAL" "%LOG%" >nul
if errorlevel 1 (
  echo ERROR: not 3.31 EXTERNAL. Abort.
  echo ERROR: not 3.31 EXTERNAL>> "%LOG%"
  pause
  exit /b 3
)
findstr /C:"6FDF" "%LOG%" >nul
if errorlevel 1 (
  echo ERROR: adapter is not 6FDF. Abort to avoid double-flash.
  echo ERROR: adapter is not 6FDF>> "%LOG%"
  pause
  exit /b 4
)

echo.>> "%LOG%"
echo === DUMP BEFORE ===>> "%LOG%"
amdvbflash.exe -s 0 "%DUMP_BEFORE%" >> "%LOG%" 2>&1
amdvbflash.exe -s 0 "%DUMP_BEFORE%"

echo.>> "%LOG%"
echo === UNLOCK ===>> "%LOG%"
amdvbflash.exe -unlockrom 0 >> "%LOG%" 2>&1
amdvbflash.exe -unlockrom 0

echo.>> "%LOG%"
echo === FLASH ===>> "%LOG%"
echo Programming ID-only 67FF. DO NOT power off.
amdvbflash.exe -p 0 "%ROM%" >> "%LOG%" 2>&1
amdvbflash.exe -p 0 "%ROM%"
echo flash exit=%ERRORLEVEL%>> "%LOG%"

echo.>> "%LOG%"
echo === DUMP AFTER ===>> "%LOG%"
amdvbflash.exe -s 0 "%DUMP_AFTER%" >> "%LOG%" 2>&1
amdvbflash.exe -s 0 "%DUMP_AFTER%"
echo ==== flash end %DATE% %TIME% ====>> "%LOG%"
echo Done. Shut down, cut PSU 10 seconds, then boot.
echo GPU-Z Device ID should be 67FF.
pause
exit /b 0
