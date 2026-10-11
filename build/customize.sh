#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# SlozOS Pro customisation — runs inside Zorin OS Core's live system (chroot)
# while build/remaster.sh builds the ISO. The repo is mounted at /ctx and the
# freshly built slozos-pro-desktop package is in /ctx/out.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive SLOZOS_PRO_BUILD=1
VERSION=${SLOZOS_PRO_VERSION:?}
log() { echo "::group::$*"; }
end() { echo "::endgroup::"; }
APT=(apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)

# Nothing may start services inside the chroot
printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d

# ── Updates ──────────────────────────────────────────────────────────────────
log "Updates"
# The ISO boots Zorin's kernel (casper/vmlinuz), so it stays put while the
# ISO is built; installed systems get kernel updates as normal (unheld below)
KPKGS=$(dpkg-query -W -f '${db:Status-Abbrev} ${Package}\n' 'linux-image-*' 'linux-modules-*' 'linux-headers-*' \
        'linux-generic*' 'linux-hwe*' 'linux-tools-*' 2>/dev/null | awk '$1 == "ii" {print $2}' || true)
[[ -n $KPKGS ]] && apt-mark hold $KPKGS >/dev/null
apt-get update -q
"${APT[@]}" full-upgrade
end

# ── Lighter: drop what a normal desktop doesn't need ─────────────────────────
log "Slim down"
# Everything installed now counts as wanted, so removing a few packages can't
# make apt "autoremove" whole chunks of Zorin OS along with them
apt-mark manual $(dpkg-query -W -f '${db:Status-Abbrev} ${Package}\n' | awk '$1 == "ii" {print $2}') >/dev/null
# Games, and Snap (a second app store running in the background: the
# Software app keeps Flatpak and regular packages)
SLIM=(aisleriot gnome-mahjongg gnome-mines gnome-sudoku quadrapassel gnome-chess five-or-more four-in-a-row
      hitori iagno lightsoff swell-foop tali gnome-robots gnome-klotski gnome-nibbles gnome-taquin gnome-tetravex
      snapd gnome-software-plugin-snap)
REMOVE=()
for p in "${SLIM[@]}"; do dpkg -s "$p" >/dev/null 2>&1 && REMOVE+=("$p"); done
if (( ${#REMOVE[@]} )); then "${APT[@]}" purge "${REMOVE[@]}"; fi
rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd
end

# ── Apps + speed-ups ─────────────────────────────────────────────────────────
log "Apps and speed-ups"
# Remote Desktop for work; compressed RAM swap (zram) so 4 GB PCs stay smooth
"${APT[@]}" install remmina systemd-zram-generator
# Faster boot: don't wait for the network before showing the desktop
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true
# No crash-report pop-ups
[[ -f /etc/default/apport ]] && sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport
# No Ubuntu Pro adverts at login
for f in /etc/xdg/autostart/ubuntu-advantage-notification.desktop; do
    [[ -f $f ]] && { grep -q '^Hidden=true' "$f" || sed -i '/^\[Desktop Entry\]/a Hidden=true' "$f"; }
done
end

# ── SlozOS Pro design + branding ─────────────────────────────────────────────
log "SlozOS Pro desktop"
"${APT[@]}" install /ctx/out/slozos-pro-desktop_*_all.deb
# Fail the build if any of our defaults don't match a real setting
if glib-compile-schemas --strict --dry-run /usr/share/glib-2.0/schemas 2>&1 | grep -i 'slozos-pro'; then
    echo "::error::90_slozos-pro.gschema.override has invalid keys"; exit 1
fi
glib-compile-schemas /usr/share/glib-2.0/schemas
grep -q 'SlozOS Pro' /usr/lib/os-release || { echo "::error::branding did not apply"; exit 1; }
end

# ── Live session + installer ─────────────────────────────────────────────────
log "Live session and installer"
# Live user / host names
if [[ -f /etc/casper.conf ]]; then
    sed -i -e 's/^export USERNAME=.*/export USERNAME="slozos"/' \
           -e 's/^export USERFULLNAME=.*/export USERFULLNAME="SlozOS Pro live session"/' \
           -e 's/^export HOST=.*/export HOST="slozos-pro"/' \
           -e 's/^export FLAVOUR=.*/export FLAVOUR="SlozOS Pro"/' /etc/casper.conf
fi
# Installer slideshow (Ubiquity shows slides/index.html while installing)
if [[ -d /usr/share/ubiquity-slideshow ]]; then
    rm -rf /usr/share/ubiquity-slideshow/*
    cp -r /ctx/installer/slideshow/. /usr/share/ubiquity-slideshow/
    install -m644 /ctx/assets/wallpapers/slozos-pro-dark.jpg /usr/share/ubiquity-slideshow/slides/background.jpg
fi
end

# ── Boot splash into the live initramfs ──────────────────────────────────────
log "initramfs"
KVER=$(ls /lib/modules | sort -V | tail -1)
update-initramfs -c -k "$KVER" 2>/dev/null || update-initramfs -u -k "$KVER"
end

# ── Clean up ─────────────────────────────────────────────────────────────────
log "Clean up"
[[ -n $KPKGS ]] && apt-mark unhold $KPKGS >/dev/null
"${APT[@]}" autoremove --purge
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/*.bin /var/log/*.log /var/log/apt/* /tmp/* /var/tmp/* /root/.cache
rm -f /usr/sbin/policy-rc.d /var/lib/dbus/machine-id
: > /etc/machine-id
end
