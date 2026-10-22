#!/usr/bin/env bash

# Подоболочка не меняет переменные и shell-опции вызывающего установщика.
(
    set -euo pipefail

    if [[ $EUID -ne 0 ]]; then
        echo "Ошибка: модуль локалей должен вызываться из-под root" >&2
        exit 1
    fi

    # Нужна часам Waybar; LANG и раскладки клавиатуры не меняем.
    locale_gen_file="/etc/locale.gen"
    available_locales="$(LC_ALL=C locale -a)"
    # glibc обычно выводит ru_RU.utf8 вместо ru_RU.UTF-8.
    if grep -Eiq '^ru_RU\.utf-?8$' <<< "$available_locales"; then
        echo "Локаль ru_RU.UTF-8 уже доступна"
        exit 0
    fi

    if [[ ! -f "$locale_gen_file" || ! -r "$locale_gen_file" ]]; then
        echo "Не найден или недоступен $locale_gen_file" >&2
        exit 1
    fi
    if ! command -v locale-gen >/dev/null 2>&1; then
        echo "Не найдена команда locale-gen; проверь установку glibc" >&2
        exit 1
    fi

    # Сохраняем остальные локали; активную запись не добавляем повторно.
    entry='ru_RU\.UTF-8[[:space:]]+UTF-8([[:space:]]|$)'
    if ! grep -Eq "^[[:space:]]*$entry" "$locale_gen_file"; then
        if grep -Eq "^[[:space:]]*#[[:space:]]*$entry" "$locale_gen_file"; then
            sed -i -E "s/^[[:space:]]*#[[:space:]]*($entry)/\1/" "$locale_gen_file"
        else
            # Начальный перевод строки нужен, если файл не завершён новой строкой.
            printf '\nru_RU.UTF-8 UTF-8\n' >> "$locale_gen_file"
        fi
    fi

    echo "Генерация локали ru_RU.UTF-8..."
    locale-gen

    # Проверяем результат, а не только код возврата генератора.
    available_locales="$(LC_ALL=C locale -a)"
    if ! grep -Eiq '^ru_RU\.utf-?8$' <<< "$available_locales"; then
        echo "После locale-gen локаль ru_RU.UTF-8 не появилась" >&2
        exit 1
    fi
    echo "Локаль ru_RU.UTF-8 готова"
)
