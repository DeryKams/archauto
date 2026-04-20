#!/bin/bash
set -e

USER_NAME="${SUDO_USER:?Запускай через sudo от обычного пользователя}"
SUDOERS_FILE="/etc/sudoers.d/99-paru-${USER_NAME}"

# Даём пользователю право ставить пакеты через pacman без второго пароля
printf '%s ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/pacman-key\n' "$USER_NAME" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"
visudo -cf "$SUDOERS_FILE" >/dev/null

# В конце всегда удаляем временное правило
trap 'rm -f "$SUDOERS_FILE"' EXIT

# Запускаем paru от обычного пользователя
# --skipreview убирает "Proceed to review?"
# --sudoloop удерживает sudo-сессию во время долгой сборки
sudo -u "$USER_NAME" paru -S --needed --noconfirm --skipreview --sudoloop \
      alacritty fuzzel mako niri neowall-git swayidle swaylock wl-clipboard-history-git xdg-desktop-portal-gnome xorg-xwayland  xwayland-satellite matugen  cava dms-shell-niri qt6-multimedia-ffmpeg noctalia-shell-git noctalia-qs-git pcmanfm-qt gvfs qt6ct kvantum nohang-git aur/minq-ananicy-git aur/stacer-bin xdman8-beta-git firefox-extension-xdman8-browser-monitor-bin aur/php-codesniffer-phpcsutils aur/php-codesniffer-phpcsextra visual-studio-code-bin fastfetch-git flameshot-git
