#!/bin/bash

# устанавливаем zsh и дополнительные пакеты
pacman -S --needed --noconfirm git curl zsh fzf powerline-fonts zsh-syntax-highlighting zsh-autosuggestions zsh-completions


chsh -s $(which zsh)
# chsh — это команда, которая меняет оболочку входа пользователя в систему
echo $SHELL

# Установка фреймворка Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "Для вступления изменений в силу, перезайдите в систему или выполните команду: exec zsh"
