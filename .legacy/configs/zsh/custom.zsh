# Этот файл подключается в конце .zshrc через source.

# --- TERM ---
TERM=xterm-kitty

# --- PATH дополнения ---
# LM Studio CLI (если установлен)
if [[ -d "$HOME/.lmstudio/bin" ]]; then
    export PATH="$PATH:$HOME/.lmstudio/bin"
fi

# ФУНКЦИИ

# Генератор паролей: pwgen 24
# Аргумент: длина пароля
# DISALLOW: массив символов, которых не должно быть в пароле
pwgen() {
    local LEN="${1:-}"

    if [[ -z "$LEN" || ! "$LEN" =~ ^[0-9]+$ || "$LEN" -le 0 ]]; then
        echo "Использование: pwgen <длина>"
        echo "Пример: pwgen 24"
        return 1
    fi

    local BASE_CHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%&*_=+?:;,.\/'

    local -a DISALLOW=(
        '0' 'O' 'o'
        '1' 'l' 'I'
        '"' "'" '\' '`'
    )

    local ALLOWED_CHARS="$BASE_CHARS"
    local ch
    for ch in "${DISALLOW[@]}"; do
        ALLOWED_CHARS="${ALLOWED_CHARS//"$ch"/}"
    done

    local PASS
    PASS="$(tr -dc "$ALLOWED_CHARS" < /dev/urandom | head -c "$LEN")"

    if [[ "${#PASS}" -ne "$LEN" ]]; then
        echo "Не удалось сгенерировать пароль нужной длины (${#PASS}/$LEN)."
        echo "Расширь BASE_CHARS или ослабь DISALLOW."
        return 1
    fi

    echo "$PASS"
}

# Вывод всех пользователей
usrlst() {
    getent passwd | cut -d: -f1 | while read user; do
        printf "%-20s | %s\n" "User: $user" "Groups: $(groups $user 2>/dev/null)"
    done
}

# Вывод групп указанного пользователя
usrgrps() {
    if getent passwd "$1" >/dev/null; then
        echo "User: $1 | Groups: $(groups "$1" 2>/dev/null)"
    else
        echo "User not found"
    fi
}

# cd с выводом содержимого после перехода
cd() {
    builtin cd "$@" || return
    lsd -a --color=auto
}

# Умная обертка cd: если передан файл — перейти в его родительскую папку
scd() {
    if [ -f "$1" ]; then
        echo -e "Warning: Вы пытаетесь перейти в файл, а не в папку.\nПопытка открытия папки с файлом\n"
        parent_dir=$(dirname "$1")
        cd "$parent_dir"
    elif [ -d "$1" ]; then
        cd "$1"
    else
        echo "Ошибка: Путь '$1' не найден."
    fi
}

# Умная обертка для ssh через kitty
ssh() {
    if [[ "$TERM" == "xterm-kitty" || -n "$KITTY_WINDOW_ID" ]] && command -v kitty >/dev/null 2>&1; then
        kitty +kitten ssh "$@"
    else
        command ssh "$@"
    fi
}

# Генерация QR-кода
qrgen() {
    if ! command -v qrencode >/dev/null 2>&1; then
        echo "qrencode не установлен. Установите: sudo pacman -S qrencode"
        return 1
    fi
    qrencode -t UTF8 -m 2 -i "$1"
}

# АЛИАСЫ

alias zshrc='nano ~/.zshrc && source ~/.zshrc && echo "=== Файл .zshrc перезагружен ==="'
alias cat='bat --paging=never'
alias catc='tee >(wl-copy) <'
alias ls='lsd -a --color=auto'

# carbonyl browser
alias carbonyl='carbonyl \
    --disable-gpu \
    --disable-software-rasterizer \
    --user-data-dir="$HOME/.config/carbonyl" \
    --disk-cache-dir="$HOME/.cache/carbonyl"'

# УСЛОВНЫЕ ПОДКЛЮЧЕНИЯ (только если цель существует)

# OpenClaw Completion
if [[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]]; then
    source "$HOME/.openclaw/completions/openclaw.zsh"
fi

# hermes-workspace (если скрипт существует)
if [[ -f "$HOME/Документы/hermes.sh" ]]; then
    alias hermeswrk="$HOME/Документы/hermes.sh"
fi

# Быстрый вход в папку рабочего стола (если существует)
if [[ -d "$HOME/Рабочий стол" ]]; then
    alias home='cd "$HOME/Рабочий стол"'
fi