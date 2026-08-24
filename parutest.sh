#!/bin/bash

exec > >(tee -a "parutest.log") 2>&1

user_nosudo="$SUDO_USER"

echo "=== Проверка установлен ли paru ==="

if command -v paru >/dev/null 2>&1; then
    echo "paru уже установлен: $(paru --version)"
    exit 0
fi

echo "paru не найден — начинаем установку"

echo "=== Установка зависимостей ==="
sudo pacman -S --noconfirm --needed rust rust-wasm cargo debugedit fakeroot pkgconf openssl git base-devel

echo "=== Сборка и установка paru из AUR ==="
sudo -u "$user_nosudo" bash -c '
    cd ~ || exit 1
    git clone https://aur.archlinux.org/paru.git
    cd paru || exit 1
    makepkg -si --noconfirm --skippgpcheck
    cd ~ || exit 1
    rm -rf paru
'

echo "=== Проверка результата ==="
if command -v paru >/dev/null 2>&1; then
    echo "paru успешно установлен: $(paru --version)"
else
    echo "ОШИБКА: paru не установлен после сборки"
    exit 1
fi