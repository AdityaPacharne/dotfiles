#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd() { command -v "$1" &>/dev/null; }

echo "==> Setup starting..."

# ─── Configs ──────────────────────────────────────────────────────────────────
mkdir -p ~/.config
for dir in foot waybar sway swaylock rofi yazi; do
  [ -d "$DOTFILES_DIR/$dir" ] && cp -r "$DOTFILES_DIR/$dir"/. ~/.config/"$dir"/ && echo "    Copied $dir"
done

[ -d "$DOTFILES_DIR/greetd" ] && sudo mkdir -p /etc/greetd && sudo cp -r "$DOTFILES_DIR/greetd"/. /etc/greetd/

# ─── Repos ────────────────────────────────────────────────────────────────────
cmd librewolf || sudo dnf config-manager addrepo --from-repofile=https://repo.librewolf.net/librewolf.repo

# ─── DNF packages ─────────────────────────────────────────────────────────────
sudo dnf install -y \
  foot udiskie ffmpeg mpv keepassxc blueman brightnessctl powertop \
  git rofi syncthing neovim tuned papirus-icon-theme greetd librewolf

# ─── Tuned ────────────────────────────────────────────────────────────────────
systemctl is-enabled tuned &>/dev/null || {
  sudo systemctl enable --now tuned
  sudo tuned-adm profile throughput-performance
}

# ─── Rust ─────────────────────────────────────────────────────────────────────
cmd rustc || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# ─── tuigreet ─────────────────────────────────────────────────────────────────
if ! cmd tuigreet; then
  sudo dnf install -y gcc make
  TMP=$(mktemp -d)
  git clone https://github.com/tuigreet/tuigreet "$TMP/tuigreet"
  cargo build --release --manifest-path "$TMP/tuigreet/Cargo.toml"
  sudo cp "$TMP/tuigreet/target/release/tuigreet" /usr/local/bin/
  sudo restorecon -v /usr/local/bin/tuigreet
  rm -rf "$TMP"
fi

# ─── Yazi ─────────────────────────────────────────────────────────────────────
if ! cmd yazi; then
  TMP=$(mktemp -d)
  curl -L https://github.com/sxyazi/yazi/releases/latest/download/yazi-aarch64-unknown-linux-gnu.tar.gz \
    | tar -xz -C "$TMP"
  sudo mv "$TMP"/yazi-aarch64-unknown-linux-gnu/{yazi,ya} /usr/local/bin/
  rm -rf "$TMP"
fi

# ─── Yazi .desktop ────────────────────────────────────────────────────────────
YAZI_DESKTOP="$HOME/.local/share/applications/yazi.desktop"
[ -f "$YAZI_DESKTOP" ] || mkdir -p ~/.local/share/applications && cat > "$YAZI_DESKTOP" << 'EOF'
[Desktop Entry]
Name=Yazi
Exec=footclient -e yazi
Terminal=false
Type=Application
Categories=System;FileManager;
EOF

# ─── Fonts ────────────────────────────────────────────────────────────────────
if ! fc-list | grep -qi "JetBrainsMono"; then
  mkdir -p ~/.local/share/fonts
  TMP=$(mktemp -d)
  curl -fLo "$TMP/JetBrainsMono.tar.xz" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
  tar -xf "$TMP/JetBrainsMono.tar.xz" -C ~/.local/share/fonts
  fc-cache -f
  rm -rf "$TMP"
fi

# ─── Cursor ───────────────────────────────────────────────────────────────────
if [ ! -d ~/.local/share/icons/Bibata-Modern-Classic ]; then
  TMP=$(mktemp -d)
  curl -L https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz \
    | tar -xJ -C "$TMP"
  mkdir -p ~/.local/share/icons
  cp -r "$TMP/Bibata-Modern-Classic" ~/.local/share/icons/
  rm -rf "$TMP"
fi

# ─── Icon theme ───────────────────────────────────────────────────────────────
gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | grep -q "Papirus-Dark" || \
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'

# ─── .bashrc ──────────────────────────────────────────────────────────────────
[ -f "$DOTFILES_DIR/.bashrc" ] && cp "$DOTFILES_DIR/.bashrc" ~/.bashrc

grep -q "EDITOR=nvim" ~/.bashrc || echo 'export EDITOR=nvim
export VISUAL=nvim' >> ~/.bashrc

grep -q '\.cargo/env' ~/.bashrc || echo 'source "$HOME/.cargo/env"' >> ~/.bashrc

# ─── Console font ─────────────────────────────────────────────────────────────
grep -q "FONT=sun12x22" /etc/vconsole.conf 2>/dev/null || \
  echo 'FONT=sun12x22' | sudo tee -a /etc/vconsole.conf

# ─── Browser ──────────────────────────────────────────────────────────────────
xdg-settings get default-web-browser 2>/dev/null | grep -q "librewolf" || \
  xdg-settings set default-web-browser librewolf.desktop

# ─── greetd ───────────────────────────────────────────────────────────────────
systemctl is-enabled greetd &>/dev/null || sudo systemctl enable --now greetd

echo ""
echo "==> Done! Restart your session."
