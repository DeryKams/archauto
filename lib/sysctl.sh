#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: модуль настройки sysctl должен вызываться из-под root" >&2
    # Возвращаем ошибку, если вызван через source; перенаправляем stderr, чтобы не было шума при exit
    return 1 2>/dev/null
fi

# Скрипт, который обновляет настройки sysctl для оптимизации использования swap и кэша файловой системы.

# Создаем файл с кастомнымыми настройками sysctl
# Путь до файла настроек
custom_sysctl="/etc/sysctl.d/99-custom.conf"

if [ -f "$custom_sysctl" ]; then
    
    echo "$custom_sysctl уже был ранее создан"
else
    
    touch "$custom_sysctl"
    echo "$custom_sysctl создан"
fi
# Создаем файл с кастомнымыми настройками sysctl


#добавляем vm.swappiness в кастомный sysctl
search_swappiness="vm.swappiness"
# Определяем насколько часто ядро будет использовать swap
new_swappiness="10"


if grep -q "^$search_swappiness" "$custom_sysctl"; then
    
    sed -i "s/^$search_swappiness=.*/$search_swappiness=$new_swappiness/" "$custom_sysctl"
    
    echo "$search_swappiness бы заменен на $new_swappiness"
    
else
    
    echo "$search_swappiness=$new_swappiness" >> "$custom_sysctl"
    echo "$search_swappiness=$new_swappiness был добавлен в конце $custom_sysctl"
fi

#добавляем vm.vfs_cache_pressure в sysctl
search_cash_pressure="vm.vfs_cache_pressure"

# Управляет тем, как агрессивно ядро очищает кэш файловой системы
new_cash_pressure="65"

if grep -q "^$search_cash_pressure" "$custom_sysctl"; then
    
    sed -i "s/^$search_cash_pressure=.*/$search_cash_pressure=$new_cash_pressure/" "$custom_sysctl"
    
    echo "$search_cash_pressure бы заменен на $new_cash_pressure"
    
else
    
    echo "$search_cash_pressure=$new_cash_pressure" >> "$custom_sysctl"
    echo "$search_cash_pressure=$new_cash_pressure бы добавлен в конце $custom_sysctl"
fi

# Применяем настройки sysctl
sysctl --system