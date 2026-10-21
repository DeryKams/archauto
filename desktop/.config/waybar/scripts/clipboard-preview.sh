#!/usr/bin/env bash

# Получаем текущий текст из системного буфера Wayland
clipboard="$(wl-paste --no-newline --type text 2>/dev/null)" || clipboard=""

# Заменяем переносы строк и табуляцию пробелами
# Waybar должен отображать только одну строку
clipboard="${clipboard//$'\n'/ }"
clipboard="${clipboard//$'\r'/ }"
clipboard="${clipboard//$'\t'/ }"

# Ограничиваем размер текста, передаваемого панели
clipboard="${clipboard:0:500}"

# Показываем состояние пустого или нетекстового буфера
if [[ -z "${clipboard//[[:space:]]/}" ]]; then
    clipboard="Буфер пуст"
fi

# Формируем корректный JSON для Waybar
# text — содержимое панели
# tooltip — текст при наведении курсора
jq -nc --arg value "$clipboard" \
    '{text: $value, tooltip: $value}'