#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: модуль настройки sysctl должен вызываться из-под root" >&2
    # Возвращаем ошибку, если вызван через source; перенаправляем stderr, чтобы не было шума при exit
    return 1 2>/dev/null
fi

# TODO Перенести настройку reflector в отдельный модуль