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
"
# Необходимо экранировать кавычки внутри команды bash -c, если открывается с двойных кавычек

# Установка темы Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $USER_HOME/.oh-my-zsh/custom/plugins/you-should-use
git clone https://github.com/Aloxaf/fzf-tab $USER_HOME/.oh-my-zsh/custom/plugins/fzf-tab
# Replace zsh's default completion selection menu with fzf

sudo -u "$SUDO_USER" bash << 'EOF'
# Создаем симлинки на системные плагины
ln -sf /usr/share/zsh/plugins/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/
ln -sf /usr/share/zsh/plugins/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/
ln -sf /usr/share/zsh/plugins/zsh-completions ~/.oh-my-zsh/custom/plugins/
EOF

if [[ -f  $USER_HOME/.zshrc ]]; then  
# изменяем тему в .zshrc на powerlevel10k
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' $USER_HOME/.zshrc
# добавляем плагины
    sed -i 's/plugins=.*/plugins=( git zsh-syntax-highlighting zsh-autosuggestions zsh-completions extract you-should-use fzf-tab)/' $USER_HOME/.zshrc
else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> $USER_HOME/.zshrc
fi


echo "Для вступления изменений в силу, перезайдите в систему или выполните команду: exec zsh"
