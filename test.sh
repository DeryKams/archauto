#!/bin/bash
set -e

# CMD utilities
    pacman -S --needed --noconfirm \
        ripgrep bat lsd duf dust gping dos2unix jq yq \
        fzf rclone irqbalance libqalculate htop \ wl-clipboard nano \ vim

# установка системных утилит
pacman -S --needed --noconfirm \
        base-devel bash-completion git wget openssh networkmanager pacman-contrib \
        cpupower power-profiles-daemon apparmor ufw gufw iptables-nft \
        ghostscript fail2ban libpwquality reflector \
        pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack \
        upower \
        bluez bluez-utils \

sudo pacman -S --needed --noconfirm \
  niri xorg-xwayland \
  greetd greetd-regreet cage \
  xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk xwayland-satellite \
  
  fuzzel mako swayidle swaylock matugen cava \
  gvfs qt6ct qt6-multimedia-ffmpeg kvantum alacritty

if ! command -v paru >/dev/null 2>&1; then
    sudo pacman -S --noconfirm --needed rust rust-wasm cargo debugedit fakeroot pkgconf openssl git base-devel

    sudo -u "$SUDO_USER" bash -c '
        cd ~ || exit 1
        git clone https://aur.archlinux.org/paru.git
        cd paru || exit 1
        makepkg -si --noconfirm
        cd ~ || exit 1
        rm -rf paru
    '
fi

sudo -u "$SUDO_USER" bash -c "
cd ~
paru -S --needed --noconfirm neowall-git wl-clipboard-history-git noctalia-shell pcmanfm-qt \
      nohang-git minq-ananicy-git stacer-bin xdman8-beta-git \
      php-codesniffer-phpcsutils php-codesniffer-phpcsextra \
    "
      # firefox-extension-xdman8-browser-monitor-bin visual-studio-code-bin fastfetch-git 

# Установка и настройка greetd для входа в niri

echo "Настраиваем greetd для входа через ReGreet"

# Включаем сервис логин-менеджера
systemctl enable greetd.service

cat > /etc/greetd/regreet.toml <<'EOF'
[background]
path = "/usr/share/backgrounds/greeter.jpg"
fit = "Cover"

[GTK]
application_prefer_dark_theme = true
cursor_theme_name = "Adwaita"
cursor_blink = true
font_name = "Inter 12"
icon_theme_name = "Adwaita"
theme_name = "Adwaita"

[appearance]
greeting_msg = "Welcome"

[commands]
reboot = ["systemctl", "reboot"]
poweroff = ["systemctl", "poweroff"]

[widget.clock]
format = "%a %H:%M"
resolution = "500ms"
label_width = 150
EOF

cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "dbus-run-session cage -s -mlast -- regreet"
user = "greeter"
EOF

enable_service(){

    local service_name="$1"
    #$1 - это первый аргумент, который передается функции
    # local - объявляем переменную, которая будет локально внутри данной функции. К примеру, чтобы она не перезаписывала глобальные

    if systemctl enable --now "$service_name"; then
        echo "Service $service_name enabled and started successfully."

        if systemctl is-active --quiet "$service_name"; then
            # systemctl is-active - специально созданная команда для проверки статуса службы
            # --quiet - означает, что вывод будет без лишней информации, только код возврата
            echo "Service $service_name is running."
        else
            echo "Service $service_name is not running after enabling."
            journalctl -n 5 -u "$service_name" --no-pager
        fi
    else
        echo "Failed to enable or start service $service_name. It may already be running or not exist."
        journalctl -n 10 -u "$service_name" --no-pager
    fi


}
# проверяем статусы служб
#Объявляем массив для служб
# -a - объявляем, что это массив
# -r - объявляем, что массив является неизменяемым, то есть только для чтения
declare -a LIST_SERVICE_CHECK=(
    "reflector.service"
    "reflector.timer"
    "fail2ban.service"
    "nohang-desktop.service"
    "ananicy.service"
    "irqbalance.service"
    "greetd.service"
    "NetworkManager.service"
    "power-profiles-daemon.service"
    "upower.service"
    "bluetooth.service"
)


for item in "${LIST_SERVICE_CHECK[@]}"; do
    #for - это цикл, который перебирает элементы массива
    # item - переменная, которую мы задали конкретно для данного цикла. Туда "кладется" каждый элемент массива по очереди
    # "" - нужны для того, чтобы службы в которых присутствуют пробелы были восприняты, как единое целое, а не ка кнесколько служб
    # [@] - квадрытные скобки нужны для обращения к элементам массива, а знак @ - для обращения ко всем элементам массива
    # если просто объявить $LIST_SERVICE_CHECK, то bash возьмет только первый элемент массива, а не все
    # если использовать [*], то будет взят весь массив, как единое целое, то есть все элементы массива будут восприниматься как одна строка
    enable_service "$item"
    # enable_service - функция, которую мы ранее определили и которая берет элемент item и выполняет операции
done