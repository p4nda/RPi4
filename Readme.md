Build Raspberry Pi 4 UEFI Firmware from source
==============================================

# Summary

2023-12-29: This repository aims to generate the latest installable builds of the official [EDK2 Raspberry Pi 4 UEFI firmware](https://github.com/tianocore/edk2-platforms/tree/master/Platform/RaspberryPi/RPi4).
Please note that the success of the build is not guaranteed, as some submodules or submodule dependencies may fetch more recent versions.

## Initial Notice

__PLEASE READ THE FOLLOWING:__

* This firmware build does not provide WiFi and BT Raspberry Pi overlays.
* Secure boot is WIP and does not work by default, setup the keys manually.
* TFTP command and ISCSI network boot is disabled.
> BUILD_FLAGS="-D RPI_MODEL=4 -D SECURE_BOOT_ENABLE=TRUE -D INCLUDE_TFTP_COMMAND=FALSE -D NETWORK_ISCSI_ENABLE=FALSE

* Many drivers (GPIO, VPU, etc) are still likely to be missing from your OS, and will
  have to be provided by a third party. Please do not ask for them here, as they fall
  outside of the scope of this project.

* A 3GB RAM limit is __~~disabled~~ by default__, but requires running more recent kernel,  
  for Linux this usually translates to using a recent kernel (version 5.8 or later) and
  for Windows this requires the installation of a filter driver.
* This firmware is based on the fork of
  [EDK2 repository](https://github.com/p4nda/edk2-platforms/tree/release/1.36-beta/Platform/RaspberryPi/RPi4),
  with the following extra patch applied:
  * `0001-MdeModulePkg-UefiBootManagerLib-Signal-ReadyToBoot-o.patch`
  * `0002-Check-for-Boot-Discovery-Policy-change.patch`

## Usage

```sh
BRANCH_NAME="1.36-beta-update-20240203"
ARTIFACTS_DIR="RPi4_UEFI_${BRANCH_NAME}"
mkdir ${ARTIFACTS_DIR}
chmod 777 ${ARTIFACTS_DIR}
# Build the firmware
podman build --squash --build-arg BRANCH=${BRANCH_NAME} -t localhost/ndf-uefi-rpi4:latest .
podman run --rm -it -v ${ARTIFACTS_DIR}:/artifacts:Z localhost/ndf-uefi-rpi4:latest
# Fix permissions on artifacts
find ${ARTIFACTS_DIR} -type d -exec chmod 750 {} +
find ${ARTIFACTS_DIR} -type f -exec chmod 640 {} +
sudo chown -R ${USER}:${USER} ${ARTIFACTS_DIR}
cd ${ARTIFACTS_DIR}/artifacts && ls -la
```

## License

The firmware (`RPI_EFI.fd`) is licensed under the current EDK2 license, which is
[BSD-2-Clause-Patent](https://github.com/tianocore/edk2/blob/master/License.txt).

The other files from the zip archives are licensed under the terms described in the
[Raspberry Pi boot files README](https://github.com/raspberrypi/firmware/blob/master/README.md).

The binary blobs in the `firmware/` directory are licensed under the Cypress wireless driver
license that is found there.
