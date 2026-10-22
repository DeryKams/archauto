#!/usr/bin/env bash

# Без interval Waybar читает JSON-строки из одного долгоживущего процесса.
if [[ "${1:-}" != "--from-stdin" ]]; then
    printf '%s\n' '{"text":"Буфер пуст","tooltip":"Буфер пуст"}'
    exec wl-paste --watch "$BASH" "${BASH_SOURCE[0]}" --from-stdin
fi

clipboard=""
if [[ "${CLIPBOARD_STATE:-}" == "nil" || "${CLIPBOARD_STATE:-}" == "clear" ]]; then
    cat > /dev/null
else
    # wl-clipboard 2.3.0 не передаёт CLIPBOARD_TYPE. Запрашиваем только метаданные
    # по событию: --list-types не получает содержимое и не расходует ещё одну вставку.
    # --type text у watcher пропускает изображения без события для обработчика,
    # поэтому наблюдаем все типы, чтобы не оставлять на панели предыдущий текст.
    types="$(wl-paste --list-types 2>/dev/null)" || types=""
    if grep -Eq '^(text/|UTF8_STRING$|STRING$|TEXT$)' <<< "$types"; then
        clipboard="$(cat)"
    else
        # Дочитываем поток, чтобы источник данных не завис на заполненном pipe.
        cat > /dev/null
    fi
fi

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