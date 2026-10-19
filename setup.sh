#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Starting setup..."

# ─── Helper ───────────────────────────────────────────────────────────────────

command_exists() { command -v "$1" &>/dev/null; }

# ─── Copy Configs ─────────────────────────────────────────────────────────────

echo "==> Copying config files..."
mkdir -p ~/.config

for dir in foot waybar sway swaylock rofi yazi; do
  if [ -d "$DOTFILES_DIR/$dir" ]; then
    mkdir -p ~/.config/"$dir"
    cp -r "$DOTFILES_DIR/$dir"/. ~/.config/"$dir"/
    echo "    Copied $dir"
  else
    echo "    Skipping $dir (not found in dotfiles)"
  fi
done

# ─── greetd config ────────────────────────────────────────────────────────────

if [ -d "$DOTFILES_DIR/greetd" ]; then
  echo "==> Setting up greetd config..."
  sudo mkdir -p /etc/greetd
  sudo cp -r "$DOTFILES_DIR/greetd"/. /etc/greetd/
  echo "    Copied greetd config"
else
  echo "    Skipping greetd config (not found in dotfiles)"
fi

# ─── DNF packages ─────────────────────────────────────────────────────────────

echo "==> Installing DNF packages..."
DNF_PACKAGES=(foot udiskie ffmpeg mpv blueman network-manager-applet powertop greetd)

for pkg in "${DNF_PACKAGES[@]}"; do
  if rpm -q "$pkg" &>/dev/null; then
    echo "    $pkg already installed, skipping"
  else
    echo "    Installing $pkg..."
    sudo dnf install -y "$pkg"
  fi
done

# ─── Rust ─────────────────────────────────────────────────────────────────────

if command_exists rustc; then
  echo "==> Rust already installed, skipping"
else
  echo "==> Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

# ─── tuigreet ─────────────────────────────────────────────────────────────────

if command_exists tuigreet; then
  echo "==> tuigreet already installed, skipping"
else
  echo "==> Building tuigreet from source..."
  source "$HOME/.cargo/env"
  sudo dnf install -y gcc make
  TMP_TUIGREET=$(mktemp -d)
  git clone https://github.com/tuigreet/tuigreet "$TMP_TUIGREET/tuigreet"
  cd "$TMP_TUIGREET/tuigreet"
  cargo build --release
  sudo cp target/release/tuigreet /usr/local/bin/tuigreet
  sudo restorecon -v /usr/local/bin/tuigreet
  cd "$DOTFILES_DIR"
  rm -rf "$TMP_TUIGREET"
  echo "    tuigreet installed"
fi

# ─── Yazi binary ──────────────────────────────────────────────────────────────

if command_exists yazi; then
  echo "==> Yazi already installed, skipping"
else
  echo "==> Installing Yazi..."
  TMP_YAZI=$(mktemp -d)
  curl -L https://github.com/sxyazi/yazi/releases/latest/download/yazi-aarch64-unknown-linux-gnu.tar.gz -o "$TMP_YAZI/yazi.tar.gz"
  tar -xf "$TMP_YAZI/yazi.tar.gz" -C "$TMP_YAZI"
  sudo mv "$TMP_YAZI"/yazi-aarch64-unknown-linux-gnu/yazi /usr/local/bin/
  sudo mv "$TMP_YAZI"/yazi-aarch64-unknown-linux-gnu/ya /usr/local/bin/
  rm -rf "$TMP_YAZI"
  echo "    Yazi installed"
fi

# ─── Yazi .desktop file ───────────────────────────────────────────────────────

YAZI_DESKTOP="$HOME/.local/share/applications/yazi.desktop"
if [ -f "$YAZI_DESKTOP" ]; then
  echo "==> Yazi .desktop already exists, skipping"
else
  echo "==> Creating Yazi .desktop file..."
  mkdir -p ~/.local/share/applications
  cat > "$YAZI_DESKTOP" << 'EOF'
[Desktop Entry]
Name=Yazi
Exec=footclient -e yazi
Terminal=false
Type=Application
Categories=System;FileManager;
EOF
  echo "    Created yazi.desktop"
fi

# ─── JetBrains Mono Nerd Font ─────────────────────────────────────────────────

if fc-list | grep -qi "JetBrainsMono"; then
  echo "==> JetBrains Mono Nerd Font already installed, skipping"
else
  echo "==> Installing JetBrains Mono Nerd Font..."
  mkdir -p ~/.local/share/fonts
  TMP_FONT=$(mktemp -d)
  curl -fLo "$TMP_FONT/JetBrainsMono.tar.xz" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
  tar -xf "$TMP_FONT/JetBrainsMono.tar.xz" -C ~/.local/share/fonts
  fc-cache -f
  rm -rf "$TMP_FONT"
  echo "    JetBrains Mono Nerd Font installed"
fi

# ─── Bibata Cursor ────────────────────────────────────────────────────────────

if [ -d ~/.local/share/icons/Bibata-Modern-Classic ]; then
  echo "==> Bibata cursor already installed, skipping"
else
  echo "==> Installing Bibata cursor..."
  TMP_CURSOR=$(mktemp -d)
  curl -L https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz \
    -o "$TMP_CURSOR/Bibata.tar.xz"
  tar -xf "$TMP_CURSOR/Bibata.tar.xz" -C "$TMP_CURSOR"
  mkdir -p ~/.local/share/icons
  cp -r "$TMP_CURSOR/Bibata-Modern-Classic" ~/.local/share/icons/
  rm -rf "$TMP_CURSOR"
  echo "    Bibata cursor installed"
fi

# ─── .bashrc exports ──────────────────────────────────────────────────────────

echo "==> Setting up .bashrc exports..."
if ! grep -q "EDITOR=nvim" ~/.bashrc; then
  echo 'export EDITOR=nvim' >> ~/.bashrc
  echo 'export VISUAL=nvim' >> ~/.bashrc
  echo "    Added EDITOR/VISUAL exports"
else
  echo "    EDITOR/VISUAL already set, skipping"
fi

if ! grep -q '\.cargo/env' ~/.bashrc; then
  echo 'source "$HOME/.cargo/env"' >> ~/.bashrc
fi

# ─── Console font ─────────────────────────────────────────────────────────────

if grep -q "FONT=sun12x22" /etc/vconsole.conf 2>/dev/null; then
  echo "==> Console font already set, skipping"
else
  echo "==> Setting console font..."
  echo 'FONT=sun12x22' | sudo tee -a /etc/vconsole.conf
  echo "    Console font set"
fi

# ─── Default browser ──────────────────────────────────────────────────────────

if xdg-settings get default-web-browser 2>/dev/null | grep -q "librewolf"; then
  echo "==> Librewolf already default browser, skipping"
else
  echo "==> Setting Librewolf as default browser..."
  xdg-settings set default-web-browser librewolf.desktop
  echo "    Default browser set to Librewolf"
fi

# ─── Enable greetd ────────────────────────────────────────────────────────────

if systemctl is-enabled greetd &>/dev/null; then
  echo "==> greetd already enabled, skipping"
else
  echo "==> Enabling greetd..."
  sudo systemctl enable greetd
  sudo systemctl start greetd
  echo "    greetd enabled and started"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "==> Setup complete! Restart your session for all changes to take effect."
