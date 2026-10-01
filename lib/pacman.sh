#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: модуль для настройки pacman должен вызываться из-под root" >&2
    # Возвращаем ошибку, если вызван через source; перенаправляем stderr, чтобы не было шума при exit
    return 1 2>/dev/null
fi

# Путь до конфига Pacman
pacman_config="/etc/pacman.conf"

# Настраиваем количество параллельных загрузок пакетов в pacman.conf
new_parallel_dow="10"

if grep -q "^ParallelDownloads" "${pacman_config}"; then

    sed -i "s/^ParallelDownloads.*/ParallelDownloads = ${new_parallel_dow}/" "${pacman_config}"

    echo "Обновлено: ParallelDownloads = ${new_parallel_dow}"
else
    # Если параметра нет, добавляем его в конец файла

    echo "ParallelDownloads = ${new_parallel_dow}" >> "${pacman_config}"

    echo "Добавлено: ParallelDownloads = ${new_parallel_dow}"
fi
# Настраиваем количество параллельных загрузок пакетов в pacman.conf

# Настраиваем Color для pacman
if grep -q "^#Color" "${pacman_config}"; then
    
    sed -i "s/#Color/Color/" "${pacman_config}"
    echo "Color был включен"
else
    if grep -q "^Color" "${pacman_config}"; then
        
        echo "Color уже включен"
    else
        echo "Color" >> "${pacman_config}"
        
    fi
fi
# Настраиваем Color для pacman

# Настраиваем ILoveCandy для pacman

if grep -q "^ILoveCandy" "${pacman_config}"; then
    #! инвертирует условие
    #-v -инвертирует условие. То есть если НЕ, то условие выполняется
    echo "ILoveCandy уже включен"
else
    
    sed -i "/^Color/a ILoveCandy" "${pacman_config}"
    #-i редактирует файл на месте
    # a/ камманда append в sed, вставляет новую сроку, после найденной строки
    #шаблон вставки: "/что ищем/a что вставляем" "$file"
fi


# Настраиваем ILoveCandy для pacman
