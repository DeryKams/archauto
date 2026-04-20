#!/bin/bash

USER_NAME="${SUDO_USER:-$(logname)}"

# Прогреваем sudo-кеш для обычного пользователя один раз
sudo -u "$USER_NAME" sudo -v

# Дальше paru сможет использовать sudo без повторного запроса пароля
sudo -u "$USER_NAME" paru -S --needed --noconfirm \
neovim-git 