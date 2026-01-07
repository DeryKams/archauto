#!/bin/bash

MAKEPKG_CONF="/etc/makepkg.conf"
# Переменная с путем до makepkg.conf
# = - должен быть без пробелов вокруг
if [[ -f "$MAKEPKG_CONF" ]]; then
    # -f - оператор проверки файла, возвращает true, если файл существует и является обычным файлом
    
    cp "$MAKEPKG_CONF" "${MAKEPKG_CONF}.backup.$(date +%Y%m%d%H%M%S)"
    
    # Сохраняем timestamp в переменную, чтобы использовать одинаковый
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    BACKUP_FILE="${MAKEPKG_CONF}.backup.${TIMESTAMP}"
    
    cp "$MAKEPKG_CONF" "$BACKUP_FILE"
    echo "Backup of $MAKEPKG_CONF created to $BACKUP_FILE"# cp - копируем файл по пути
    # "${MAKEPKG_CONF}.backup.$(date +%Y%m%d%H%M%S)" - целевое имя файла
    # ${MAKEPKG_CONF} - отделяем переменную от остального текста
    # $(date +%Y%m%d%H%M%S) - выполняем команду date для получения текущей даты и времени в формате ГГГГММДДЧЧММСС
    sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' "$MAKEPKG_CONF"
    # sed - потоковый текстовый редактор
    # -i - редактирование файла на месте
    #  's/.../.../' - шаблон замены
    #  ^ - объявляет начало строки
    #  #MAKEFLAGS=.* - ищем строку, начинающуюся с #MAKEFLAGS
    #  MAKEFLAGS="-j$(nproc)" - заменяем на эту строку
    if grep -q '^MAKEFLAGS="-j$(nproc)"' "$MAKEPKG_CONF"; then
        echo "MAKEFLAGS успешно обновлены для использования всех процессоров."
    else
        echo "Предупреждение: не удалось найти/обновить строку MAKEFLAGS" >&2
    fi
else
    echo "Error: $MAKEPKG_CONF not found.">&2
    # >&2 - перенаправление вывода ошибки в стандартный поток ошибок
fi
