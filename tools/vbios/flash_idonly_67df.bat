@echo off
setlocal EnableExtensions
title RX580 VBIOS flash ID-only 67DF
color 0A

set "ROOT=%~dp0"
set "TOOLDIR=%ROOT%AMDVBFlash-classic-3.31"
set "ROM=%ROOT%roms\RX580_idonly_67df_fixed.rom"
set "DUMP_BEFORE=%ROOT%roms\RX580-from-card.rom"
set "DUMP_AFTER=%ROOT%roms\RX580-after-flash.rom"
set "LOG=%ROOT%flash-log.txt"

if not exist "%TOOLDIR%\amdvbflash.exe" (
  echo ERROR: missing %TOOLDIR%\amdvbflash.exe
  pause
  exit /b 1
)
if not exist "%ROM%" (
  echo ERROR: missing %ROM%
  pause
  exit /b 1
)

cd /d "%TOOLDIR%"
echo ==== flash start %DATE% %TIME% ==== > "%LOG%"
echo TOOLDIR=%TOOLDIR%>> "%LOG%"
echo ROM=%ROM%>> "%LOG%"

echo ============================================================
echo  Classic AMDVBFlash 3.31 EXTERNAL - ID-only 67DF
echo  Flash: %ROM%
echo  Log  : %LOG%
echo ============================================================
echo.
echo First line of -i MUST say: AMDVBFLASH version 3.31 EXTERNAL
echo If you see 5.0.xxx, STOP.
echo This ROM only changes Device ID 6FDF to 67DF. ASIC is unchanged.
echo.
pause

echo.
echo [1/5] Install AMDVBFlash driver
echo.>> "%LOG%"
echo === DRIVER ===>> "%LOG%"
start /wait "" "%TOOLDIR%\AMDVBFlashDriverInstaller.exe"
echo driver installer finished>> "%LOG%"

echo.
echo [2/5] List adapters
echo.>> "%LOG%"
echo === LIST ===>> "%LOG%"
amdvbflash.exe -i >> "%LOG%" 2>&1
amdvbflash.exe -i
echo.
echo Adapter is usually 0. Current Device ID should still be 6FDF.
pause

echo.
echo [3/5] Dump current VBIOS from card
echo.>> "%LOG%"
echo === DUMP BEFORE ===>> "%LOG%"
amdvbflash.exe -s 0 "%DUMP_BEFORE%" >> "%LOG%" 2>&1
amdvbflash.exe -s 0 "%DUMP_BEFORE%"
echo Saved: %DUMP_BEFORE%
pause

echo.
echo [4/5] Unlock + flash ID-only 67DF ROM
echo Type YES to continue (power must stay on).
set /p CONFIRM=Type YES then Enter: 
if /I not "%CONFIRM%"=="YES" (
  echo Aborted. Nothing flashed.>> "%LOG%"
  echo Aborted.
  pause
  exit /b 2
)

echo.>> "%LOG%"
echo === UNLOCK ===>> "%LOG%"
echo Unlocking ROM...
amdvbflash.exe -unlockrom 0 >> "%LOG%" 2>&1
amdvbflash.exe -unlockrom 0

echo.>> "%LOG%"
echo === FLASH ===>> "%LOG%"
echo Programming... DO NOT power off.
amdvbflash.exe -p 0 "%ROM%" >> "%LOG%" 2>&1
amdvbflash.exe -p 0 "%ROM%"
set "FLASHERR=%ERRORLEVEL%"
echo flash exit=%FLASHERR%>> "%LOG%"

echo.
echo [5/5] Dump after flash
echo.>> "%LOG%"
echo === DUMP AFTER ===>> "%LOG%"
amdvbflash.exe -s 0 "%DUMP_AFTER%" >> "%LOG%" 2>&1
amdvbflash.exe -s 0 "%DUMP_AFTER%"
echo Saved: %DUMP_AFTER%
echo.
echo ==== flash end %DATE% %TIME% ====>> "%LOG%"
echo.
echo Next: shut down PC, cut PSU power 10 seconds, then boot.
echo Check GPU-Z Device ID = 67DF (not 6FDF).
echo Log saved to: %LOG%
echo.
pause
