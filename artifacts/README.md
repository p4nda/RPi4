## RPi4 EDK2 UEFI with latest Raspberry PI firmware

Supports booting from NVMe drive on CM4

### Fix EFI boot

In UEFI Shell [F1]:
```sh
Shell> map
Shell> FS0:
Shell> bcfg boot add 0 FS0:\EFI\fedora\grubaa64.efi "Fedora Server"
Shell> reset
```

### Bootable images (tested)
- 2024-02-03: [Fedora-Server-dvd-aarch64-39-1.5.iso](https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/aarch64/iso/Fedora-Server-dvd-aarch64-39-1.5.iso)
- 2023-12-27: [Fedora-Server-dvd-aarch64-Rawhide-20231226.n.0.iso](https://mirrors.hostiserver.com/fedora/fedora/linux/development/rawhide/Server/aarch64/iso/Fedora-Server-dvd-aarch64-Rawhide-20231226.n.0.iso)

Note: NVMe drives may work in Devicetree/ACPI+Devicetree mode, but not in ACPI-only mode.
Go to UEFI settings -> Advanced and set the correct mode, disable 3 GB limit if needed.

### Useful links
- https://qiot-project.github.io/blog/rhel9-on-arm8/
- https://www.eisfunke.com/posts/2023/uefi-boot-on-raspberry-pi-3.html
- https://notenoughtech.com/raspberry-pi/it-took-me-2-months-to-boot-cm4-from-nvme/
