# Цвета и элементы prompt
PS1='\[\e[1;33m\]\t \[\e[1;36m\]\w \[\e[1;35m\]\$ \[\e[0m\]'

# Цвета для ls
alias ls='ls --color=auto'

alias clr='clear'

alias grep='grep --color=auto'

alias bashrc='nano ~/.bashrc && source ~/.bashrc'

# Генератор паролей
genpass() {
    # Устанавливаем длину пароля (по умолчанию 8)
    local length="${1:-8}"

    # Проверка что аргумент - положительное число
    if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
        echo -e "\033[1;31mОшибка:\033[0m длина должна быть числом > 0"
        echo "Использование: genpass [длина]"
        echo "Пример: genpass 12"
        return 1
    fi

    # Набор символов
    local chars='A-Za-z0-9!@#$%^&*()_+-=[]{}|;:,.<>?~'

    # Генерация пароля
    local password=$(tr -dc "$chars" < /dev/urandom | head -c "$length")

    # Вывод пароля
    echo -e "\033[1;32mПароль:\033[0m $password"

    # Копирование в буфер обмена (для Termux)
    if command -v termux-clipboard-set &>/dev/null; then
        echo -n "$password" | termux-clipboard-set
        echo -e "\033[1;36mСкопировано в буфер!\033[0m"
    else
        echo -e "\033[1;33mПодсказка:\033[0m установите Termux:API для копирования в буфер"
        echo "pkg install termux-api"
    fi
}

#Улучшенный ls
alias ll='ls -alhF --color=auto --group-directories-first'
# -a — показывает все файлы, включая скрытые (начинающиеся с .)
# -l — подробный список (права, владелец, размер, дата изменения)
# -h — человекочитаемые размеры (например, 1K вместо 1024)
# -F — добавляет символы-индикаторы (/ для папок, * для исполняемых файлов)
# --color=auto — раскрашивает вывод (папки синим, файлы белым и т. д.)
# --group-directories-first — сначала папки, потом файлы

#fastping
alias fastping='ping -c 5 -i 0.2'
#Упрощённая версия ping, которая отправляет 5 пакетов с интервалом 0.2 секунды
# -c 5 — отправить 5 пакетов и завершить работу
# -i 0.2 — интервал между пакетами 0.2 секунды (быстрее стандартного)

#Проверка портов
alias ports='ss -tulnp'
# Показывает все открытые порты на компьютере и какие программы их используют.
# -t — TCP-порты
# -u — UDP-порты
# -l — только слушающие (открытые) порты
# -n — показывать номера портов (а не имена служб)
# -p — показывать процесс, который использует порт

#git alias
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
# gs — статус репозитория
# ga . — добавить файлы в коммит
# gc "bag restore" - создать коммит
# gp — отправить изменения на сервер
# gl — красивая история коммитов

#защита от дурака
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
# rm -i — спрашивает подтверждение перед удалением файла.
# cp -i — спрашивает, если файл уже существует.
# mv -i — аналогично, перед перезаписью.