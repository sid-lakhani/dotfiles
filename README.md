# Dotfiles

A unified, keyboard-driven Arch Linux workstation powered by **Hyprland**, **Caelestia**, and **Kitty**.

Managed modularly with [GNU Stow](https://www.gnu.org/software/stow/).

---

## Highlights

- **Compositor & Tiling:** [Hyprland](https://hyprland.org/) with fluid spring animations, custom window rules, and multi-workspace workflow.
- **Desktop Shell:** [Caelestia](https://github.com/caelestia-dots/caelestia) (Quickshell) providing a native Wayland status bar, system tray, quick settings, and notification center.
- **Terminal Stack:** [Kitty](https://sw.kovidgoyal.net/kitty/) with GPU rendering and Kitty Graphics Protocol; fallback support for [Foot](https://codeberg.org/dnkl/foot).
- **Shells & Prompt:** Zsh and Fish configured with Starship prompt, syntax highlighting, and auto-suggestions.
- **Dynamic Theming:** Custom wallpaper engine with Quickshell picker (`Super + B`), supporting live video (`.mp4`), animated GIFs, and static imagery. Automatically extracts Material You and Pywal palettes, syncing colors across Hyprland borders, GTK, Caelestia, terminal windows, and code editors (VS Code & Antigravity IDE) in real time.
- **Terminal Polish:** Fastfetch system summary with dynamic color dots and optional theme-matched sprite companions (`pokefetch`).
- **Launcher:** [Fuzzel](https://codeberg.org/dnkl/fuzzel) styled with the active wallpaper scheme.

---

## Architecture

Configurations are organized into independent Stow packages:

```
dotfiles/
├── bin/          # User scripts (wallpaper engine, update checkers, pokefetch)
├── btop/         # System monitor theme and layout
├── fastfetch/    # System info layout and icons
├── fish/         # Fish shell configuration
├── foot/         # Foot terminal configuration
├── fuzzel/       # Application launcher styling
├── gtk/          # GTK 3/4 theme and icon settings
├── hypr/         # Hyprland rules, keybinds, and monitors
├── kitty/        # Kitty terminal configuration and dynamic palette
├── nvim/         # Neovim configuration
├── quickshell/   # Caelestia Quickshell desktop shell & 3D wallpaper picker
├── wallpapers/   # Static and live wallpaper collection
└── zsh/          # Zsh configuration and aliases
```

---

## Core Utilities

- **`wallpaper`**: Manages static, GIF, and video wallpapers. Coordinates `awww` transitions, `mpvpaper` playback, and system palette syncing.
- **`extract-palette`**: Chroma-weighted palette extractor synthesizing Material You and 16-color ANSI themes from wallpaper accents.
- **`wall-thumbs`**: Multi-threaded thumbnail generator caching previews for the wallpaper picker.
- **`check-updates`**: Background Arch package update monitor for pacman and AUR packages.
- **`pokefetch`**: Terminal sysfetch displaying system metrics alongside theme-aware animated sprites. Run `poke-sprites` to download the sprite library.

---

## Keybindings

| Keybinding | Action |
| :--- | :--- |
| `Super + Return` | Spawn Kitty terminal |
| `Super + Space` | Open application launcher (Fuzzel) |
| `Super + B` | Open wallpaper picker |
| `Super + C` | Launch VS Code |
| `Super + A` | Launch Antigravity IDE |
| `Super + Shift + Q` | Close active window |
| `Super + Shift + F` | Toggle fullscreen |
| `Super + 1..9` | Switch to workspace |
| `Super + Shift + 1..9` | Move window to workspace |

---

## Installation

### 1. Clone the repository

```sh
git clone https://github.com/sid-lakhani/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
```

### 2. Install dependencies

```sh
sudo pacman -S --needed - < packages/pacman.txt
```

Install AUR dependencies (including `quickshell-git`) using your preferred AUR helper.

### 3. Deploy configurations

Preview symlinks:

```sh
./scripts/stow.sh --simulate
```

Apply symlinks:

```sh
./scripts/stow.sh
```

---

## Credits & Acknowledgements

- **[Caelestia Shell](https://github.com/caelestia-dots/caelestia):** Desktop shell foundation, Wayland widgets, and Material You color generation.
- **[Diego Malagrida (pocket-dots)](https://github.com/diegoMalagrida/pocket-dots):** Concept and inspiration for the wallpaper-adaptive terminal sprite engine.
- **[Hyprland](https://hyprland.org/):** Dynamic tiling Wayland compositor.
