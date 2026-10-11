#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Build slozos-pro-desktop_<version>_all.deb: the SlozOS Pro design and
# branding as one package, so installed systems get design updates through
# apt like any other update.
#
#   build/build-deb.sh <version> <outdir>
#
# Bundles (pinned): Fluent GTK theme, Fluent icons + cursors (vinceliuice,
# GPL-3.0), and the GNOME extensions in build/extensions.txt. Also memory
# tuning (zram + sysctl) under /etc.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
VERSION=${1:?version}
OUT=${2:?outdir}
CTX=$(cd "$(dirname "$0")/.." && pwd)
FLUENT_GTK_SHA=7a49a464b0188c340101c52965c18190b1c694cf     # 2026-08-17
FLUENT_ICONS_SHA=c8a244f571ef8fb47812bdc9dbce76546cedce69   # 2026-08-30

SRC=$(mktemp -d); STAGE=$(mktemp -d)
trap 'rm -rf "$SRC" "$STAGE"' EXIT
fetch() {  # fetch OWNER/REPO SHA → $SRC/REPO
    mkdir -p "$SRC/${1#*/}"
    curl -fsSL --retry 5 "https://github.com/$1/archive/$2.tar.gz" | tar -xz -C "$SRC/${1#*/}" --strip-components=1
}

# Static files (schemas override, branding script, boot splash, GRUB theme…)
cp -a "$CTX/packaging/root/." "$STAGE/"

# Artwork
install -Dm644 "$CTX/assets/wallpapers/slozos-pro-light.jpg" "$STAGE/usr/share/backgrounds/slozos-pro/slozos-pro-light.jpg"
install -Dm644 "$CTX/assets/wallpapers/slozos-pro-dark.jpg"  "$STAGE/usr/share/backgrounds/slozos-pro/slozos-pro-dark.jpg"
install -Dm644 "$CTX/assets/brand/start-button.png"   "$STAGE/usr/share/slozos-pro/start-button.png"
install -Dm644 "$CTX/assets/brand/login-logo.png"     "$STAGE/usr/share/slozos-pro/login-logo.png"
install -Dm644 "$CTX/assets/brand/grub-background.png" "$STAGE/usr/share/grub/themes/slozos-pro/background.png"
for d in "$CTX"/assets/brand/icons/*/; do
    install -Dm644 "$d/slozos-pro-logo.png" "$STAGE/usr/share/icons/hicolor/$(basename "$d")/apps/slozos-pro-logo.png"
done
echo "$VERSION" > "$STAGE/usr/share/slozos-pro/version"

# Fluent GTK + GNOME Shell theme: Fluent-round-Light / Fluent-round-Dark
fetch vinceliuice/Fluent-gtk-theme "$FLUENT_GTK_SHA"
mkdir -p "$STAGE/usr/share/themes"
# The installer picks GNOME Shell styles by `gnome-shell --version`; build
# them for Zorin OS 18's GNOME 46, not the build machine's (none)
mkdir -p "$SRC/bin"; printf '#!/bin/sh\necho "GNOME Shell 46.0"\n' > "$SRC/bin/gnome-shell"; chmod +x "$SRC/bin/gnome-shell"
( cd "$SRC/Fluent-gtk-theme" && PATH="$SRC/bin:$PATH" HOME=/tmp bash ./install.sh -d "$STAGE/usr/share/themes" -t default -c light dark -s standard --tweaks round )
for t in Fluent-round-Light Fluent-round-Dark; do
    [[ -d $STAGE/usr/share/themes/$t/gtk-3.0 && -d $STAGE/usr/share/themes/$t/gnome-shell ]] \
        || { echo "Fluent theme $t missing"; ls "$STAGE/usr/share/themes"; exit 1; }
done

# Fluent icons (Fluent, Fluent-light, Fluent-dark) + cursors
fetch vinceliuice/Fluent-icon-theme "$FLUENT_ICONS_SHA"
mkdir -p "$STAGE/usr/share/icons"
( cd "$SRC/Fluent-icon-theme" && HOME=/tmp bash ./install.sh -d "$STAGE/usr/share/icons" )
cp -r "$SRC/Fluent-icon-theme/cursors/dist"      "$STAGE/usr/share/icons/Fluent-cursors"
cp -r "$SRC/Fluent-icon-theme/cursors/dist-dark" "$STAGE/usr/share/icons/Fluent-dark-cursors"
sed -i 's/^Name=.*/Name=Fluent Cursors/'      "$STAGE/usr/share/icons/Fluent-cursors/index.theme"
sed -i 's/^Name=.*/Name=Fluent Dark Cursors/' "$STAGE/usr/share/icons/Fluent-dark-cursors/index.theme"
[[ -f $STAGE/usr/share/icons/Fluent/index.theme ]] || { echo "Fluent icons missing"; exit 1; }

# GNOME Shell extensions. Their settings schemas move to the system schema
# directory so SlozOS Pro's defaults (90_slozos-pro.gschema.override) apply.
EXT="$STAGE/usr/share/gnome-shell/extensions"
SCHEMAS="$STAGE/usr/share/glib-2.0/schemas"
mkdir -p "$EXT" "$SCHEMAS"
grep -v '^#' "$CTX/build/extensions.txt" | while read -r uuid tag sha; do
    [[ -n $uuid ]] || continue
    curl -fsSL --retry 5 -o "$SRC/$uuid.zip" \
        "https://extensions.gnome.org/download-extension/$uuid.shell-extension.zip?version_tag=$tag"
    echo "$sha  $SRC/$uuid.zip" | sha256sum -c --quiet -
    mkdir -p "$EXT/$uuid"
    unzip -q "$SRC/$uuid.zip" -d "$EXT/$uuid"
    if [[ -d $EXT/$uuid/schemas ]]; then
        mv "$EXT/$uuid"/schemas/*.gschema.xml "$SCHEMAS/"
        rm -rf "$EXT/$uuid/schemas"
    fi
done
chmod -R a+rX,go-w "$STAGE"

# Package
mkdir -p "$STAGE/DEBIAN" "$OUT"
sed "s/@VERSION@/$VERSION/" "$CTX/packaging/DEBIAN/control.in" > "$STAGE/DEBIAN/control"
install -m755 "$CTX/packaging/DEBIAN/postinst" "$CTX/packaging/DEBIAN/prerm" "$STAGE/DEBIAN/"
install -m644 "$CTX/packaging/DEBIAN/triggers" "$CTX/packaging/DEBIAN/conffiles" "$STAGE/DEBIAN/"
echo "Installed-Size: $(du -sk --exclude=DEBIAN "$STAGE" | cut -f1)" >> "$STAGE/DEBIAN/control"
dpkg-deb --root-owner-group -Zxz --build "$STAGE" "$OUT/slozos-pro-desktop_${VERSION}_all.deb"
ls -lh "$OUT"
