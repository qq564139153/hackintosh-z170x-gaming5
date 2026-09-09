cd /d "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash"
amdvbflash.exe --version > "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\probe-out.txt" 2>&1
echo ==== >> "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\probe-out.txt"
amdvbflash.exe -i >> "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\probe-out.txt" 2>&1
echo EXIT=%ERRORLEVEL% >> "C:\Users\sean\project-code\hackintosh\tools\vbios\AMDVBFlash\probe-out.txt"
