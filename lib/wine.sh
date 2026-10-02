#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo "Ошибка: Модуль для установки игровых пакетов должен вызываться из под root" >&2
	return 1 2>/dev/null
fi

# Устанавливаем игровые пакеты
pacman -S --needed wine wine-mono wine-gecko winetricks lutris
