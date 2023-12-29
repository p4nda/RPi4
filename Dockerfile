# Build RPi4 edk2 UEFI and include latest Raspberry PI firmware

ARG CONTAINER_NAME=firmware
ARG VERSION="1.36-beta"
ARG ARCHIVE_NAME="RPi4_UEFI_Firmware_${VERSION}.tar.gz"
ARG PROJECT_URL="https://github.com/p4nda/RPi4"
ARG GIT_BRANCH="release/1.36-beta"

# Download official RPi firmware
ARG RPI_FIRMWARE_URL=https://github.com/raspberrypi/firmware/
ARG RPI_FIRMWARE_BRANCH="next"
ARG START_ELF_VERSION=${RPI_FIRMWARE_BRANCH}
ARG DTB_VERSION=${RPI_FIRMWARE_BRANCH}
ARG DTBO_VERSION=${RPI_FIRMWARE_BRANCH}

ARG CONTAINER_GID=1001
ARG CONTAINER_UID=1001

FROM quay.io/rockylinux/rockylinux:9.3-minimal as build
ARG PROJECT_URL
ARG GIT_BRANCH
ARG VERSION
ARG ARCH
ARG COMPILER
ARG BUILD_TYPE

# Update the base image and install basic packages
RUN microdnf -y update && \
    microdnf -y install vim mc git curl wget zip findutils epel-release

# Install build dependencies
RUN set -eux; \
    microdnf install -y git make patch gcc-c++ gcc-aarch64-linux-gnu libuuid-devel acpica-tools openssl openssl-devel python

# Set the working directory
WORKDIR /usr/src/app

# Download the forked RPi4 edk2 repository from GitHub
RUN git clone --depth 1 -b ${GIT_BRANCH} ${PROJECT_URL} ./ && \
    git submodule update --init && \
    cd edk2 && \
    git submodule update --init

# Build EDK2 BaseTools
RUN set -exou pipefail; \
    make -C edk2/BaseTools && \
    mkdir keys

# Apply patch
RUN patch --binary -d edk2 -p1 -i ../0001-MdeModulePkg-UefiBootManagerLib-Signal-ReadyToBoot-o.patch
RUN patch --binary -d edk2-platforms -p1 -i ../0002-Check-for-Boot-Discovery-Policy-change.patch

# Build UEFI
RUN set -exou pipefail; \
    export WORKSPACE=$PWD && \
    export PACKAGES_PATH=$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi && \
    export BUILD_FLAGS="-D RPI_MODEL=4 -D SECURE_BOOT_ENABLE=FALSE -D INCLUDE_TFTP_COMMAND=FALSE -D NETWORK_ISCSI_ENABLE=FALSE -D SMC_PCI_SUPPORT=1" && \
    export DEFAULT_KEYS="-D DEFAULT_KEYS=TRUE -D PK_DEFAULT_FILE=$WORKSPACE/keys/pk.cer -D KEK_DEFAULT_FILE1=$WORKSPACE/keys/ms_kek.cer -D DB_DEFAULT_FILE1=$WORKSPACE/keys/ms_db1.cer -D DB_DEFAULT_FILE2=$WORKSPACE/keys/ms_db2.cer -D DBX_DEFAULT_FILE1=$WORKSPACE/keys/arm64_dbx.bin" && \
    export EDK_TOOLS_PATH=$WORKSPACE/edk2/BaseTools && \
    export CONF_PATH=$WORKSPACE/edk2/BaseTools/Conf && \
    export LD=/usr/bin/ld.bfd && \
    export ARCH=AARCH64 && \
    export COMPILER=GCC5 && \
    export GCC5_AARCH64_PREFIX=aarch64-linux-gnu- && \
    source edk2/edksetup.sh && \
    for BUILD_TYPE in RELEASE; do \
        build -a $ARCH -t $COMPILER -b $BUILD_TYPE -p edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc \
        --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVendor=L"${PROJECT_URL}" \
        --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString=L"UEFI Firmware ${VERSION}" \
        ${BUILD_FLAGS} ${DEFAULT_KEYS} ; \
    done && \
    mv Build/RPi4/${BUILD_TYPE}_${COMPILER}/FV/RPI_EFI.fd /usr/src/app/RPI_EFI.fd && \
    mv edk2-non-osi/Platform/RaspberryPi/RPi4/TrustedFirmware/bl31.bin /usr/src/app/bl31.bin

# ########################
#   Stage 2: Final image
# ########################
FROM quay.io/rockylinux/rockylinux:9.3-minimal as final
ARG CONTAINER_NAME
ARG ARCHIVE_NAME
ARG VERSION
ARG PROJECT_URL
ARG GIT_BRANCH
ARG RPI_FIRMWARE_URL
ARG RPI_FIRMWARE_BRANCH
ARG START_ELF_VERSION
ARG DTB_VERSION
ARG DTBO_VERSION
ARG CONTAINER_UID=1001
ARG CONTAINER_GID=1001

WORKDIR "/home/${CONTAINER_NAME}/artifacts"

RUN set -exou pipefail; \
    groupadd -g ${CONTAINER_GID} ${CONTAINER_NAME} && \
    useradd -u ${CONTAINER_UID} -g ${CONTAINER_GID} \
      -d /home/${CONTAINER_NAME} -s /bin/nologin \
      -c 'RPi4 UEFI Firmware Builder' ${CONTAINER_NAME} && \
    mkdir -p keys overlays DIST

COPY --from=build /usr/src/app/RPI_EFI.fd .
COPY --from=build /usr/src/app/bl31.bin .
COPY --from=build /usr/src/app/keys keys/

# ################################
#   Get latest raspberre firmware
# ################################

# Download latest version of compiled *.dtbo overlays
# https://github.com/raspberrypi/firmware/blob/next/boot/overlays/

RUN curl -O -L $RPI_FIRMWARE_URL/raw/$START_ELF_VERSION/boot/fixup4.dat && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$START_ELF_VERSION/boot/start4.elf && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTB_VERSION/boot/bcm2711-rpi-4-b.dtb && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTB_VERSION/boot/bcm2711-rpi-cm4.dtb && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTB_VERSION/boot/bcm2711-rpi-400.dtb && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/upstream-pi4.dtbo && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/dwc2.dtbo && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/dwc-otg.dtbo && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/miniuart-bt.dtbo && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/disable-bt.dtbo && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/disable-wifi.dtbo && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/disable-emmc.dtbo && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/vc4-kms-v3d-pi4.dtbo && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/cma.dtbo && \
    curl -O -L $RPI_FIRMWARE_URL/raw/$DTBO_VERSION/boot/overlays/pcie-32bit-dma.dtbo && \
    mv *.dtbo overlays/

# Include text files
COPY config-cm4.txt ./config-cm4-${VERSION}.txt
COPY Dockerfile \
    License.txt ./

# Create UEFI firmware archive
RUN echo -e "\n\tProject URL: ${PROJECT_URL}\n\tGit branch: ${GIT_BRANCH}\n\tRPi firmware URL: ${RPI_FIRMWARE_URL}\n\tRPi firmware branch: ${RPI_FIRMWARE_BRANCH}\n\tBuild number: ${VERSION}\n\tArchive name: ${ARCHIVE_NAME}" >> README.md && \
    microdnf install -y tar && \
    sha256sum RPI_EFI.fd >> RPI_EFI.fd.sha256 && \
    sha256sum bl31.bin >> bl31.bin.sha256 && \
    tar -czvf DIST/${ARCHIVE_NAME}  \
      RPI_EFI.fd RPI_EFI.fd.sha256 \
      bl31.bin bl31.bin.sha256 \
      *.dtb \
      fixup4.dat \
      start4.elf \
      config-cm4-${VERSION}.txt \
      Dockerfile \
      License.txt \
      overlays && \
    sha256sum DIST/${ARCHIVE_NAME} >> DIST/${ARCHIVE_NAME}.sha256 && \
    microdnf remove -y tar && microdnf clean all && \
    chown -R ${CONTAINER_UID}:0 /home/${CONTAINER_NAME} && \
    chmod -R 0755 /home/${CONTAINER_NAME}

# Get RPI_EFI.fd with latest RPi firmware
# mkdir /home/${USER}/RPi4_UEFI_${VERSION}
# podman run --rm -it -v /home/${USER}/RPi4_UEFI_${VERSION}:/artifacts:Z localhost/ndf-uefi-rpi4:latest
VOLUME ["/artifacts"]

USER ${CONTAINER_UID}
CMD ["/bin/bash", "-c", "cp -R ~/* /artifacts"]
