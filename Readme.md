Build Raspberry Pi 4 UEFI Firmware from source
==============================================

# Summary

2023-12-29: This repository aims to generate the latest installable builds of the official [EDK2 Raspberry Pi 4 UEFI firmware](https://github.com/tianocore/edk2-platforms/tree/master/Platform/RaspberryPi/RPi4).
Please note that the success of the build is not guaranteed, as some submodules or submodule dependencies may fetch more recent versions.

## Initial Notice

__PLEASE READ THE FOLLOWING:__

* This firmware build does not provide WiFi and BT Raspberry Pi overlays.
* Secure boot is disabled, this may change in future release and is WIP.
> BUILD_FLAGS="-D RPI_MODEL=4 -D SECURE_BOOT_ENABLE=FALSE -D INCLUDE_TFTP_COMMAND=FALSE -D NETWORK_ISCSI_ENABLE=FALSE

* Many drivers (GPIO, VPU, etc) are still likely to be missing from your OS, and will
  have to be provided by a third party. Please do not ask for them here, as they fall
  outside of the scope of this project.

* A 3GB RAM limit is __disabled by default__, but requires running more recent kernel,  
  for Linux this usually translates to using a recent kernel (version 5.8 or later) and
  for Windows this requires the installation of a filter driver.
* This firmware is based on the fork of
  [EDK2 repository](https://github.com/p4nda/edk2-platforms/tree/release/1.36-beta/Platform/RaspberryPi/RPi4),
  with the following extra patch applied:
  * `0001-MdeModulePkg-UefiBootManagerLib-Signal-ReadyToBoot-o.patch`
  * `0002-Check-for-Boot-Discovery-Policy-change.patch`

## Usage

### Prepare destination folder
```sh
cd ~/ && mkdir RPi4_UEFI
IMAGE_DATE=$(date +'%Y%m%d%H%M')
ARTIFACTS_FOLDER_NAME="RPi4_UEFI_${IMAGE_DATE}"
mkdir ${ARTIFACTS_FOLDER_NAME}
sudo chmod 777 ${ARTIFACTS_FOLDER_NAME}
```

### Build the image and copy artifacts to destination
Run as normal non-root user
```sh
podman build --squash --build-arg VERSION=${IMAGE_DATE} -t localhost/ndf-uefi-rpi4:latest .
podman run --rm -it -v /home/${USER}/RPi4_UEFI_202312291434/:/artifacts:Z localhost/ndf-uefi-rpi4:latest
```
### Fix permissions on files produced by the image
```sh
sudo chown ${USER}:${USER} ${ARTIFACTS_FOLDER_NAME}
sudo chmod 640 ${ARTIFACTS_FOLDER_NAME}
cd ${ARTIFACTS_FOLDER_NAME}/artifacts && ls -la
```

## License

The firmware (`RPI_EFI.fd`) is licensed under the current EDK2 license, which is
[BSD-2-Clause-Patent](https://github.com/tianocore/edk2/blob/master/License.txt).

The other files from the zip archives are licensed under the terms described in the
[Raspberry Pi boot files README](https://github.com/raspberrypi/firmware/blob/master/README.md).

The binary blobs in the `firmware/` directory are licensed under the Cypress wireless driver
license that is found there.
