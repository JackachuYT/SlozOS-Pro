#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Build the SlozOS Pro ISO by remastering Zorin OS Core.
#
#   sudo build/remaster.sh <workdir> <version>
#
#   1. download the pinned Zorin OS Core ISO and check its SHA256
#   2. unpack the live system (casper/filesystem.squashfs)
#   3. run build/customize.sh inside it (chroot): SlozOS Pro design, apps,
#      branding — see that script
#   4. repack the live system, refresh the live boot files
#   5. write a new ISO that boots exactly like the original (xorriso replays
#      Zorin's BIOS + UEFI boot setup), named SlozOS-Pro-<version>-amd64.iso
#
# Runs on Ubuntu 24.04 (the same base as Zorin OS 18), as root.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

WORK=${1:?workdir}
VERSION=${2:?version}
CTX=$(cd "$(dirname "$0")/.." && pwd)
source "$CTX/build/zorin.env"
OUT="$WORK/SlozOS-Pro-$VERSION-amd64.iso"
ROOT="$WORK/root"
ISO="$WORK/iso"

log() { echo "::group::$*"; }
end() { echo "::endgroup::"; }

mkdir -p "$WORK"

# ── 1. Zorin OS Core ─────────────────────────────────────────────────────────
log "Download Zorin OS Core"
if [[ ! -f $WORK/zorin.iso ]] || ! echo "$ZORIN_SHA256  $WORK/zorin.iso" | sha256sum -c --quiet -; then
    curl -fL --retry 5 -o "$WORK/zorin.iso" "$ZORIN_URL"
    echo "$ZORIN_SHA256  $WORK/zorin.iso" | sha256sum -c -
fi
end

# ── 2. Unpack ────────────────────────────────────────────────────────────────
log "Unpack"
rm -rf "$ROOT" "$ISO"
mkdir -p "$ISO"
xorriso -osirrox on -indev "$WORK/zorin.iso" -extract / "$ISO" 2>/dev/null
chmod -R u+w "$ISO"
unsquashfs -q -d "$ROOT" "$ISO/casper/filesystem.squashfs"
rm -f "$ISO/casper/filesystem.squashfs" "$ISO/casper/filesystem.squashfs.gpg"
end

# ── 3. Customise (chroot) ────────────────────────────────────────────────────
log "Customise"
cleanup() {
    for d in ctx run sys proc dev/pts dev; do
        mountpoint -q "$ROOT/$d" && umount -l "$ROOT/$d"
    done
}
trap cleanup EXIT
for d in dev dev/pts proc sys run; do mount --bind "/$d" "$ROOT/$d"; done
mkdir -p "$ROOT/ctx" && mount --bind "$CTX" "$ROOT/ctx"
# name resolution inside the chroot (the live system's own resolv.conf is a
# systemd-resolved symlink that doesn't resolve here)
mv "$ROOT/etc/resolv.conf" "$ROOT/etc/resolv.conf.slozos-orig"
cp /etc/resolv.conf "$ROOT/etc/resolv.conf"

chroot "$ROOT" env DEBIAN_FRONTEND=noninteractive SLOZOS_PRO_VERSION="$VERSION" \
    bash /ctx/build/customize.sh

rm -f "$ROOT/etc/resolv.conf"
mv "$ROOT/etc/resolv.conf.slozos-orig" "$ROOT/etc/resolv.conf"
cleanup
rmdir "$ROOT/ctx"
trap - EXIT
end

# ── 4. Repack the live system ────────────────────────────────────────────────
log "Repack"
# Live boot files: customize.sh rebuilt the initramfs (new boot splash), the
# kernel itself is held at Zorin's version
KVER=$(ls "$ROOT/lib/modules" | sort -V | tail -1)
cp "$ROOT/boot/vmlinuz-$KVER" "$ISO/casper/vmlinuz"
cp "$ROOT/boot/initrd.img-$KVER" "$ISO/casper/initrd.zstd"

chroot "$ROOT" dpkg-query -W --showformat='${Package} ${Version}\n' > "$ISO/casper/filesystem.manifest"
du -sx --block-size=1 "$ROOT" | cut -f1 > "$ISO/casper/filesystem.size"
mksquashfs "$ROOT" "$ISO/casper/filesystem.squashfs" -noappend -comp xz -b 1M -Xdict-size 100% \
    -wildcards -e 'proc/*' 'sys/*' 'dev/*' 'run/*' 'tmp/*'
end

# ── 5. Boot menus, disk info, ISO ────────────────────────────────────────────
log "ISO"
bash "$CTX/build/iso-branding.sh" "$ISO" "$VERSION"

# "Check disc for defects" reads this
(cd "$ISO" && find . -type f ! -name md5sum.txt ! -name boot.cat -print0 | sort -z | xargs -0 md5sum > md5sum.txt)

# Same boot setup as Zorin's ISO: xorriso reports the exact mkisofs options
# it was made with (BIOS isolinux, UEFI image in an appended GPT partition,
# hybrid MBR). The UEFI partition and MBR are copied from Zorin's ISO by
# reference (--interval:local_fs:…), everything else comes from our tree.
BOOT_OPTS=$(xorriso -indev "$WORK/zorin.iso" -report_el_torito as_mkisofs 2>/dev/null \
    | grep -v -e '^-V ' -e '^--modification-date=')
echo "$BOOT_OPTS"
# the boot catalog is written fresh
rm -f "$ISO/isolinux/boot.cat" "$ISO/boot.catalog"
rm -f "$OUT"
eval "xorriso -as mkisofs -r -J -joliet-long -V 'SlozOS Pro $VERSION' -o '$OUT' $(echo "$BOOT_OPTS" | tr '\n' ' ') '$ISO'"
ls -lh "$OUT"
end
