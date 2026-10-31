# SlozOS Pro — "ByteYum"

**A touch-first, lightweight desktop for small tablets and laptops.**
Built on [pearOS](https://pearos.xyz) NiceC0re (Arch Linux + KDE Plasma 6), tuned for the Microsoft Surface Pro 1 and other 4 GB devices. Roughly two-thirds touch, one-third keyboard and mouse.

- 👆 **Touch first:** take the keyboard off and it switches to tablet mode, with bigger controls. A keyboard pops up when you tap a text box, including on the login screen. The screen follows when you turn it, and you can swipe up from the bottom edge to see all your windows.
- ⌨️ **Still great with a keyboard:** clip the Type Cover back on (or plug in a mouse) and it's a normal desktop again.
- 🪶 **Quick on 4 GB:** compressed RAM swap, no file indexing in the background, and lighter glass effects on older graphics like the Surface Pro 1's.
- 💻 **Surface Pro 1/2 fixes:** no more going straight back to sleep after waking (the firmware sends a false "lid closed"), reliable Marvell Wi-Fi, deep sleep.
- 🐞 **Fixes over pearOS:**
  - **Lock screen:** uses Arch's own lock screen, because pearOS's fork often refuses the password ([pearOS-archlinux/iso#142](https://github.com/pearOS-archlinux/iso/issues/142)).
  - **Booting:** uses Arch's standard boot loaders, and adds a safe-graphics boot option.
  - **Tablet mode:** no longer forced off.
- 🍐 **New look:** the SlozOS Pro "ByteYum" wallpapers (pear-coloured liquid glass) and SlozOS branding, on pearOS's macOS-style desktop.

## Download and install

1. Download **all** the `.7z.00x` parts of the latest release from [**Releases**](https://github.com/JackachuYT/SlozOS-Pro/releases) into one folder.
2. Put them back together:
   - **Windows:** install [7-Zip](https://www.7-zip.org/), then right-click the `.001` file → **7-Zip** → **Extract Here**
   - **macOS:** open the `.001` file with [Keka](https://www.keka.io/)
   - **Linux:** `7z x SlozOS-Pro-1.0-ByteYum-x86_64.7z.001`
3. Flash the `.iso` to a USB stick (8 GB+) with [Balena Etcher](https://etcher.balena.io/).
4. **Surface Pro 1:**
   - Hold **Volume Up** while pressing **Power** to open the firmware settings, and turn **Secure Boot off**.
   - Then hold **Volume Down** while pressing **Power** to boot from the USB stick.
5. Choose **Try or Install SlozOS Pro**, then tap **Install SlozOS Pro** on the desktop.

## How it's built

GitHub Actions builds everything in an Arch Linux container (`.github/workflows/build.yml`, `build/ci-build.sh`):

| Part | What it is |
|---|---|
| `profile/` | The live ISO (an [archiso](https://gitlab.archlinux.org/archlinux/archiso) profile). Its skeleton is Arch's `releng` profile; it installs pearOS's desktop packages, trimmed for small devices, plus the touch packages (KDE's on-screen keyboard and screen rotation) |
| `pkgbuilds/slozos-pro-settings` | pearOS's desktop design (GPL-3.0) with SlozOS Pro wallpapers and logos, touch-first defaults, and without pearOS's custom-licensed apps |
| `pkgbuilds/slozos-pro-system` | Branding, the Surface fixes, the touch-friendly login screen, memory tuning and the boot splash |
| `pkgbuilds/slozos-pro-installer` | The installer's settings and look (Calamares), written for SlozOS Pro |
| `tests/vm-test.py` | Boots the ISO in a UEFI virtual machine and takes screenshots |

Installed systems get updates from Arch Linux, CachyOS and pearOS like any pearOS install. SlozOS Pro's own three packages come from the `repo` release on this page.

## Credits

- [pearOS](https://github.com/pearOS-archlinux) NiceC0re by the Pear Project: desktop design and apps (GPL-3.0 / MIT)
- [Arch Linux](https://archlinux.org) and [archiso](https://gitlab.archlinux.org/archlinux/archiso) (GPL-3.0)
- [CachyOS](https://cachyos.org): the optimised kernel
- [KDE Plasma](https://kde.org/plasma-desktop/) and [Calamares](https://calamares.io)

SlozOS Pro is an independent project. It is not affiliated with, or endorsed by, the pearOS project, Arch Linux, CachyOS or Apple. SlozOS Pro doesn't ship pearOS's custom-licensed apps (calculator, notch, installer settings, live-CD desktop), or the Apple wallpapers included in pearOS.
