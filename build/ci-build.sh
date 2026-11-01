#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# CI: build the SlozOS Pro ISO inside an archlinux container.
#
#   docker run --privileged -v "$PWD:/src" -v /mnt/work:/work archlinux:latest \
#       bash /src/build/ci-build.sh <version> <pkgrel>
#
# Output in /work/out: the ISO and SlozOS Pro's packages.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
VERSION=${1:?version}; PKGREL=${2:-1}
CTX=/src; OUT=/work/out
REPO=/var/cache/slozos-pro-repo

echo "::group::pacman + keys"
cat > /etc/pacman.d/mirrorlist <<'MIR'
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
MIR
pacman-key --init
pacman-key --populate archlinux
pacman-key --add "$CTX/profile/pearos.gpg" && pacman-key --lsign-key 4C1A9F3C131ACA95
pacman-key --add "$CTX/profile/inled.gpg"  && pacman-key --lsign-key 89F828A9675B63CD0077CE9965AA57CF36E2018F
# CachyOS's key comes in its keyring package, which pearOS's repo carries
cat > /tmp/bootstrap.conf <<'CONF'
[options]
Architecture = auto
SigLevel = Required DatabaseOptional
[core]
Include = /etc/pacman.d/mirrorlist
[extra]
Include = /etc/pacman.d/mirrorlist
[pearos]
Server = https://mirror.pearos.xyz/main/$arch/
CONF
pacman -Sy --noconfirm --config /tmp/bootstrap.conf cachyos-keyring
pacman-key --populate cachyos
pacman -Syu --noconfirm archiso base-devel git python sudo
echo "::endgroup::"

bash "$CTX/build/build-packages.sh" "$VERSION" "$REPO" slozos-pro-local "$PKGREL"

echo "::group::mkarchiso"
mkdir -p "$OUT"
SLOZOS_PRO_VERSION="$VERSION" mkarchiso -v -w /work/archiso -o "$OUT" "$CTX/profile"
mkdir -p "$OUT/packages"
cp "$REPO"/*.pkg.tar.zst "$OUT/packages/"
ls -lh "$OUT" "$OUT/packages"
echo "::endgroup::"
