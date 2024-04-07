Build Raspberry Pi 4 UEFI Firmware from source
==============================================

# Summary

This repository aims to generate more recent installable builds of the official [EDK2 Raspberry Pi 4 UEFI firmware](https://github.com/tianocore/edk2-platforms/tree/master/Platform/RaspberryPi/RPi4).

Please note that the success of the build is not guaranteed, as some submodules or submodule dependencies may fetch more recent code.

## Initial Notice

__PLEASE READ THE FOLLOWING:__

* This firmware build does not provide WiFi and BT Raspberry Pi overlays, WiFi and BT is disabled in config-cm4.txt.

* Many drivers (GPIO, VPU, etc) are still likely to be missing from your OS, and will
  have to be provided by a third party. Please do not ask for them here, as they fall
  outside of the scope of this project.

* The following extra patch is applied:
  * `RPi4_disable_3GB_RAM_limit.patch`
  * `RPi4_set_system_table_ACPI+DeviceTree_by_default.patch`
  * `RPi4_increase_SD_card_default_speed_to_50_83.patch`
  * `RPi4_decrease_default_CpuLowSpeedMHz_to_600.patch`

> BUILD_FLAGS="-D RPI_MODEL=4 -D SECURE_BOOT_ENABLE=TRUE -D INCLUDE_TFTP_COMMAND=TRUE -D NETWORK_ENABLE=TRUE -D NETWORK_TLS_ENABLE=TRUE -D NETWORK_IP6_ENABLE=FALSE -D NETWORK_ISCSI_ENABLE=FALSE -D NETWORK_VLAN_ENABLE=FALSE -D NETWORK_IPSEC_ENABLE=FALSE -D SMC_PCI_SUPPORT=1"

## Usage

```sh
cd RPi4
BRANCH_NAME="1.37-beta-update-20240406"
ARTIFACTS_DIR="RPi4_UEFI_${BRANCH_NAME}"
mkdir "release/${ARTIFACTS_DIR}"
chmod 777 -R "release/${ARTIFACTS_DIR}"

# Build
podman build --squash --build-arg BRANCH=${BRANCH_NAME} -t localhost/ndf-uefi-rpi4:latest .

# Copy artifacts to attached volume dir
podman run --rm -it -v $PWD/release/${ARTIFACTS_DIR}:/artifacts:Z localhost/ndf-uefi-rpi4:latest

# Fix artifact permissions
sudo find "release/${ARTIFACTS_DIR}" -type d -exec chmod 750 {} +
sudo find "release/${ARTIFACTS_DIR}" -type f -exec chmod 640 {} +
sudo chown -R ${USER}:${USER} "release/${ARTIFACTS_DIR}"
cd "release/${ARTIFACTS_DIR}/artifacts" && ls -la
```

## License

The firmware (`RPI_EFI.fd`) is licensed under the current EDK2 license, which is
[BSD-2-Clause-Patent](https://github.com/tianocore/edk2/blob/master/License.txt).

The other files from the zip archives are licensed under the terms described in the
[Raspberry Pi boot files README](https://github.com/raspberrypi/firmware/blob/master/README.md).

The binary blobs in the `firmware/` directory are licensed under the Cypress wireless driver
license that is found there.
