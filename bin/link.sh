#!/usr/bin/env bash
set -euo pipefail

repo="${XDG_CONFIG_REPO:-$HOME/nixos-config}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
bin_home="${XDG_BIN_HOME:-$HOME/.local/bin}"

link_file() {
    local source="$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"
    ln -sfn "$source" "$target"
}

link_file "$repo/dotfiles/alacritty/alacritty.toml" \
          "$config_home/alacritty/alacritty.toml"

link_file "$repo/dotfiles/bluetuith/bluetuith.conf" \
          "$config_home/bluetuith/bluetuith.conf"

link_file "$repo/dotfiles/gh/config.yml" \
          "$config_home/gh/config.yml"

link_file "$repo/dotfiles/helix/config.toml" \
          "$config_home/helix/config.toml"

link_file "$repo/dotfiles/helix/themes/autumn_night_transparent.toml" \
          "$config_home/helix/themes/autumn_night_transparent.toml"

link_file "$repo/dotfiles/hypr/hyprland.conf" \
          "$config_home/hypr/hyprland.conf"

link_file "$repo/dotfiles/hypr/shaders/eink.glsl" \
          "$config_home/hypr/shaders/eink.glsl"

link_file "$repo/dotfiles/mimeapps.list" \
          "$config_home/mimeapps.list"

link_file "$repo/dotfiles/nix/nix.conf" \
          "$config_home/nix/nix.conf"

link_file "$repo/dotfiles/nvim/init.lua" \
          "$config_home/nvim/init.lua"

link_file "$repo/dotfiles/waybar/compact.jsonc" \
          "$config_home/waybar/compact.jsonc"

link_file "$repo/dotfiles/waybar/expanded.jsonc" \
          "$config_home/waybar/expanded.jsonc"

link_file "$repo/dotfiles/waybar/style.css" \
          "$config_home/waybar/style.css"

link_file "$repo/dotfiles/waybar/scripts/cpu-status" \
          "$config_home/waybar/scripts/cpu-status"

link_file "$repo/dotfiles/waybar/scripts/memory-status" \
          "$config_home/waybar/scripts/memory-status"

link_file "$repo/dotfiles/waybar/scripts/nvidia-status" \
          "$config_home/waybar/scripts/nvidia-status"

link_file "$repo/dotfiles/zathura/zathurarc.conf" \
          "$config_home/zathura/zathurarc.conf"

mkdir -p "$bin_home"

for command in toggle-eink toggle-theme toggle-waybar; do
    link_file "$repo/bin/$command" "$bin_home/$command"
done

# Preserve the currently selected Waybar mode when possible.
if [[ ! -L "$config_home/waybar/config" ]]; then
    link_file "$config_home/waybar/expanded.jsonc" \
              "$config_home/waybar/config"
fi
