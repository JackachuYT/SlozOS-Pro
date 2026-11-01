#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Build SlozOS Pro's own packages (pkgbuilds/*) into a local pacman repo that
# the ISO build installs from.
#
#   build/build-packages.sh <version> <repo dir> <repo name> [pkgrel]
#
# pkgrel (CI: the run number) makes every build an upgrade for installed
# systems, even within the same SlozOS Pro version.
#
# Runs as root on Arch (CI's archlinux container); makepkg itself runs as an
# unprivileged "builder" user.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
VERSION=${1:?version}; REPO=${2:?repo dir}; NAME=${3:?repo name}; PKGREL=${4:-1}
CTX=$(cd "$(dirname "$0")/.." && pwd)
id builder >/dev/null 2>&1 || useradd -m builder
# in builder's home: makepkg runs as builder and can't enter root's mktemp dirs
WORK=$(sudo -u builder mktemp -d /home/builder/build.XXXXXX)

# Artwork every package can pick from (./artwork next to each PKGBUILD)
ART="$WORK/artwork"
mkdir -p "$ART/icons" "$ART/plymouth"
cp "$CTX"/assets/brand/artwork/* "$ART/"
cp -r "$CTX"/assets/brand/icons/. "$ART/icons/"
cp "$CTX"/assets/plymouth/{logo.png,bar-fill.png,bar-track.png} "$ART/plymouth/"
cp "$CTX"/assets/wallpapers/{byteyum,bloom}-{light,dark}.jpg "$ART/"

mkdir -p "$REPO"
for dir in "$CTX"/pkgbuilds/*/; do
    pkg=$(basename "$dir")
    echo "::group::Build $pkg"
    cp -r "$dir" "$WORK/$pkg"
    cp -r "$ART" "$WORK/$pkg/artwork"
    sed -i -e "s/^pkgver=.*/pkgver=$VERSION/" -e "s/^pkgrel=.*/pkgrel=$PKGREL/" "$WORK/$pkg/PKGBUILD"
    chown -R builder: "$WORK/$pkg"
    # -d: runtime dependencies are checked when the ISO installs them
    (cd "$WORK/$pkg" && sudo -u builder makepkg -d -f --noconfirm)
    cp "$WORK/$pkg"/*.pkg.tar.zst "$REPO/"
    echo "::endgroup::"
done
repo-add -q "$REPO/$NAME.db.tar.gz" "$REPO"/*.pkg.tar.zst
ls -lh "$REPO"
rm -rf "$WORK"
