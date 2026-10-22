#!/bin/bash


# Проверка прав суперпользователя
if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: модуль установки kitty должен вызываться из-под root" >&2
    # Возвращаем ошибку, если вызван через source; перенаправляем stderr, чтобы не было шума при exit
    return 1 2>/dev/null
fi

if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
    echo "Ошибка: запустите установщик через sudo от обычного пользователя" >&2
    return 1
fi

# getent учитывает домашний каталог из учётной записи, без вычисления через eval.
USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
    echo "Домашний каталог пользователя $SUDO_USER не найден" >&2
    return 1
fi


echo "Installing ranger and configuring it for image previews in kitty terminal..."

# Устанавливаем пакеты для kitty. Если они уже установлены, то pacman их пропускает
pacman -S --needed --noconfirm ranger kitty extra/kitty-shell-integration extra/kitty-terminfo extra/python-pillow extra/wl-clipboard

# Каталоги, перенаправления и sed выполняются от пользователя, чтобы не создавать root-owned файлы.
runuser -u "$SUDO_USER" -- env HOME="$USER_HOME" XDG_CONFIG_HOME="$USER_HOME/.config" bash <<'BASH'
set -euo pipefail
USER_HOME="$HOME"
cd -- "$USER_HOME"

# Путь к конфигу Kitty для пользователя
KITTY_CONF="$USER_HOME/.config/kitty/kitty.conf"

# Создаем директорию, если её нет
mkdir -p "$USER_HOME/.config/kitty"

# Используем heredoc для читаемости многострочного текста
cat > "$KITTY_CONF" << 'EOF'
# Tab bar settings
tab_bar_style powerline
tab_powerline_style round
tab_bar_min_tabs 1

# Wayland integration
wayland_titlebar_color system

# Font settings
font_family family="Fira Code"
font_size 12
bold_font auto
italic_font auto
bold_italic_font auto

# Appearance
background_opacity 0.9
foreground #f8f8f2
background #000000
url_color #d65c9d
term xterm-256color

# Cursor
cursor_shape beam
cursor_shape_unfocused hollow
cursor_trail 6
cursor #cccccc
cursor_blink_interval -1
cursor_trail_decay 0.1 0.3
cursor_stop_blinking_after 15.0

# Behavior
mouse_hide_wait 3.0
scrollback_lines 10000
scrollbar scrolled
remember_window_size yes
initial_window_width 850
initial_window_height 600
window_margin_width 4
confirm_os_window_close -1
strip_trailing_spaces smart
bell_on_tab "🔔 "
notify_on_cmd_finish always

# Shell
shell zsh
shell_integration enabled
EOF

echo "Конфигурация Kitty записана в $KITTY_CONF"

#домашняя директория пользователя содержиться в $USER_HOME
echo "Домашняя директория пользователя: $USER_HOME"

#Копируем конфигурационные файлы ranger
echo "Copying ranger configuration files..."

mkdir -p "$USER_HOME/.config/ranger"
ranger --copy-config=all

echo "Ranger configuration"

rcconf="$USER_HOME/.config/ranger/rc.conf"
metpreview="kitty"

# Проверка существования файла rc.conf
if [[ -f "$rcconf" ]]; then
    # Настройка preview_images
    if grep -Eq "^set[[:space:]]+preview_images([[:space:]]|$)" "$rcconf"; then
        if grep -Eq "^set[[:space:]]+preview_images[[:space:]]+true[[:space:]]*$" "$rcconf"; then
            echo "set preview_images true already exists in $rcconf."
        else
            sed -i -E 's/^set[[:space:]]+preview_images([[:space:]].*)?$/set preview_images true/' "$rcconf"
            echo "Updated set preview_images to true in $rcconf."
        fi
    else
        echo "set preview_images true" >> "$rcconf"
        echo "Added set preview_images true to $rcconf."
    fi
    
    # Настройка preview_images_method
    if grep -Eq "^set[[:space:]]+preview_images_method([[:space:]]|$)" "$rcconf"; then
        if grep -Eq "^set[[:space:]]+preview_images_method[[:space:]]+$metpreview[[:space:]]*$" "$rcconf"; then
            echo "set preview_images_method $metpreview already exists in $rcconf."
        else
            sed -i -E "s/^set[[:space:]]+preview_images_method([[:space:]].*)?$/set preview_images_method $metpreview/" "$rcconf"
            echo "Updated set preview_images_method to $metpreview in $rcconf."
        fi
    else
        echo "set preview_images_method $metpreview" >> "$rcconf"
        echo "Added set preview_images_method $metpreview to $rcconf."
    fi
    
    echo "kitty terminal installed and ranger configured with image previews."
else
    echo "Error: $rcconf not found."
fi
BASH

# Проверить нужно файлы
# ~/.config/kitty/kitty.conf
# font_family family="Fira Code"
# shell zsh
# tab_bar_style powerline

# ~/.config/ranger/rc.conf
# set preview_images_method kitty

