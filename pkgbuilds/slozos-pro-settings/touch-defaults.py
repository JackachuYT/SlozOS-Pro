#!/usr/bin/env python3
"""SlozOS Pro touch-first defaults for new accounts (/etc/skel), applied on
top of pearOS's: tablet mode follows the hardware instead of being forced
off, KDE's on-screen keyboard is the input method, swipe up from the bottom
edge opens Overview, and the leftover 1x scale for a VM display is dropped
so the Surface's screen scales itself.
    touch-defaults.py <skel .config dir>
"""
import configparser, sys
from pathlib import Path

cfg_dir = Path(sys.argv[1])

def edit(name, changes, remove=()):
    path = cfg_dir / name
    ini = configparser.RawConfigParser(strict=False, interpolation=None, delimiters=("=",))
    ini.optionxform = str                         # KDE keys are case-sensitive
    if path.exists():
        ini.read(path, encoding="utf-8")
    for section, key in remove:
        if ini.has_section(section):
            ini.remove_option(section, key)
    for section, values in changes.items():
        if not ini.has_section(section):
            ini.add_section(section)
        for key, value in values.items():
            ini.set(section, key, value)
    with open(path, "w", encoding="utf-8") as f:
        ini.write(f, space_around_delimiters=False)

edit("kwinrc", {
    "Input": {"TabletMode": "auto"},
    "Wayland": {"InputMethod[$e]": "/usr/share/applications/org.kde.plasma.keyboard.desktop",
                "VirtualKeyboardEnabled": "true"},
    "Effect-overview": {"TouchBorderActivate": "4"},
})
edit("kdeglobals", {}, remove=[("KScreen", "ScreenScaleFactors")])
