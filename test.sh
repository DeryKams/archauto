#!/bin/bash
set -e

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
paru -S --needed --noconfirm alacritty fuzzel mako niri neowall-git swayidle swaylock wl-clipboard-history-git xdg-desktop-portal-gnome xorg-xwayland  xwayland-satellite matugen cava qt6-multimedia-ffmpeg noctalia-shell-git pcmanfm-qt gvfs qt6ct /
      # kvantum nohang-git aur/minq-ananicy-git aur/stacer-bin xdman8-beta-git firefox-extension-xdman8-browser-monitor-bin aur/php-codesniffer-phpcsutils aur/php-codesniffer-phpcsextra visual-studio-code-bin fastfetch-git 
    "

# Установка и настройка greetd для входа в niri
pacman -S --needed --noconfirm greetd greetd-regreet cage

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
