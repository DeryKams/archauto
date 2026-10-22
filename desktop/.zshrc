# Powerlevel10k Instant Prompt
# Должен находиться в начале .zshrc
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Плагины Oh My Zsh
plugins=(
    git
    fzf
    extract
    you-should-use
    fzf-tab
)

# Загружаем Oh My Zsh и систему автодополнения
source "$ZSH/oh-my-zsh.sh"

# Автоматические подсказки команд
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh


# Генератор паролей
# Использование: pwgen 24
pwgen() {
    local LEN="${1:-}"

    # Проверяем корректность длины
    if [[ -z "$LEN" || ! "$LEN" =~ ^[0-9]+$ || "$LEN" -le 0 ]]; then
        echo "Использование: pwgen <длина>"
        echo "Пример: pwgen 24"
        return 1
    fi

    # Допустимый исходный набор символов
    local BASE_CHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%&*_=+?:;,.\/'

    # Символы, исключённые из генерации
    local -a DISALLOW=(
        '0' 'O' 'o'
        '1' 'l' 'I'
        '"' "'" '\' '`'
    )

    # Исключаем запрещённые символы
    local ALLOWED_CHARS="$BASE_CHARS"
    local ch

    for ch in "${DISALLOW[@]}"; do
        ALLOWED_CHARS="${ALLOWED_CHARS//"$ch"/}"
    done

    # Генерируем пароль из случайных байтов
    local PASS
    PASS="$(tr -dc "$ALLOWED_CHARS" < /dev/urandom | head -c "$LEN")"

    # Проверяем длину результата
    if [[ "${#PASS}" -ne "$LEN" ]]; then
        echo "Не удалось сгенерировать пароль нужной длины (${#PASS}/$LEN)."
        return 1
    fi

    echo "$PASS"
}


# Системные утилиты

# Показывает всех пользователей и их группы
alias usrlst='getent passwd | cut -d: -f1 | while read user; do printf "%-20s | %s\n" "User: $user" "Groups: $(groups $user 2>/dev/null)"; done'

# Показывает группы указанного пользователя
usrgrps() {
    if getent passwd "$1" >/dev/null 2>&1; then
        echo "User: $1 | Groups: $(groups "$1" 2>/dev/null)"
    else
        echo "User not found"
    fi
}


# Навигация и файлы

# Показывает содержимое каталога после перехода
cd() {
    builtin cd "$@" || return
    lsd -a --color=auto
}

# Редактирует .zshrc и перезапускает Zsh
alias zshrc='nano ~/.zshrc && exec zsh'

# Замена стандартных команд
alias ls='lsd -a --color=auto'
alias cat='bat --paging=never'

# Удаляем прежний алиас при повторном source этого файла.
unalias catc 2>/dev/null

# Копирует и выводит один файл, не открывая аргументы на запись.
function catc {
    if [[ $# -ne 1 ]]; then
        print -u2 'Использование: catc <файл>'
        return 1
    fi
    if [[ ! -f "$1" || ! -r "$1" ]]; then
        print -u2 -- "Файл недоступен для чтения: $1"
        return 1
    fi

    # Ожидаем результат wl-copy: сбой копирования не должен выглядеть успехом.
    command wl-copy < "$1" || return
    command cat < "$1"
}

# Переход на рабочий стол
alias home='cd ~/"Рабочий стол"'

# Переходит в каталог либо в родительский каталог файла
scd() {
    if [[ -f "$1" ]]; then
        echo "Указан файл. Переход в родительский каталог."
        cd "$(dirname "$1")"
    elif [[ -d "$1" ]]; then
        cd "$1"
    else
        echo "Ошибка: Путь '$1' не найден."
        return 1
    fi
}


# Браузер Carbonyl

# Запускает терминальный браузер с отдельным профилем
alias carbonyl='carbonyl \
    --disable-gpu \
    --disable-software-rasterizer \
    --user-data-dir="$HOME/.config/carbonyl" \
    --disk-cache-dir="$HOME/.cache/carbonyl"'


# SSH

# Использует Kitty SSH kitten внутри Kitty
# В других терминалах запускает обычный SSH
ssh() {
    if [[ "$TERM" == "xterm-kitty" || -n "${KITTY_WINDOW_ID:-}" ]] &&
        command -v kitty >/dev/null 2>&1; then
        kitty +kitten ssh "$@"
    else
        command ssh "$@"
    fi
}


# QR-коды

# Генерирует QR-код из переданной строки
qrgen() {
    if [[ $# -ne 1 || -z "$1" ]]; then
        print -u2 'Использование: qrgen "текст"'
        return 1
    fi

    # Сохраняем регистр; начальный дефис в тексте не становится опцией.
    qrencode -t UTF8 -m 2 -- "$1"
}


# Hermes

# Запуск Hermes Workspace с WebUI
alias hermeswrk='~/Документы/hermes.sh'

# Запускает Chromium с CDP и передаёт адрес подключения Hermes
hermesup() {
    local env_file="$HOME/.hermes/.env"
    local ws="" out="" i

    # Запускаем Chromium, если CDP недоступен
    if ! curl -s --max-time 1 http://127.0.0.1:9222/json/version >/dev/null 2>&1; then
        (setsid chromium --remote-debugging-port=9222 --headless --disable-gpu \
            --user-data-dir="$HOME/.cache/hermes-chromium-profile" \
            >/dev/null 2>&1 &)
    fi

    # Получаем WebSocket endpoint
    for i in $(seq 1 20); do
        out=$(curl -s --max-time 1 http://127.0.0.1:9222/json/version)
        ws=$(printf '%s' "$out" | grep -o 'ws://[^"]*')
        [[ -n "$ws" ]] && break
        sleep 0.5
    done

    # Прерываем запуск, если CDP недоступен
    if [[ -z "$ws" ]]; then
        echo "hermesup: Chromium DevTools не поднялся на :9222."
        return 1
    fi

    # Обновляем адрес CDP в .env
    if grep -q '^BROWSER_CDP_URL=' "$env_file" 2>/dev/null; then
        sed -i "s|^BROWSER_CDP_URL=.*|BROWSER_CDP_URL=$ws|" "$env_file"
    else
        echo "BROWSER_CDP_URL=$ws" >> "$env_file"
    fi

    echo "Chromium up, CDP: $ws"
    hermes "$@"
}

# Пересоздаёт окружение Hermes из uv.lock и запускает восстановление
alias hermes-fix='(set -e; echo "Пересоздаем venv (lock-версии) + чиним lazy-окружение"; cd /opt/hermes-agent; sudo rm -rf venv; uv venv venv --python 3.11; UV_PROJECT_ENVIRONMENT=venv uv sync --extra all --locked; rm -rf ~/.local/share/hermes-agent/python; ./venv/bin/hermes doctor --fix)'


# npm

# Пользовательский каталог глобальных npm-пакетов
export PATH="$HOME/.npm-global/bin:$PATH"


# Powerlevel10k
# Загружаем пользовательские настройки темы
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# Подсветка синтаксиса
# Загружается последней, после остальных плагинов
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh