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
  neovim-git