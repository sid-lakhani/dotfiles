# Dotfiles

Personal Arch Linux configuration managed with GNU Stow.

## Components

- Hyprland and Caelestia
- Fish and Zsh
- Foot and Fuzzel
- Fastfetch and btop
- Neovim
- GTK 3/4 styling
- Personal wallpapers

## Requirements

- Arch Linux
- Git
- GNU Stow
- Packages listed in `packages/pacman.txt`
- AUR helper or manual AUR installation for `quickshell-git` in `packages/aur.txt`

## Installation

Install the official repository packages:

```sh
sudo pacman -S --needed - < packages/pacman.txt
```

Install AUR packages separately, using your preferred AUR helper.

Preview dotfile links:

```sh
./scripts/stow.sh --simulate
```

Apply dotfile links:

```sh
./scripts/stow.sh
```

Back up existing configuration before applying Stow on a new machine.

## Notes

- The repository stores configuration, not a complete system backup.
- Machine-specific services, drivers, credentials, and application state may require separate setup.
- Wallpapers are stored in `wallpapers/pix/wall` and linked to `~/pix/wall`.
