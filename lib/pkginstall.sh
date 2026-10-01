#!/bin/bash

# Проверка прав суперпользователя
if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: модуль установки микрокода должен вызываться из-под root" >&2
    # Возвращаем ошибку, если вызван через source; перенаправляем stderr, чтобы не было шума при exit
    return 1 2>/dev/null
fi

# Пример подключения в основном скрипте:
# if [[ -f "./lib/pkginstall.sh" ]]; then
#     source "./lib/pkginstall.sh"
# else
#     echo "Модуль пакетов отсутствует в папке lib или нет доступа" >&2
# fi

# Скрипт установки пакетов из pacman

 # Установка шрифтов
    pacman -S --needed --noconfirm ttf-dejavu noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-liberation ttf-fira-code ttf-jetbrains-mono ttf-hack ttf-nerd-fonts-symbols noto-fonts-extra powerline-fonts
    # установка системных утилит
    pacman -S --needed --noconfirm base-devel bash-completion git wget openssh networkmanager pacman-contrib cpupower power-profiles-daemon apparmor ufw gufw iptables fail2ban libpwquality reflector
    # Установка игровых пакетов
    pacman -S --needed --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon gamemode lib32-gamemode steam pavucontrol
    # Рабочая среда KDE
    pacman -S --needed --noconfirm plasma-sdk kio-extras plasma-browser-integration filelight krdc
    # CMD utilities
    pacman -S --needed --noconfirm ripgrep bat lsd duf dust gping fastfetch kitty bottom dos2unix jq yq fzf rclone extra/irqbalance extra/libqalculate htop ghostscript fwupd fwupd-docs github-cli genact extra/wl-clipboard extra/traceroute extra/uv 
    # disk management
    pacman -S --needed --noconfirm ntfs-3g timeshift unrar zip 7zip
    # additional packages
    pacman -S --needed --noconfirm vlc mpv tor torbrowser-launcher nyx chromium  gwenview qbittorrent obsidian flameshot krusader libreoffice-fresh-ru okular man-pages man-pages-ru qrca kfind kdenlive
    # codec for vlc mpv
    pacman -S --needed --noconfirm gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly vlc-plugin-ffmpeg
    
    # если используется ядро hardened, то нужно установить заголовки - extra/linux-hardened-headers
    # поддержка старых видеокарт - xf86-video-ati
    