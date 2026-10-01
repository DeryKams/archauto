#!/bin/bash


# Проверка прав суперпользователя
if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: модуль установки kitty должен вызываться из-под root" >&2
    # Возвращаем ошибку, если вызван через source; перенаправляем stderr, чтобы не было шума при exit
    return 1 2>/dev/null
fi

# Путь до папки пользователя
USER_HOME=$(eval echo ~$SUDO_USER)


echo "Installing ranger and configuring it for image previews in kitty terminal..."

# Устанавливаем пакеты для kitty. Если они уже установлены, то pacman их пропускает
pacman -S --needed --noconfirm ranger kitty extra/kitty-shell-integration extra/kitty-terminfo extra/python-pillow extra/wl-clipboard

# Добавляем конфигурацию к kitty

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

# Исправляем права доступа, так как файл создан от root
chown "$SUDO_USER:$(id -gn "$SUDO_USER")" "$KITTY_CONF"
echo "Конфигурация Kitty записана в $KITTY_CONF"
# Добавляем конфигурацию к kitty


#Получаем домашнюю директорию пользователя
if [[ $EUID -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
    #$EUID - переменная, которая содержит ID текущего пользователя
    # -eq - аналог == для других языков
    # 0 - это ID суперпользователя (root)
    # [[ $EUID -eq 0 ]] - условие: если текущий пользователь - суперпользователь
    # && - логическое "и"; оба условия должны быть истинными
    # -n - проверка что строка не пустая
    # $SUDO_USER - переменная в которой храниться имя пользователя, который  запустил команду через sudo
    # [[ -n "$SUDO_USER" ]] - проверяется, что в переменной пользователя, который запустил через sudo, не пустая
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    # getent - команда, которая позволяет получать записи из системных баз данных Linux, к примеру passwd, group или hosts
    # Синтаксис: getent <база данных> <ключ> - getent passwd "$SUDO_USER"
    # getent passwd "$SUDO_USER" - ищем в справочнике passwd пользователя, который запустил команду через sudo
    # | (pipe) — это оператор, который перенаправляет вывод одной команды (getent) на вход другой
    # cut - вывод команды в поток
    # -d: - разделитель, который используется в файле passwd (записи разделены двоеточиями)
    # -f6 - вывод шестого поля, которое соответствует домашней директории пользователя
else
    USER_HOME="$HOME"
fi

#домашняя директория пользователя содержиться в $USER_HOME
echo "Домашняя директория пользователя: $USER_HOME"

#Копируем конфигурационные файлы ranger
echo "Copying ranger configuration files..."

mkdir -p "$USER_HOME/.config/ranger"
chown "$SUDO_USER":"$(id -gn "$SUDO_USER")" "$USER_HOME/.config/ranger"
sudo -u "$SUDO_USER" ranger --copy-config=all

echo "Ranger configuration"

rcconf="$USER_HOME/.config/ranger/rc.conf"
metpreview="kitty"

# Проверка существования файла rc.conf
if [[ -f "$rcconf" ]]; then
    # Настройка preview_images
    if grep -q "^set preview_images" "$rcconf"; then
        if grep -q "^set preview_images true" "$rcconf"; then
            echo "set preview_images true already exists in $rcconf."
        else
            sed -i 's/^set preview_images.*/set preview_images true/' "$rcconf"
            echo "Updated set preview_images to true in $rcconf."
        fi
    else
        echo "set preview_images true" >> "$rcconf"
        echo "Added set preview_images true to $rcconf."
    fi
    
    # Настройка preview_images_method
    if grep -q "^set preview_images_method" "$rcconf"; then
        if grep -q "^set preview_images_method $metpreview" "$rcconf"; then
            echo "set preview_images_method $metpreview already exists in $rcconf."
        else
            sed -i "s/^set preview_images_method.*/set preview_images_method $metpreview/" "$rcconf"
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

# Проверить нужно файлы
# ~/.config/kitty/kitty.conf
# font_family family="Fira Code"
# shell zsh
# tab_bar_style powerline

# ~/.config/ranger/rc.conf
# set preview_images_method kitty

