@echo off
cd /d "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash"
echo === DRIVER INSTALL === > "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\driver-out.txt"
AMDVBFlashDriverInstaller.exe >> "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\driver-out.txt" 2>&1
echo DRIVER_EXIT=%ERRORLEVEL% >> "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\driver-out.txt"
echo Y| amdvbflash.exe --version > "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\probe-out.txt" 2>&1
echo ==== >> "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\probe-out.txt"
echo Y| amdvbflash.exe -i >> "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\probe-out.txt" 2>&1
echo EXIT=%ERRORLEVEL% >> "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\probe-out.txt"
echo ==== BIOS FILE INFO ==== >> "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\probe-out.txt"
echo Y| amdvbflash.exe --bios-file-info "..\roms\RX580_rx570_patched_fixed.rom" >> "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\probe-out.txt" 2>&1
