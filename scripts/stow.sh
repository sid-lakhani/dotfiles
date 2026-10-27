#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

packages=(
  fish zsh hypr caelestia foot fuzzel
  fastfetch btop nvim gtk wallpapers
)

if [[ "${1:-}" == "--simulate" ]]; then
  exec stow --simulate --verbose --target="$HOME" "${packages[@]}"
fi

stow --target="$HOME" "${packages[@]}"
