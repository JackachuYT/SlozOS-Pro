#!/usr/bin/env bash
# Prints what the SlozOS Pro remaster needs to know about the Zorin OS root
# filesystem (branding, extensions, defaults, available packages).
# Usage: inspect.sh <unpacked squashfs root>
set -uo pipefail
R=$1
sec() { echo; echo "===== $* ====="; }
sec "os-release";            cat "$R/usr/lib/os-release"; cat "$R/etc/lsb-release" 2>/dev/null
sec "GNOME Shell";           chroot "$R" gnome-shell --version 2>/dev/null || ls "$R/usr/share/gnome-shell"
sec "Shell extensions";      ls "$R/usr/share/gnome-shell/extensions"
sec "Zorin packages";        chroot "$R" dpkg-query -W -f '${Package}\t${Version}\t${Installed-Size}\n' | grep -i zorin
sec "Ubiquity / slideshow";  chroot "$R" dpkg-query -W -f '${Package}\n' | grep -iE 'ubiquity|slideshow|plymouth|grub|census|popularity'
sec "Schema overrides";      ls -la "$R/usr/share/glib-2.0/schemas/" | grep -i override; for f in "$R"/usr/share/glib-2.0/schemas/*override; do echo "--- $f"; cat "$f"; done
sec "dconf defaults";        ls -R "$R/etc/dconf" 2>/dev/null; cat "$R"/etc/dconf/db/*.d/* 2>/dev/null | head -80
sec "Desktop files naming Zorin"; grep -l -i '^Name=.*zorin' "$R"/usr/share/applications/*.desktop "$R"/etc/xdg/autostart/*.desktop 2>/dev/null | while read -r f; do echo "$f: $(grep -m1 '^Name=' "$f") | $(grep -m1 '^Exec=' "$f")"; done
sec "Autostart";             ls "$R/etc/xdg/autostart"
sec "Icons named zorin";     find "$R/usr/share/icons" "$R/usr/share/pixmaps" -iname '*zorin*' | sed 's|/[^/]*/[^/]*$||' | sort | uniq -c | sort -rn | head -20; find "$R/usr/share/icons" -iname '*zorin*' -printf '%f\n' | sort -u | head -30
sec "Backgrounds";           ls "$R/usr/share/backgrounds" "$R/usr/share/gnome-background-properties" 2>/dev/null
sec "Plymouth";              ls "$R/usr/share/plymouth/themes"; readlink -f "$R/etc/alternatives/default.plymouth"
sec "GRUB";                  grep -E 'DISTRIBUTOR|THEME|BACKGROUND' "$R/etc/default/grub" "$R"/etc/default/grub.d/* 2>/dev/null; ls "$R/boot/grub/themes" "$R/usr/share/grub/themes" 2>/dev/null
sec "Themes / icon themes";  ls "$R/usr/share/themes"; ls "$R/usr/share/icons"
sec "apt sources";           cat "$R"/etc/apt/sources.list 2>/dev/null; for f in "$R"/etc/apt/sources.list.d/*; do echo "--- $f"; cat "$f"; done
sec "Flatpak remotes";       chroot "$R" flatpak remotes --system 2>/dev/null; ls "$R/var/lib/flatpak/app" 2>/dev/null
sec "Snap";                  chroot "$R" dpkg-query -W snapd 2>&1 | head -2
sec "Kernel";                ls "$R/boot"
sec "Strings: Zorin in /usr/share (top dirs)"; grep -rIl --exclude-dir=locale --exclude-dir=doc -i 'zorin os' "$R/usr/share" 2>/dev/null | sed "s|$R||" | awk -F/ '{print "/"$2"/"$3"/"$4}' | sort | uniq -c | sort -rn | head -25
