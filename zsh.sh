#!/bin/bash

# устанавливаем zsh и дополнительные пакеты
pacman -S --needed --noconfirm zsh zsh-completions git curl fzf powerline-fonts nerd-fonts-hack zsh-syntax-highlighting


chsh -s $(which zsh)
# chsh — это команда, которая меняет оболочку входа пользователя в систему
echo $SHELL

# Установка фреймворка Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
