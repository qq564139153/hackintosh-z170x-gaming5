Description
===========
AMDVBFLASH is a console utility for AMD GPU devices in a diagnostics environment providing the ability to flash the VBIOS.

Installation and launch
=======================
This package was created by W1zzard at TechPowerUp (www.techpowerup.com)

The normal AMDVBFLASH distribution only works after installation of the software on your system, and it will install a permanently running Ring-0 kernel mode driver, which is a security risk.

The version in this archive is distributed as a portable package that does not require any such installation.

Due to how AMD designed AMDVBFLASH, you have to run AMDVBFlashDriverInstaller.exe first, which installs the driver that AMDVBFLASH requires for hardware access. 
This driver is independent and separate from your "graphics driver".

Once you are finished with flashing, run AMDVBFlashDriverInstaller.exe again, to stop and uninstall the driver.

Documentation
=============
See the included PDF, or start AMDVBFLASH with -h option.