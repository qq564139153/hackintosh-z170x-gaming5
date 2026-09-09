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

Prerequisite steps before running the tool
===========================================
- Please make sure to always initiate IFWI flash after fresh reboot. Tool needs the required FW to be in expected status, so triggering flash via tool after clean reboot of system is a must.
- There are 2 partitions in each SPIROM (on newer GPUs), so to flash the IFWI completely on both partition, please make sure we initiate the flash process twice. Steps to be followed:
	I.) Initiate flash using the desired IFWI.
	II.) After flashing is complete, reboot the system.
	III.) Once system boots up, reinitiate the flash using same IFWI (similar step and command as I. above)
	IV.) After flashing is complete, reboot the system again. We would have now flashed both the SPIROM partitions with same IFWI.
- Please make sure to always use the properly SIGNED IFWI file only for flashing, which is officially released. Otherwise using unsigned/corrupted IFWI may lead to erasing the entire partition in SPIROM.
- Refer to Known Issues section for initiating flash via tool on WINDOWS with AMD Graphics driver installed. No dependency on Linux systems.