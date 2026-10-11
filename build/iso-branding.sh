#!/usr/bin/env bash
# SlozOS Pro names on the ISO itself: boot menus, boot-menu theme, disc info.
#   iso-branding.sh <unpacked iso dir> <version>
set -euo pipefail
ISO=${1:?}; VERSION=${2:?}
CTX=$(cd "$(dirname "$0")/.." && pwd)

# GRUB (UEFI) and isolinux (BIOS) menus
for f in "$ISO/boot/grub/grub.cfg" "$ISO/boot/grub/loopback.cfg" "$ISO"/isolinux/*.cfg; do
    [[ -f $f ]] || continue
    sed -i -e 's/Zorin OS/SlozOS Pro/g' -e 's/--class zorin/--class slozos-pro/g' \
           -e 's|/boot/grub/themes/zorin/|/boot/grub/themes/slozos-pro/|g' "$f"
done
# The live NVIDIA option keeps Zorin's kernel parameter (nvidia-zorin is
# handled by Zorin's nvidia-zorin-live package inside the live system)
sed -i 's/(modern NVIDIA drivers)/(NVIDIA graphics)/' "$ISO/boot/grub/grub.cfg"

# Boot-menu theme: same layout as the installed system's
rm -rf "$ISO/boot/grub/themes/zorin"
mkdir -p "$ISO/boot/grub/themes/slozos-pro"
cp "$CTX"/packaging/root/usr/share/grub/themes/slozos-pro/* "$ISO/boot/grub/themes/slozos-pro/"
cp "$CTX/assets/brand/grub-background.png" "$ISO/boot/grub/themes/slozos-pro/background.png"

# Disc info (shown by the live session's "Try or Install" screen)
echo "SlozOS-Pro $VERSION 64bit" > "$ISO/.disk/info"
[[ -f $ISO/README.diskdefines ]] && sed -i 's/Zorin[- ]OS[^ ]*/SlozOS-Pro/g' "$ISO/README.diskdefines"
grep -rl 'Zorin' "$ISO/boot/grub/grub.cfg" "$ISO/.disk" 2>/dev/null && { echo "Zorin names left on the ISO"; exit 1; }
exit 0
