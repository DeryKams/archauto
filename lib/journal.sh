#!/bin/bash

# Скрипт для ограничения размера журнала systemd и проверки его целостности

# Проверка прав суперпользователя
if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: модуль обслуживания журнала должен вызываться из-под root" >&2
    # Возвращаем ошибку, если вызван через source; перенаправляем stderr, чтобы не было шума при exit
    return 1 2>/dev/null
fi

# Пример подключения в основном скрипте:
# if [[ -f "./lib/journal.sh" ]]; then
#     source "./lib/journal.sh"
# else
#     echo "Модуль ограничения журнала отсутствует в папке lib или нет доступа" >&2
# fi

# Ограничение размера журналов до 30 мегабайт
journalctl --vacuum-size=30M

# Проверка целостности файлов журнала
journalctl --verify

# настройки выше только обрезают текущий журнал

conf_file="/etc/systemd/journald.conf"
#Проверка для создания бэкапа journal.conf
if [ -f "${conf_file}.bak" ]; then
    echo "Бэкап был уже ранее создан: ${conf_file}.bak"
else
    #Проверка существования файла
    if [ -f "${conf_file}" ]; then
        #В квадратных скобках [] прописывается условие для проверки. Необходимы пробелы после и перед скобками (перед и после условия проверки)
        # -f проверяет существует ли файл с именем, указанным справа
        #Создание бэкапа
        cp "${conf_file}" "${conf_file}.bak"
        echo "Был создан бэкап: ${conf_file}.bak"
    else
        echo "Файл не найден: ${conf_file}"
    fi
fi
#Для каждого if нужен свой fi

# Ставим настройку на постоянную основу
# Это общий лимит на все журналы вместе взятые
# Он ограничивает суммарный размер всех файлов в папке /var/log/journal/.

new_value_maxuse="40M"
if grep -q "^#SystemMaxUse" "${conf_file}"; then
    #grep - команда поиска текста в файле
    #-q - тихий режим, grep не выводит строки, а просто сообщает о найденом совпадении
    
    sed -i "s/^#SystemMaxUse=.*/SystemMaxUse=$new_value_maxuse/" "${conf_file}"
    #sed -i Редактирует файл на месте
    #"s" -команда замены для sed
    # s/шаблон/замена/
    #/^ - обозначение начала строки для поиска. В замене он обозначается буквально
    # .* - регулярное выражение, которое обозначает любое выражение до перевода строки
    echo "#SystemMaxUse был заменен"
else
    if grep -q "^SystemMaxUse=" "${conf_file}"; then
        sed -i "s/^SystemMaxUse=.*/SystemMaxUse=$new_value_maxuse/" "${conf_file}"
        echo "*^SystemMaxUse был заменен"
    else
        echo "SystemMaxUse=$new_value_maxuse" >> "${conf_file}"
        echo "SystemMaxUse был добавлен в конец файла"
    fi
fi

# Это лимит на размер одного конкретного файла журнала.
# SystemMaxFileSize замена
new_max_file_size="20M"

if grep -q "^#SystemMaxFileSize" "${conf_file}"; then
    
    sed -i "s/^#SystemMaxFileSize=.*/SystemMaxFileSize=$new_max_file_size/" "${conf_file}"
    #sed -i редактирвует в инлайне
    #s/шаблон/замена/
    #^-начало строки
    #.*-регулряное выражение, обозанчающие любое выражение до перевода строки
    
    echo "#SystemMaxFileSize был заменен на SystemMaxFileSize=$new_max_file_size"
    
else
    if grep -q "^SystemMaxFileSize" "${conf_file}"; then
        sed -i "s/^SystemMaxFileSize.*/SystemMaxFileSize=$new_max_file_size/" "${conf_file}"
        
        echo "SystemMaxFileSize был заменен на SystemMaxFileSize=$new_max_file_size"
        
    else
        
        echo "SystemMaxFileSize=$new_max_file_size" >> "${conf_file}"
        echo "SystemMaxFileSize=$new_max_file_size был добавлен в конце ${conf_file}"
    fi
fi


# Перезапуск службы для применения изменений
systemctl restart systemd-journald

