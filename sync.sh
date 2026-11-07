#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Syncing configs to dotfiles..."

for dir in foot sway rofi yazi; do
  if [ -d ~/.config/"$dir" ]; then
    mkdir -p "$DOTFILES_DIR/$dir"
    cp -r ~/.config/"$dir"/. "$DOTFILES_DIR/$dir"/
    echo "    Synced $dir"
  fi
done

if [ -f ~/.bashrc ]; then
  cp ~/.bashrc "$DOTFILES_DIR/.bashrc"
  echo "    Synced .bashrc"
fi

if [ -d /etc/greetd ]; then
  mkdir -p "$DOTFILES_DIR/greetd"
  sudo cp -r /etc/greetd/. "$DOTFILES_DIR/greetd"/
  echo "    Synced greetd"
fi

echo ""
echo "==> Done."
cd "$DOTFILES_DIR"
git add .
git commit -m "batman"
git push origin main
