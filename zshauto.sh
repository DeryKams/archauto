#!/bin/bash

exec > >(tee -a "zshauto.log") 2>&1
set -euo pipefail
ZSHRC="$HOME/.zshrc"
ZSH_THEME="powerlevel10k/powerlevel10k"
pluginszsh="git sudo z fzf colored-man-pages zsh-autosuggestions zsh-syntax-highlighting history-substring-search autocorrect archlinux docker docker-compose sdkman kotlin gradle"
bindfirst="bindkey '^[[A' history-substring-search-up"
bindsecond="bindkey '^[[B' history-substring-search-down"
# git - Алиасы и удобные функции для работы с Git
# archlinux - Короткие псевдонимы для команд `pacman` (например, `pacs` вместо `pacman -S`).
# colored-man-pages - Делает страницы `man` цветными и более читаемыми.
# z - Просто пишите `z часть_имени_папки`, и он перенесет вас в самый часто посещаемый каталог с таким названием
# fzf - Интеграция нечеткого поиска. Теперь **`Ctrl+R`** вызовет интерактивный поиск по истории команд, а **`Ctrl+T`** — поиск файлов в текущем каталоге.
# zsh-autosuggestions - Подсказки команд на основе истории и автодополнения.
# zsh-syntax-highlighting - Подсветка синтаксиса команд в термин
# history-substring-search: Этот плагин кардинально улучшает поиск по истории. Вы начинаете вводить любую часть команды (не обязательно с начала), а затем нажимаете клавиши Вверх/Вниз, чтобы переключаться между всеми совпадениями из вашей истории
# autocorrect: Исправляет незначительные опечатки в командах.
# systemd: Очень полезно для Arch Linux. Добавляет короткие псевдонимы для управления службами systemd. Например, scs apache вместо systemctl status apache
# sdkman - менеджер версий для множества SDK (Software Development Kit) для JVM и не только
# kotlin: Добавляет автодополнение для команд компилятора kotlin и kotlinc
# gradle  Он обеспечивает автодополнение для задач Gradle. Вы можете написать ./gradlew bui и нажать Tab, чтобы он дополнил до build.

# Обновляемся
pacman -Syu --noconfirm
# установка всех пакетов

pacman -S --needed --noconfirm zsh zsh-completions git curl fzf ttf-meslo-nerd-font-powerlevel10k
# chsh — это команда, которая меняет оболочку после входа пользователя в систему
chsh -s $(which zsh)

# обновляем кэш шрифтов
fc-cache -f -v

echo $SHELL
# Установка фреймворка Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Установка внешних плагинов

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/history-substring-search 



# Настройка темы

if [ -f $ZSHRC ]; then
 
sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$ZSH_THEME\"/" $ZSHRC
sed -i "s/^plugins=(.*/plugins=($pluginszsh)/" $ZSHRC
fi
 
if grep -q "" $ZSHRC; then
# Привязка клавиш для history-substring-search. Чтобы history-substring-search заработал на стрелках Вверх/Вниз, добавьте эти строки в конец вашего файла $ZSHRC

echo "$bindfirst" >> $ZSHRC
echo "$bindsecond" >> $ZSHRC
fi
fi
source $ZSHRC






# # Установка SDKMAN
# curl -s "https://get.sdkman.io" | bash
# source "$HOME/.sdkman/bin/sdkman-init.sh"
# # Устанавливаем последнюю версию Java (необходима для Kotlin)
# sdk install java

# # Устанавливаем последнюю версию Kotlin
# sdk install kotlin

# # Устанавливаем последнюю версию Gradle
# sdk install gradle
