#!/bin/bash

# Проверка прав суперпользователя
if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: модуль установки микрокода должен вызываться из-под root" >&2
    # Возвращаем ошибку, если вызван через source; перенаправляем stderr, чтобы не было шума при exit
    return 1 2>/dev/null
fi

# Пример подключения в основном скрипте:
# if [[ -f "./lib/mkinitcpio.sh" ]]; then
#     source "./lib/mkinitcpio.sh"
# else
#     echo "Модуль установки микрокода отсутствует в папке lib или нет доступа" >&2
# fi

echo "Обновление микрокода"

# Выбор пакета микрокода по вендору CPU 
if grep -qm1 "AuthenticAMD" /proc/cpuinfo; then
    # -q — тихий режим, без вывода, возвращает лишь 0 или 1
    # -m1 — прекращает поиск после первой найденной строки

    # Если микрокод AMD, то пакет amd-ucode
    ucode_pkg="amd-ucode"
elif grep -qm1 "GenuineIntel" /proc/cpuinfo; then
    # если Intel - intel-ucode
    ucode_pkg="intel-ucode"
else
    # иначе пустая строка
    ucode_pkg=""
fi

if [ -n "$ucode_pkg" ]; then
# Ставим микрокод, если не установлен
    pacman -S --needed --noconfirm "$ucode_pkg"
    
    # Добавление микрокода
    # Хук microcode обязан быть в HOOKS, иначе микрокод не попадёт в initramfs
    if ! grep -qE '^HOOKS=.*\bmicrocode\b' /etc/mkinitcpio.conf; then
        echo "В HOOKS не найден хук microcode, добавляем его"
        sed -i 's/^HOOKS=(\(.*\))/HOOKS=(\1 microcode)/' /etc/mkinitcpio.conf
    fi
    
    mkinitcpio -P
    
    # Регенерация конфига — только если загрузчик реально GRUB.
    # rEFInd и systemd-boot сканируют /boot сами, им ничего не нужно.
    if command -v grub-mkconfig >/dev/null 2>&1; then
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
else
    echo "Не удалось определить вендора CPU, микрокод пропущен"
fi