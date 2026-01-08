#!/bin/bash

USER_HOME=$(eval echo ~$SUDO_USER)

# устанавливаем zsh и дополнительные пакеты
pacman -S --needed --noconfirm git curl zsh fzf powerline-fonts zsh-syntax-highlighting zsh-autosuggestions zsh-completions




# Установка фреймворка Oh My Zsh
sudo -u "$SUDO_USER" bash -c "
cd ~
sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended
chsh -s $(which zsh)
# chsh — это команда, которая меняет оболочку входа пользователя в систему
echo "Текущая оболочка: $SHELL"
# Установка темы Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
"
# Необходимо экранировать кавычки внутри команды bash -c, если открывается с двойных кавычек



if [[ -f  $USER_HOME/.zshrc ]]; then  
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' $USER_HOME/.zshrc
else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> $USER_HOME/.zshrc
fi

source $USER_HOME/.zshrc

echo "Для вступления изменений в силу, перезайдите в систему или выполните команду: exec zsh"
