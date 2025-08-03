#!/bin/bash

echo "Installing ranger and configuring it for image previews in kitty terminal..."
pacman -S --needed --noconfirm ranger kitty extra/kitty-shell-integration extra/kitty-terminfo extra/python-pillow

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
