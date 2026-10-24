#!/usr/bin/env bash
# подключаемый модуль проверки зеркал
# source объявляет функции без запуска проверки

# выводит ошибку и завершает проверку
archauto_mirror_error() {
    # >&2 отправляет сообщение в поток ошибок
    printf 'Проверка зеркал: %s\n' "$1" >&2
    exit 1
}

# проверяет полную загрузку базы extra и сообщает причину отказа
archauto_mirror_is_reachable() {
    local template="$1" url attempt result bytes reason
    # ${переменная//старое/новое} заменяет все вхождения
    url="${template//\$repo/extra}"
    # $(команда) подставляет вывод команды
    url="${url//\$arch/$(uname -m)}"
    # ${url%/} убирает завершающий слеш если он есть
    url="${url%/}/extra.db"

    # две попытки уменьшают влияние кратковременного сбоя
    for attempt in 1 2; do
        # 2>&1 добавляет ошибки curl к сохраненному выводу
        if result="$(curl --fail --silent --show-error --location \
            --connect-timeout 4 --max-time 30 \
            --speed-limit 65536 --speed-time 5 \
            --output /dev/null --write-out '\n%{size_download}' "$url" 2>&1)"; then
            # ## оставляет часть строки после последнего переноса
            bytes="${result##*$'\n'}"
            # =~ проверяет цифры а (( )) сравнивает числа
            if [[ "$bytes" =~ ^[0-9]+$ ]] && (( bytes >= 1048576 )); then
                return 0
            fi
            reason="слишком маленький ответ: ${bytes} байт"
        else
            # %% оставляет сообщение перед первым переносом
            reason="${result%%$'\n'*}"
            [[ -n "$reason" ]] || reason='неизвестная ошибка curl'
        fi
        printf 'Попытка %d для %s: %s\n' "$attempt" "$template" "$reason" >&2
    done
    return 1
}

# проверяет зеркала и обновляет список pacman
# круглые скобки изолируют выход из функции от вызывающего скрипта
archauto_update_mirrors() (
    if [[ $# -gt 2 ]]; then
        archauto_mirror_error 'использование: archauto_update_mirrors [кандидат] [действующий mirrorlist]'
    fi
    # :- выбирает стандартный путь если аргумент не передан
    local source_list="${1:-/etc/pacman.d/mirrorlist}"
    local target_list="${2:-/etc/pacman.d/mirrorlist}" line template
    local checked=0 available=0 rejected=0 backup candidate

    command -v curl >/dev/null 2>&1 || archauto_mirror_error 'не найдена команда curl'
    [[ -f "$source_list" && -r "$source_list" ]] || archauto_mirror_error "не читается $source_list"
    [[ -f "$target_list" && ! -L "$target_list" ]] || archauto_mirror_error "ожидался обычный файл: $target_list"
    [[ -w "$target_list" && -w "$(dirname -- "$target_list")" ]] || archauto_mirror_error "нет прав на изменение $target_list"

    # mktemp создает файл с уникальным именем рядом с mirrorlist
    candidate="$(mktemp "$(dirname -- "$target_list")/.mirrorlist.archauto.XXXXXX")" || archauto_mirror_error 'не удалось создать временный файл'
    # trap удаляет временный файл при выходе из функции
    trap 'rm -f -- "$candidate"' EXIT

    # IFS= и read -r сохраняют пробелы и обратные слеши
    while IFS= read -r line || [[ -n "$line" ]]; do
        # =~ ищет строку Server с адресом http или https
        if [[ "$line" =~ ^[[:space:]]*Server[[:space:]]*=[[:space:]]*(https?://[^[:space:]#]+) ]]; then
            # BASH_REMATCH[1] содержит адрес из круглых скобок
            template="${BASH_REMATCH[1]}"
            ((checked += 1))
            if archauto_mirror_is_reachable "$template"; then
                printf '%s\n' "$line" >> "$candidate" || archauto_mirror_error 'не удалось записать временный файл'
                ((available += 1))
                printf 'Доступно: %s\n' "$template"
            else
                ((rejected += 1))
                printf 'Исключено после двух попыток: %s\n' "$template" >&2
            fi
        elif [[ "$line" =~ ^[[:space:]]*Server[[:space:]]*= ]]; then
            archauto_mirror_error "неподдерживаемый адрес зеркала: $line"
        else
            # комментарии и пустые строки сохраняются без изменений
            printf '%s\n' "$line" >> "$candidate" || archauto_mirror_error 'не удалось записать временный файл'
        fi
    # < передает строки файла в цикл
    done < "$source_list"

    ((checked > 0)) || archauto_mirror_error "в $source_list нет HTTP(S)-зеркал"
    ((available > 0)) || archauto_mirror_error 'все зеркала недоступны; прежний mirrorlist сохранён'

    # cmp -s проверяет изменился ли список зеркал
    if cmp -s -- "$candidate" "$target_list"; then
        printf 'Список зеркал актуален: доступно %d из %d.\n' "$available" "$checked"
        return 0
    fi

    backup="${target_list}.backup.$(date +%Y%m%d%H%M%S).$$"
    cp -a -- "$target_list" "$backup" || archauto_mirror_error 'не удалось создать резервную копию'
    chmod --reference="$target_list" "$candidate" || archauto_mirror_error 'не удалось сохранить права файла'
    if [[ $EUID -eq 0 ]]; then
        chown --reference="$target_list" "$candidate" || archauto_mirror_error 'не удалось сохранить владельца файла'
    fi
    mv -f -- "$candidate" "$target_list" || archauto_mirror_error 'не удалось обновить список зеркал'
    printf 'Список обновлён: доступно %d из %d, исключено %d. Резервная копия: %s\n' \
        "$available" "$checked" "$rejected" "$backup"
)

# при прямом запуске вызываем функцию со всеми аргументами
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    archauto_update_mirrors "$@"
fi
