#!/usr/bin/env bash
set -euo pipefail

exec > >(tee -a "outputarchauto.log") 2>&1


# Нужен целевой обычный пользователь; при установке из Live ISO его передаёт filesystem.sh.
if [[ $EUID -ne 0 || -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
    echo "Запусти скрипт через sudo от обычного пользователя или через filesystem.sh"
    exit 1
fi

USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
[[ -n $USER_HOME && -d $USER_HOME ]] || {
    echo "Домашний каталог пользователя $SUDO_USER не найден" >&2
    exit 1
}
DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Проверяем комплект модулей до изменения системных настроек.
for module in locale journal sysctl pacman wine kitty; do
    module_path="$DOTFILES/lib/$module.sh"
    if [[ ! -f "$module_path" || ! -r "$module_path" ]]; then
        echo "Обязательный модуль отсутствует или недоступен: $module_path" >&2
        exit 1
    fi
done

# Проверки
[[ -d "$DOTFILES/desktop/.config" && -x "$DOTFILES/desktop/.local/bin/arch-waylock" &&
    -f "$DOTFILES/gdm/90-apple-dark" && -f "$DOTFILES/gdm/profile" ]] || {
    echo "Не найдены конфигурации рабочего стола в $DOTFILES"
    exit 1
}
if [[ -L "$USER_HOME/.config" &&
    $(readlink -f "$USER_HOME/.config") != "$DOTFILES/desktop/.config" ]]; then
    echo "Существующая $USER_HOME/.config ссылается на другой каталог; сохраните его настройки перед установкой нового UI-kit" >&2
    exit 1
fi


# Локали для рабочего окружения, включая часы Waybar.
source "$DOTFILES/lib/locale.sh"

#Ограничение журнала systemd
source "$DOTFILES/lib/journal.sh"

# Разовый TRIM; периодический запуск включается ниже через fstrim.timer.
fstrim -va


# Настройка swap и cache pressure в systemctl
source "$DOTFILES/lib/sysctl.sh"

# Настройка ILoveCandy, Color и ParallelDownloads в pacman
source "$DOTFILES/lib/pacman.sh"

# Установка Wine для windows приложений
source "$DOTFILES/lib/wine.sh"

DESKTOP_PACKAGES=(
    niri waylock gdm dconf swayidle swaync kitty waybar fuzzel wl-clipboard cantarell-fonts
    xdg-desktop-portal-gtk xdg-desktop-portal-gnome xwayland-satellite
    brightnessctl playerctl polkit-gnome power-profiles-daemon
    pipewire pipewire-pulse wireplumber
    stow git fzf neovim rust imagemagick
    pipewire-alsa grim slurp papirus-icon-theme
    pcmanfm-qt gvfs
    python
    python-gobject
    gtk3
    gtk-layer-shell
)


# Шрифты
FONTS=(
    ttf-dejavu noto-fonts noto-fonts-cjk noto-fonts-emoji
    ttf-liberation ttf-fira-code ttf-jetbrains-mono
    ttf-hack ttf-nerd-fonts-symbols noto-fonts-extra
    powerline-fonts
)


# Системные утилиты
SYSTEM_UTILS=(
    base-devel bash-completion wget openssh networkmanager
    pacman-contrib bluez bluez-utils blueman apparmor
    ufw gufw iptables-nft ghostscript fail2ban
    libpwquality reflector
)

# Игровые пакеты
GAME_PACKAGES=(
    mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
    gamemode lib32-gamemode steam pavucontrol
)

# Консольные утилиты
CONSOLE_UTILS=(
    ripgrep bat lsd duf dust gping dos2unix jq yq
    rclone irqbalance libqalculate htop
    nano vim qrencode tree
)

# Диски и архивы
DISK_UTILS=(
    ntfs-3g timeshift unrar zip p7zip unzip
)

APPLICATIONS=(
    chromium mpv vlc tor torbrowser-launcher nyx
    qbittorrent obsidian flameshot libreoffice-fresh-ru 
    krdc freerdp
)

# Кодеки
CODECS=(
    gst-libav gst-plugins-good gst-plugins-bad
    gst-plugins-ugly vlc-plugin-ffmpeg
)

# Устанавливает переданный список пакетов через pacman
install_packages() {
    pacman -S --needed --noconfirm "$@"
}

# Установка пакетов по категориям
for group in \
DESKTOP_PACKAGES \
FONTS \
SYSTEM_UTILS \
GAME_PACKAGES \
CONSOLE_UTILS \
DISK_UTILS \
APPLICATIONS \
CODECS
do
    # Получаем элементы массива по его имени
    declare -n packages="$group"
    
    # Устанавливаем пакеты текущей категории
    echo "Установка: $group"
    install_packages "${packages[@]}"
    
    # Удаляем ссылку перед следующей итерацией
    unset -n packages
done

# Установка kitty
source "$DOTFILES/lib/kitty.sh"

skip_aur=false
preinstalled=false
for option in "$@"; do
    case $option in
        --skip-aur) skip_aur=true ;;
        --preinstalled) preinstalled=true ;;
        *) echo "Использование: $0 [--skip-aur] [--preinstalled]" >&2; exit 2 ;;
    esac
done


# Сохраняем существующий .zshrc, если он не подключён к нашему репозиторию
ZSHRC_SOURCE="$DOTFILES/desktop/.zshrc"
ZSHRC_TARGET="$USER_HOME/.zshrc"

if [[ -e "$ZSHRC_TARGET" || -L "$ZSHRC_TARGET" ]] &&
   [[ ! "$ZSHRC_TARGET" -ef "$ZSHRC_SOURCE" ]]; then

    # Создаём резервную копию пользовательской конфигурации
    runuser -u "$SUDO_USER" -- \
        mv -- "$ZSHRC_TARGET" "$ZSHRC_TARGET.backup.$(date +%Y%m%d%H%M%S)"
fi
# Dotfiles — обычный пользователь
# Существующий каталог не даёт Stow превратить всю ~/.config в одну ссылку.
USER_SYSTEMD="$USER_HOME/.config/systemd/user"
runuser -u "$SUDO_USER" -- mkdir -p \
"$USER_SYSTEMD/niri.service.wants" "$USER_HOME/.local/bin"
# 1. Запускаем Stow от обычного пользователя, чтобы ссылки создавались от его имени.
# 2. -- отделяет параметры runuser от команды, которую он должен выполнить.
# 3. В sh -c символ _ занимает $0: $1 — домашний каталог, $2 — папка с установщиком и dotfiles.
# 4. Сначала переходим домой: из /root Stow не сможет нормально работать.
# 5. Stow берёт пакет desktop из dotfiles (-d) и создаёт ссылки дома (-t).
runuser -u "$SUDO_USER" -- \
sh -c 'cd "$1" && stow --ignore="(^|/)(kitty|niri\.service\.wants|\.DS_Store|\._[^/]*)($|/)" -d "$2" -t "$1" desktop' _ "$USER_HOME" "$DOTFILES"
runuser -u "$SUDO_USER" -- env NIRI_CONFIG="$USER_HOME/.config/niri/config.kdl" niri validate

# Включаем GDM на следующую загрузку, не запуская графический вход во время установки.
systemctl enable gdm.service
install -Dm644 "$DOTFILES/gdm/90-apple-dark" /etc/dconf/db/gdm.d/90-apple-dark
if [[ ! -e /etc/dconf/profile/gdm ]]; then
    install -Dm644 "$DOTFILES/gdm/profile" /etc/dconf/profile/gdm
else
    grep -Fxq 'user-db:user' /etc/dconf/profile/gdm &&
    grep -Fxq 'file-db:/usr/share/gdm/greeter-dconf-defaults' /etc/dconf/profile/gdm || {
        echo 'Профиль GDM не содержит необходимые базы dconf' >&2
        exit 1
    }
    if ! grep -Fxq 'system-db:gdm' /etc/dconf/profile/gdm; then
        sed -i '/^user-db:user$/a system-db:gdm' /etc/dconf/profile/gdm
    fi
fi
dconf update

# GDM иначе выбирает GNOME, который устанавливается как зависимость портала.
ACCOUNT_FILE="/var/lib/AccountsService/users/$SUDO_USER"
mkdir -p /var/lib/AccountsService/users
if [[ -f "$ACCOUNT_FILE" ]]; then
    if grep -q '^XSession=' "$ACCOUNT_FILE"; then
        sed -i 's/^XSession=.*/XSession=niri/' "$ACCOUNT_FILE"
    else
        printf 'XSession=niri\n' >> "$ACCOUNT_FILE"
    fi
else
    printf '[User]\nXSession=niri\n' > "$ACCOUNT_FILE"
fi

# Автозапуск служб вместе с Niri

ln -sfn ../swayidle.service \
"$USER_SYSTEMD/niri.service.wants/swayidle.service"

ln -sfn /usr/lib/systemd/user/swaync.service \
"$USER_SYSTEMD/niri.service.wants/swaync.service"

ln -sfn /usr/lib/systemd/user/waybar.service \
"$USER_SYSTEMD/niri.service.wants/waybar.service"

chown -h "$SUDO_USER:" \
"$USER_SYSTEMD/niri.service.wants/"*.service

chown "$SUDO_USER:" \
"$USER_SYSTEMD/niri.service.wants"

pacman -S --noconfirm --needed openresolv

if [[ "$skip_aur" == false ]]; then
    # Собираем paru под текущую libalpm: готовый paru-bin может быть несовместим.
    if ! paru --version >/dev/null 2>&1; then
        PARU_BUILD_DIR="$(mktemp -d "$USER_HOME/paru-build.XXXXXX")"
        chown "$SUDO_USER:" "$PARU_BUILD_DIR"
        runuser -u "$SUDO_USER" -- \
        git clone https://aur.archlinux.org/paru.git "$PARU_BUILD_DIR/paru"
        runuser -u "$SUDO_USER" -- \
        env CARGO_PROFILE_RELEASE_LTO=off \
        bash -c 'cd "$1" && makepkg --noconfirm' _ "$PARU_BUILD_DIR/paru"
        if pacman -Qq paru-bin >/dev/null 2>&1; then
            pacman -R --noconfirm paru-bin
        fi
        pacman -U --noconfirm "$PARU_BUILD_DIR"/paru/paru-[0-9]*.pkg.tar.zst
    fi
    
    # Установка AUR-пакетов через paru
    runuser -u "$SUDO_USER" -- paru -S --needed --noconfirm \
    walker elephant \
    elephant-desktopapplications elephant-calc \
    elephant-runner elephant-clipboard \
    neowall-git wl-clipboard-history-git \
    nohang-git minq-ananicy-git stacer-bin \
    php-codesniffer-phpcsutils php-codesniffer-phpcsextra \
    visual-studio-code-bin fastfetch-git \
    carbonyl gdm-settings
    
    
    # В chroot пользовательский systemd ещё не запущен: подготовить unit офлайн.
    cat > "$USER_SYSTEMD/elephant.service" <<'EOF'
[Unit]
Description=Elephant launcher backend
PartOf=graphical-session.target
After=graphical-session.target
Requisite=graphical-session.target

[Service]
ExecStart=/usr/bin/elephant
Restart=on-failure
EOF
    ln -sfn ../elephant.service \
    "$USER_SYSTEMD/niri.service.wants/elephant.service"
    chown "$SUDO_USER:" "$USER_SYSTEMD/elephant.service"
    chown -h "$SUDO_USER:" "$USER_SYSTEMD/niri.service.wants/elephant.service"
fi



#объявляем функцию для включения служб
enable_service(){
    
    local service_name="$1"
    #$1 - это первый аргумент, который передается функции
    # local - объявляем переменную, которая будет локально внутри данной функции. К примеру, чтобы она не перезаписывала глобальные
    
    if systemctl enable --now "$service_name"; then
        echo "Service $service_name enabled and started successfully."
        
        if systemctl is-active --quiet "$service_name"; then
            # systemctl is-active - специально созданная команда для проверки статуса службы
            # --quiet - означает, что вывод будет без лишней информации, только код возврата
            echo "Service $service_name is running."
        else
            echo "Service $service_name is not running after enabling."
            journalctl -n 5 -u "$service_name" --no-pager
        fi
    else
        echo "Failed to enable or start service $service_name. It may already be running or not exist."
        journalctl -n 10 -u "$service_name" --no-pager
    fi
    
    
}

# Снимаем маску перед включением службы в общем цикле.
systemctl unmask power-profiles-daemon.service

# проверяем статусы служб
#Объявляем массив для служб
# -a - объявляем, что это массив
# -r - объявляем, что массив является неизменяемым, то есть только для чтения
declare -a LIST_SERVICE_CHECK=(
    "power-profiles-daemon.service"
    "systemd-resolved.service"
    "fstrim.timer"
    "reflector.service"
    "reflector.timer"
    "fail2ban.service"
    "nohang-desktop.service"
    "ananicy.service"
    "irqbalance.service"
)

for item in "${LIST_SERVICE_CHECK[@]}"; do
    #for - это цикл, который перебирает элементы массива
    # item - переменная, которую мы задали конкретно для данного цикла. Туда "кладется" каждый элемент массива по очереди
    # "" - нужны для того, чтобы службы в которых присутствуют пробелы были восприняты, как единое целое, а не ка кнесколько служб
    # [@] - квадрытные скобки нужны для обращения к элементам массива, а знак @ - для обращения ко всем элементам массива
    # если просто объявить $LIST_SERVICE_CHECK, то bash возьмет только первый элемент массива, а не все
    # если использовать [*], то будет взят весь массив, как единое целое, то есть все элементы массива будут восприниматься как одна строка
    enable_service "$item"
    # enable_service - функция, которую мы ранее определили и которая берет элемент item и выполняет операции
done

# Устанавливаем Zsh и системные плагины, если они отсутствуют
pacman -S --needed --noconfirm \
    zsh \
    zsh-completions zsh-syntax-highlighting \
    zsh-autosuggestions curl

# Устанавливаем пользовательские компоненты Oh My Zsh
runuser -u "$SUDO_USER" -- env HOME="$USER_HOME" bash <<'BASH'
    set -euo pipefail
    cd -- "$HOME"

    # Определяем каталоги установки Oh My Zsh
    ZSH_DIR="$HOME/.oh-my-zsh"
    PLUGINS="$ZSH_DIR/custom/plugins"
    THEMES="$ZSH_DIR/custom/themes"

    # Устанавливаем Oh My Zsh без изменения существующего .zshrc
    if [[ ! -d "$ZSH_DIR" ]]; then
        git clone --depth 1 \
            https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"
    fi

    # Создаём каталоги пользовательских плагинов и тем
    mkdir -p "$PLUGINS" "$THEMES"

    # Устанавливаем тему Powerlevel10k
    if [[ ! -d "$THEMES/powerlevel10k" ]]; then
        git clone --depth 1 \
            https://github.com/romkatv/powerlevel10k.git \
            "$THEMES/powerlevel10k"
    fi

    # Устанавливаем плагин подсказок существующих алиасов
    if [[ ! -d "$PLUGINS/you-should-use" ]]; then
        git clone --depth 1 \
            https://github.com/MichaelAquilina/zsh-you-should-use.git \
            "$PLUGINS/you-should-use"
    fi

    # Устанавливаем плагин интерактивного автодополнения fzf-tab
    if [[ ! -d "$PLUGINS/fzf-tab" ]]; then
        git clone --depth 1 \
            https://github.com/Aloxaf/fzf-tab.git \
            "$PLUGINS/fzf-tab"
    fi


BASH

# Определяем путь к установленной оболочке Zsh
ZSH_BIN="$(command -v zsh)"

# Назначаем Zsh оболочкой пользователя, если она ещё не используется
if [[ "$(getent passwd "$SUDO_USER" | cut -d: -f7)" != "$ZSH_BIN" ]]; then
    chsh -s "$ZSH_BIN" "$SUDO_USER"
fi


# Установка flatpak # Нужно в конце, так как qalculate-qt будет долгим
pacman -S --noconfirm --needed flatpak flatpak-kcm flatpak-xdg-utils
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y io.github.Qalculate.qalculate-qt org.telegram.desktop

# настройка reflector
reflector --country 'Russia' --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

echo "Установка завершена"
