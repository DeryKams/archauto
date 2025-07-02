# Цвета и элементы prompt
PS1='\[\e[1;33m\]\t \[\e[1;36m\]\w \[\e[1;35m\]\$ \[\e[0m\]'

export HISTCONTROL=ignorespace

export LS_COLORS='di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

alias bashrc='nano ~/.bashrc && bash -n ~/.bashrc &&  source ~/.bashrc'

# Цвета для ls
alias ls='ls --color=auto'

#Улучшенный ls
alias ll='ls -alhF --color=auto --group-directories-first  --time-style=long-iso'
# -a — показывает все файлы, включая скрытые (начинающиеся с .)
# -l — подробный список (права, владелец, размер, дата изменения)
# -h — человекочитаемые размеры (например, 1K вместо 1024)
# -F — добавляет символы-индикаторы (/ для папок, * для исполняемых файлов)
# --color=auto — раскрашивает вывод (папки синим, файлы белым и т. д.)
# --group-directories-first — сначала папки, потом файлы

alias clr='clear'

alias grep='grep --color=auto -i -n -H'
#-i — --color=auto — подсветка совпаденийигнорирование регистра
alias hgrep='history | grep'

grep -C 3 "error" file.log  # Покажет 3 строки до и после


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
alias ga='git add .'
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



# Цвета для less/man
export LESS_TERMCAP_mb=$'\E[1;31m'
export LESS_TERMCAP_md=$'\E[1;36m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_so=$'\E[1;47;30m'
export LESS_TERMCAP_se=$'\E[0m'


