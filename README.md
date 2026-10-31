# SlozOS Pro

**A theme for [pearOS](https://pearos.xyz) NiceC0re that makes it say SlozOS Pro, and changes nothing else.**

| Where | pearOS | With the theme |
|---|---|---|
| System name (About window, system info, login prompt) | pearOS NiceC0re | **SlozOS Pro** |
| Menu-bar menu | About This Pear | **About SlozOS Pro** |
| Boot menu | Arch | **SlozOS Pro** |
| Global theme and login theme names | pearOS Splash Theme, pearOS SDDM | **SlozOS Pro** |
| Logo (menu bar, About window, boot splash, login splash) | 🍐 pear | **SloZ sloth** |

Wallpapers, apps, settings, effects and updates all stay exactly as pearOS ships them.

## Install

On pearOS, download `slozos-pro-theme-…pkg.tar.zst` from the latest [**release**](https://github.com/JackachuYT/SlozOS-Pro/releases), then open a terminal in that folder and run:

```bash
sudo pacman -U slozos-pro-theme-*.pkg.tar.zst
```

Restart to see the new boot splash. pearOS updates don't undo the theme: if an update brings back a pearOS name or logo, the theme puts SlozOS Pro back automatically.

**Uninstall:** `sudo pacman -R slozos-pro-theme` puts every pearOS name and logo back exactly as it was.

## How it works

- `theme/slozos-pro-theme` swaps the names and logos (`apply`), and puts pearOS's originals back (`restore`). pearOS's original files are kept in `/var/lib/slozos-pro-theme/originals`.
- `theme/slozos-pro-theme.hook` is a pacman hook that runs `apply` again whenever an update touches one of those files.
- `tests/test-theme.sh` runs it against a pearOS file tree: apply, re-apply, a pearOS update, a theme update, and restore.

SlozOS Pro is an independent project, not affiliated with or endorsed by the pearOS project.
