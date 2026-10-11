# SlozOS Pro

**A beginner-friendly, lightweight desktop OS for everyday use and work, designed like Windows 11.**
Built on [Zorin OS](https://zorin.com/os/) 18.1 Core, which is built on Ubuntu 24.04 LTS (supported until 2029).

- 🪟 **Feels like Windows 11:** the Start button and your apps sit in the middle of the taskbar. The Windows key opens a Start menu with pinned apps, recommended files and search. Drag a window to the top of the screen for snap layouts.
- 🎨 **Fluent look:** rounded corners, a translucent taskbar, Fluent theme, icons and cursors, the Selawik font, and SlozOS Pro's own wallpapers.
- 💼 **Ready for work:** LibreOffice (opens and saves Word, Excel and PowerPoint files), email and calendar, Remote Desktop, the Brave web browser.
- 🪶 **Light and quick:** compressed RAM swap keeps 4 GB PCs smooth, the desktop doesn't wait for the network to start, and there is no Snap running in the background, and no games, crash pop-ups or adverts. Choose **NVIDIA graphics** on the boot menu if you have an NVIDIA card.
- 🔄 **Updates in the Software app:** Ubuntu and Zorin security updates, plus SlozOS Pro's own design updates.

## Download and install

1. Download **all** the `.7z.00x` parts of the latest release from [**Releases**](https://github.com/JackachuYT/SlozOS-Pro/releases) into one folder. Each part is under GitHub's 2 GB limit.
2. Put them back together:
   - **Windows:** install [7-Zip](https://www.7-zip.org/), then right-click the `.001` file → **7-Zip** → **Extract Here**. The `7z` command isn't available in a terminal on Windows, so use the right-click menu.
   - **macOS:** open the `.001` file with [Keka](https://www.keka.io/)
   - **Linux:** `7z x SlozOS-Pro-1.0-amd64.7z.001`
3. Flash `SlozOS-Pro-1.0-amd64.iso` to a USB stick (8 GB+) with [Balena Etcher](https://etcher.balena.io/).
4. Boot from the USB stick and choose **Try or Install SlozOS Pro**.

## How it's built

Everything is automated in GitHub Actions (`.github/workflows/build.yml`):

| Step | What happens |
|---|---|
| `build/build-deb.sh` | Builds `slozos-pro-desktop`, the SlozOS Pro design, tuning and branding as one Debian package: the pinned Fluent theme, icons and cursors, the GNOME extensions in `build/extensions.txt`, SlozOS Pro's defaults (`90_slozos-pro.gschema.override`), memory tuning, wallpapers, boot splash and boot menu |
| `build/remaster.sh` | Downloads Zorin OS Core (checked against its SHA256), unpacks it, runs `build/customize.sh` inside it, repacks it, and writes an ISO that boots exactly like Zorin's |
| `tests/vm-test.py` | Boots the new ISO's live desktop in QEMU and takes screenshots |

Branding is re-applied automatically: `slozos-pro-desktop` watches for updates (dpkg triggers) that bring Zorin names back, and runs `/usr/lib/slozos-pro/brand` again.

## Credits

- [Zorin OS](https://zorin.com/os/) Core by Zorin Technology Group: the base system (free edition)
- [Ubuntu](https://ubuntu.com) by Canonical
- [Fluent GTK theme](https://github.com/vinceliuice/Fluent-gtk-theme) and [Fluent icon theme](https://github.com/vinceliuice/Fluent-icon-theme) by Vince Liuice (GPL-3.0)
- [Dash to Panel](https://github.com/home-sweet-gnome/dash-to-panel) and [ArcMenu](https://gitlab.com/arcmenu/ArcMenu) (GPL)
- [Selawik](https://github.com/microsoft/Selawik) font by Microsoft (SIL Open Font License)

SlozOS Pro is an independent project. It is not affiliated with, or endorsed by, Zorin Technology Group Ltd., Canonical or Microsoft. Zorin OS is a trademark of Zorin Technology Group Ltd.; Ubuntu is a trademark of Canonical Ltd.; Windows is a trademark of Microsoft Corporation. SlozOS Pro does not include any software from Zorin OS Pro.
