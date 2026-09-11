@echo off
setlocal EnableExtensions
title FLASH Dataland RX570 212488 FULL ROM - HIGH RISK
color 0C

set "ROOT=%~dp0"
set "TOOLDIR=%ROOT%AMDVBFlash-classic-3.31"
set "ROM=%ROOT%roms\RX570-212488.rom"
set "ORIG=%ROOT%roms\RX580-original.rom"
set "DUMP_BEFORE=%ROOT%roms\RX580-from-card-before-212488.rom"
set "DUMP_AFTER=%ROOT%roms\RX580-after-212488.rom"
set "LOG=%ROOT%flash-212488-log.txt"

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
if not exist "%ORIG%" (
  echo ERROR: missing original backup %ORIG%
  pause
  exit /b 1
)

cd /d "%TOOLDIR%"
echo ==== flash 212488 start %DATE% %TIME% ==== > "%LOG%"
echo TOOLDIR=%TOOLDIR%>> "%LOG%"
echo ROM=%ROM%>> "%LOG%"

echo ============================================================
echo  WARNING: FULL crossflash to Dataland RX570 #212488
echo  This is NOT an ID-only patch of your PowerColor dump.
echo  Risk: HDMI black screen / no display (seen before on this PC).
echo  Rescue: restore_original.bat + iGPU / RDP / dual-BIOS.
echo  ROM : %ROM%
echo  Backup original must stay: %ORIG%
echo ============================================================
echo.
echo Type YES in capitals to continue, anything else aborts.
set /p CONFIRM=Confirm flash: 
if /I not "%CONFIRM%"=="YES" (
  echo Aborted by user.
  echo aborted>> "%LOG%"
  pause
  exit /b 2
)

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

echo.>> "%LOG%"
echo === DUMP BEFORE ===>> "%LOG%"
amdvbflash.exe -s 0 "%DUMP_BEFORE%" >> "%LOG%" 2>&1
amdvbflash.exe -s 0 "%DUMP_BEFORE%"

echo.>> "%LOG%"
echo === UNLOCK ===>> "%LOG%"
amdvbflash.exe -unlockrom 0 >> "%LOG%" 2>&1
amdvbflash.exe -unlockrom 0

echo.>> "%LOG%"
echo === FLASH FULL 212488 ===>> "%LOG%"
echo Programming. DO NOT power off.
amdvbflash.exe -f -p 0 "%ROM%" >> "%LOG%" 2>&1
amdvbflash.exe -f -p 0 "%ROM%"
echo flash exit=%ERRORLEVEL%>> "%LOG%"

echo.>> "%LOG%"
echo === DUMP AFTER ===>> "%LOG%"
amdvbflash.exe -s 0 "%DUMP_AFTER%" >> "%LOG%" 2>&1
amdvbflash.exe -s 0 "%DUMP_AFTER%"
echo ==== flash 212488 end %DATE% %TIME% ====>> "%LOG%"

echo.
echo Done if programmed+verified above.
echo NEXT: Shut down, cut PSU power ~10 seconds, then boot.
echo If black screen: use iGPU/RDP and run restore_original.bat
echo Log: %LOG%
pause
exit /b 0
