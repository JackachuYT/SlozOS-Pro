#!/usr/bin/env bash
# Tests slozos-pro-theme against a fake pearOS file tree: apply, re-apply,
# a pearOS update, a theme update, and restore.
set -euo pipefail
CTX=$(cd "$(dirname "$0")/.." && pwd)
export SLOZOS_PRO_THEME_ROOT=$(mktemp -d)
R=$SLOZOS_PRO_THEME_ROOT
THEME="$CTX/theme/slozos-pro-theme"
fail() { echo "FAIL: $*"; exit 1; }
pass() { echo "ok   $*"; }

pearos_tree() {   # the pearOS files the theme touches (names as pearOS ships them)
    mkdir -p "$R"/usr/lib "$R"/etc/default
    cat > "$R/usr/lib/os-release" <<'OS'
NAME="pearOS NiceC0re"
VARIANT="Release Build Oct. 2026"
VERSION="26.10"
PRETTY_NAME="pearOS NiceC0re"
ID=arch
BUILD_ID=rolling
HOME_URL="https://pearOS.xyz"
LOGO=nicec0re-logo
IMAGE_ID=pearos-nicec0re
OS
    printf 'DISTRIB_ID=pearOS\nDISTRIB_RELEASE=26.10\nDISTRIB_CODENAME=nicec0re\nDISTRIB_DESCRIPTION="pearOS NiceC0re"\n' > "$R/etc/lsb-release"
    printf 'pearOS NiceC0re \\r (\\l)\n\n' > "$R/etc/issue"
    printf 'GRUB_DEFAULT=0\nGRUB_DISTRIBUTOR="Arch"\nGRUB_THEME="/usr/share/grub/themes/pearOS/theme.txt"\n' > "$R/etc/default/grub"
    local q="$R/usr/share/plasma/plasmoids/xyz.pearos.pearmenu/contents/ui"
    mkdir -p "$q"; printf '        PlasmaExtras.MenuItem {\n            text: i18n("About This Pear")\n        }\n' > "$q/MainMenuButton.qml"
    local lnf
    for lnf in pearOS pearOS-dark; do
        mkdir -p "$R/usr/share/plasma/look-and-feel/$lnf/contents/splash/images" "$R/usr/share/sddm/themes/$lnf"
        printf '{\n    "KPlugin": {\n        "Name": "pearOS Splash Theme for Plasma",\n        "Id": "%s"\n    }\n}\n' "$lnf" \
            > "$R/usr/share/plasma/look-and-feel/$lnf/metadata.json"
        echo "pear splash" > "$R/usr/share/plasma/look-and-feel/$lnf/contents/splash/images/drawing.svg"
    done
    printf '[SddmGreeterTheme]\nName=pearOS SDDM\n' > "$R/usr/share/sddm/themes/pearOS/metadata.desktop"
    printf '[SddmGreeterTheme]\nName=pearOS SDDM Dark\n' > "$R/usr/share/sddm/themes/pearOS-dark/metadata.desktop"
    local f
    for f in usr/share/pixmaps/nicec0re-logo.png usr/share/icons/piri-logo.png usr/share/extras/release_logo.png \
             usr/share/extras/pearos_cropped_transparent.png "usr/share/extras/Pearos_fullscreen_non-transparent.png.png.png" \
             usr/share/extras/pearlogo.svg usr/share/extras/drawing.svg usr/share/extras/drawing-black.svg \
             usr/share/plymouth/themes/pear-plymouth/boot.png usr/share/plymouth/themes/pear-plymouth/logo.svg; do
        mkdir -p "$(dirname "$R/$f")"; echo "pear: $f" > "$R/$f"
    done
}

pearos_tree
cp -r "$R" "$R.pristine"
mkdir -p "$R/usr/share/slozos-pro-theme"; cp "$CTX"/theme/art/* "$R/usr/share/slozos-pro-theme/"

# ── apply ────────────────────────────────────────────────────────────────────
bash "$THEME" apply
grep -qx 'NAME="SlozOS Pro"' "$R/usr/lib/os-release"            || fail "os-release NAME"
grep -qx 'PRETTY_NAME="SlozOS Pro"' "$R/usr/lib/os-release"     || fail "os-release PRETTY_NAME"
grep -qx 'LOGO=slozos-pro-logo' "$R/usr/lib/os-release"         || fail "os-release LOGO"
grep -qx 'VERSION="26.10"' "$R/usr/lib/os-release"              || fail "os-release must keep pearOS's version"
grep -qx 'ID=arch' "$R/usr/lib/os-release"                      || fail "os-release must keep ID"
grep -qx 'HOME_URL="https://pearOS.xyz"' "$R/usr/lib/os-release" || fail "os-release must keep the rest"
grep -qx 'DISTRIB_DESCRIPTION="SlozOS Pro"' "$R/etc/lsb-release" || fail "lsb-release"
grep -q '^SlozOS Pro ' "$R/etc/issue"                           || fail "issue"
grep -qx 'GRUB_DISTRIBUTOR="SlozOS Pro"' "$R/etc/default/grub"  || fail "grub distributor"
grep -q 'GRUB_THEME="/usr/share/grub/themes/pearOS/theme.txt"' "$R/etc/default/grub" || fail "grub theme must stay pearOS's"
grep -q 'i18n("About SlozOS Pro")' "$R/usr/share/plasma/plasmoids/xyz.pearos.pearmenu/contents/ui/MainMenuButton.qml" || fail "menu"
grep -q '"Name": "SlozOS Pro",' "$R/usr/share/plasma/look-and-feel/pearOS/metadata.json"     || fail "global theme name"
grep -q '"Name": "SlozOS Pro Dark",' "$R/usr/share/plasma/look-and-feel/pearOS-dark/metadata.json" || fail "dark global theme name"
grep -qx 'Name=SlozOS Pro' "$R/usr/share/sddm/themes/pearOS/metadata.desktop"                 || fail "login theme name"
cmp -s "$R/usr/share/plymouth/themes/pear-plymouth/boot.png" "$CTX/theme/art/boot.png"       || fail "boot splash logo"
cmp -s "$R/usr/share/pixmaps/nicec0re-logo.png" "$CTX/theme/art/logo-tile-1024.png"          || fail "About logo"
cmp -s "$R/usr/share/plasma/look-and-feel/pearOS/contents/splash/images/drawing.svg" "$CTX/theme/art/logo-white.svg" || fail "splash logo"
pass "apply: name and logos are SlozOS Pro, everything else is pearOS's"

# ── apply again: nothing changes, originals stay pearOS's ────────────────────
before=$(cd "$R" && find . -type f ! -path './var/*' -exec sha256sum {} + | sort)
bash "$THEME" apply
after=$(cd "$R" && find . -type f ! -path './var/*' -exec sha256sum {} + | sort)
[[ $before == "$after" ]] || fail "second apply changed files"
grep -q 'pear: ' "$R/var/lib/slozos-pro-theme/originals/usr/share/pixmaps/nicec0re-logo.png" || fail "original logo kept"
pass "apply again: no changes"

# ── a pearOS update brings its files back ────────────────────────────────────
cp "$R.pristine/usr/lib/os-release" "$R/usr/lib/os-release"
echo "pear v2" > "$R/usr/share/plymouth/themes/pear-plymouth/boot.png"
bash "$THEME" apply
grep -qx 'NAME="SlozOS Pro"' "$R/usr/lib/os-release" || fail "re-brand after update"
cmp -s "$R/usr/share/plymouth/themes/pear-plymouth/boot.png" "$CTX/theme/art/boot.png" || fail "re-logo after update"
grep -qx 'pear v2' "$R/var/lib/slozos-pro-theme/originals/usr/share/plymouth/themes/pear-plymouth/boot.png" || fail "updated original kept"
pass "pearOS update: SlozOS Pro again, new original kept"

# ── a theme update: new artwork must not be mistaken for pearOS's ────────────
echo "slozos art v2" > "$R/usr/share/slozos-pro-theme/logo-tile-512.png"
bash "$THEME" apply
grep -qx 'slozos art v2' "$R/usr/share/icons/piri-logo.png" || fail "new artwork applied"
grep -q 'pear: ' "$R/var/lib/slozos-pro-theme/originals/usr/share/icons/piri-logo.png" || fail "original survived a theme update"
pass "theme update: new artwork, pearOS's original untouched"

# ── restore: everything back to pearOS ───────────────────────────────────────
# (pearOS's boot splash is its v2 now, from the update above)
echo "pear v2" > "$R.pristine/usr/share/plymouth/themes/pear-plymouth/boot.png"
bash "$THEME" restore
diff -r --exclude=slozos-pro-theme --exclude=var "$R.pristine" "$R" >/dev/null || { diff -r --exclude=slozos-pro-theme --exclude=var "$R.pristine" "$R" | head; fail "restore"; }
[[ ! -e $R/var/lib/slozos-pro-theme ]] || fail "state removed"
pass "restore: pearOS exactly as before"
rm -rf "$R" "$R.pristine"
echo "all tests passed"
