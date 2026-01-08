#!/bin/bash

# Обновляем систему
pacman -Syu
# устанавливаем zsh и дополнительные пакеты
pacman -S --needed --noconfirm zsh zsh-completions git curl fzf powerline-fonts nerd-fonts-hack

chsh -s $(which zsh)
# chsh — это команда, которая меняет оболочку входа пользователя в систему
echo $SHELL