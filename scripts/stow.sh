#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

packages=(
  bin quickshell caelestia fish zsh hypr foot kitty fuzzel
  fastfetch btop nvim gtk wallpapers
)

if [[ "${1:-}" == "--simulate" ]]; then
  exec stow --simulate --verbose --target="$HOME" "${packages[@]}"
fi

stow --target="$HOME" "${packages[@]}"
