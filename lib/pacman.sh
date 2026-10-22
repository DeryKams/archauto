#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: модуль для настройки pacman должен вызываться из-под root" >&2
    # Возвращаем ошибку, если вызван через source; перенаправляем stderr, чтобы не было шума при exit
    return 1 2>/dev/null
fi

# Путь до конфига Pacman
pacman_config="/etc/pacman.conf"

if ! grep -Eq '^[[:space:]]*\[options\][[:space:]]*$' "$pacman_config"; then
    echo "Секция [options] не найдена в $pacman_config; файл не изменён" >&2
    return 1
fi

# Удаляем прежние активные и закомментированные значения только в [options].
# Вставка после заголовка работает и при отсутствии параметров; повторный запуск не создаёт дублей.
sed -i -E '
/^[[:space:]]*\[options\][[:space:]]*$/,/^[[:space:]]*\[/ {
    /^[[:space:]]*#?[[:space:]]*(ParallelDownloads|Color|ILoveCandy)([[:space:]=]|$)/d
    /^[[:space:]]*\[options\][[:space:]]*$/a\
ParallelDownloads = 10\
Color\
ILoveCandy
}
' "$pacman_config"

echo "Настроена секция [options]: ParallelDownloads = 10, Color, ILoveCandy"
