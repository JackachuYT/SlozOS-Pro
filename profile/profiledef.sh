#!/usr/bin/env bash
# shellcheck disable=SC2034
# SlozOS Pro live ISO (archiso profile). Skeleton: Arch Linux's "releng"
# profile (GPL-3.0-or-later); desktop: pearOS NiceC0re packages; SlozOS Pro's
# own packages come from the local [slozos-pro] repo built by CI.

iso_name="SlozOS-Pro"
iso_label="SLOZOS_PRO_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="SlozOS <https://github.com/JackachuYT/SlozOS-Pro>"
iso_application="SlozOS Pro Live"
iso_version="${SLOZOS_PRO_VERSION:-dev}"
install_dir="arch"
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/sudoers.d/10-live"]="0:0:440"
  ["/usr/local/bin/slozos-pro-live-setup"]="0:0:755"
)
