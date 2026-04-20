#!/bin/bash

exec > >(tee -a "niriauto.log") 2>&1

if [[ -z "$SUDO_USER" ]]; then
    echo "Скрипт нужно запускать через sudo от обычного пользователя."
    exit 1
fi

user_nosudo="$SUDO_USER"
USER_RUNTIME_DIR="/run/user/$(id -u "$user_nosudo")"

file="/etc/systemd/journald.conf"
search_maxuse="SystemMaxUse"
search_max_file_size="SystemMaxFileSize"
new_value_maxuse="50M"
new_max_file_size="40M"
custom_sysctl="/etc/sysctl.d/99-custom.conf"
new_swappiness="10"
new_cash_pressure="65"
search_swappiness="vm.swappiness"
search_cash_pressure="vm.vfs_cache_pressure"
pacman_config="/etc/pacman.conf"
search_parallel_dow="ParallelDownloads"
new_parallel_dow="10"
downloadPckg="yes"
cpuUpd="yes"
grab_conf="/etc/default/grub"
srch_grub_default="GRUB_CMDLINE_LINUX_DEFAULT"
grub_configurator="yes"

#Ограничение журнала
journalctl --vacuum-size=30M
journalctl --verify
systemctl restart systemd-journald

#Проверка для создания бэкапа journal.conf
if [ -f "$file.original" ]; then
    echo "Бэкап был уже ранее создан: $file.original"
else
    #Проверка существования файла
    if [ -f "$file" ]; then
        #В квадратных скобках [] прописывается условие для проверки. Необходимы пробелы после и перед скобкаби (перед и после условия проверки)
        # -f проверяет существует ли файл с именем, указанным справа
        #Создание бэкапа
        cp "$file" "$file.original"
        echo "Был создан бэкап: $file.original"
    else
        echo "Файл не найден: $file"
    fi
fi
#Для каждого if нужен свой fi

#замена SystemMaxUse
if grep -q "^#$search_maxuse" "$file"; then
    #grep - команда поиска текста в файле
    #-q - тихий режим, grep не выводит строки, а просто сообщает о найденом совпадении

    sed -i "s/^#$search_maxuse=.*/$search_maxuse=$new_value_maxuse/" "$file"
    #sed -i Редактирует файл на месте
    #"s" -команда замены для sed
    # s/шаблон/замена/
    #/^ - обозначение начала строки для поиска. В замене он обозначается буквально
    # .* - регулярное выражение, которое обозначает любое выражение до перевода строки
    echo "#$search_maxuse был заменен"
else
    if grep -q "^$search_maxuse=" "$file"; then
        sed -i "s/^$search_maxuse=.*/$search_maxuse=$new_value_maxuse/" "$file"
        echo "$search_maxuse был заменен"
    else
        echo "$search_maxuse=$new_value_maxuse" >> "$file"
        echo "SystemMaxUse был добавлен в конец файла"
    fi
fi

#SystemMaxFileSize замена
if grep -q "^#$search_max_file_size" "$file"; then

    sed -i "s/^#$search_max_file_size=.*/$search_max_file_size=$new_max_file_size/" "$file"
    #sed -i редактирвует в инлайне
    #s/шаблон/замена/
    #^-начало строки
    #.*-регулряное выражение, обозанчающие любое выражение до перевода строки

    echo "#$search_max_file_size был заменен на $search_max_file_size=$new_max_file_size"

else
    if grep -q "^$search_max_file_size" "$file"; then
        sed -i "s/^$search_max_file_size.*/$search_max_file_size=$new_max_file_size/" "$file"

        echo "$search_max_file_size был заменен на $search_max_file_size=$new_max_file_size"

    else

        echo "$search_max_file_size=$new_max_file_size" >> "$file"
        echo "$search_max_file_size=$new_max_file_size был добавлен в конце $file"
    fi
fi


#Создание кастомного systemctl
if [ -f "$custom_sysctl" ]; then
    echo "$custom_sysctl уже был ранее создан"
else

    touch "$custom_sysctl"
    echo "$custom_sysctl создан"
fi

#добавляем vm.swappiness в кастомный sysctl
if grep -q "^$search_swappiness" "$custom_sysctl"; then

    sed -i "s/^$search_swappiness=.*/$search_swappiness=$new_swappiness/" "$custom_sysctl"

    echo "$search_swappiness бы заменен на $new_swappiness"

else

    echo "$search_swappiness=$new_swappiness" >> "$custom_sysctl"
    echo "$search_swappiness=$new_swappiness был добавлен в конце $custom_sysctl"
fi

#добавляем vm.vfs_cache_pressure в sysctl
if grep -q "^$search_cash_pressure" "$custom_sysctl"; then

    sed -i "s/^$search_cash_pressure=.*/$search_cash_pressure=$new_cash_pressure/" "$custom_sysctl"

    echo "$search_cash_pressure бы заменен на $new_cash_pressure"

else

    echo "$search_cash_pressure=$new_cash_pressure" >> "$custom_sysctl"
    echo "$search_cash_pressure=$new_cash_pressure бы добавлен в конце $custom_sysctl"
fi

#sysctl --system

if grep -q "^$search_parallel_dow" "$pacman_config"; then
    sed -i "s/^$search_parallel_dow.*/$search_parallel_dow = $new_parallel_dow/" "$pacman_config"
    echo "$search_parallel_dow было заменено значение на $new_parallel_dow"
else
    echo "$search_parallel_dow = $new_parallel_dow" >> "$pacman_config"
    echo "$search_parallel_dow = $new_parallel_dow было добавлено в конец $pacman_config"
fi

if grep -q "^#Color" "$pacman_config"; then

    sed -i "s/#Color/Color/" "$pacman_config"
    echo "Color был включен"
else
    if grep -q "^Color" "$pacman_config"; then

        echo "Color уже включен"
    else
        echo "Color" >> "$pacman_config"

    fi
fi

if grep -q "^ILoveCandy" "$pacman_config"; then
    #! инвентирует условие
    #-v -инвентирует условие. То есть если НЕ, то условие выполняется
    echo "ILoveCandy уже включен"
else

    sed -i "/^Color/a ILoveCandy" "$pacman_config"
    #-i редактирует файл на месте
    # a/ камманда append в sed, вставляет новую сроку, после найденной строки
    #шаблон вставки: "/что ищем/a что вставляем" "$file"
fi

echo "Идет обновление системы"

pacman -Syu --noconfirm
echo "Обновление завершено"

echo "Идет установка пакетов"
if [ "$downloadPckg" == "yes" ]; then

    # Установка шрифтов
    pacman -S --needed --noconfirm \
        ttf-dejavu noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-liberation \
        ttf-fira-code ttf-jetbrains-mono ttf-hack ttf-nerd-fonts-symbols \
        noto-fonts-extra powerline-fonts

    # установка системных утилит
    pacman -S --needed --noconfirm \
        base-devel bash-completion git wget openssh networkmanager pacman-contrib \
        cpupower power-profiles-daemon apparmor ufw gufw iptables-nft \
        ghostscript fail2ban libpwquality reflector

# Установка игровых пакетов
    pacman -S --needed --noconfirm \
        mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
        gamemode lib32-gamemode steam pavucontrol

# CMD utilities
    pacman -S --needed --noconfirm \
        ripgrep bat lsd duf dust gping dos2unix jq yq \
        fzf rclone irqbalance libqalculate htop \ wl-clipboard

# disk management
    pacman -S --needed --noconfirm \
        ntfs-3g timeshift unrar zip p7zip

# additional packages
    pacman -S --needed --noconfirm \
        chromium mpv vlc tor torbrowser-launcher nyx \
        qbittorrent obsidian flameshot libreoffice-fresh-ru
# codec for vlc mpv
    pacman -S --needed --noconfirm \
        gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly vlc-plugin-ffmpeg
    # если используется ядро hardened, то нужно установить заголовки - extra/linux-hardened-headers
    # поддержка старых видеокарт - xf86-video-ati

else
    echo "Пакеты пропущены"
fi
echo "Пакеты установлены"

if [ "$cpuUpd" == "yes" ]; then

    echo "Обновление микрокода"
    pacman -S --noconfirm amd-ucode
    mkinitcpio -P
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "Микрокод обновлен"


    #Нужно уточнить, нужно ли проводить процедуру после перекомпиляции ядра
else
    echo "Микрокод пропущен"
fi

if [ "$grub_configurator" = "yes" ]; then
    #определяем тип файловой системы для корневого диска

    #Создаем переменную с командой, которая ищет строку, где смонтирован корень
    fstype_var=$(findmnt -n -o FSTYPE / 2>/dev/null || awk '$2 == "/" {print $3}' /proc/mounts)

    #awk - перебирает слова и строки, находит слово type и выводит следующее за ним значение
    grub_params="quiet loglevel=0 rd.systemd.show_status=auto rd.udev.log_level=0 splash rootfstype=$fstype_var selinux=0 raid=noautodetect nowatchdog"

    #проверяем наличие бэкапа
    if [ -f "$grab_conf.original" ]; then
        echo "Бэкап grub уже существует"
    else
        if [ -f "$grab_conf" ]; then
            #Создаем бэкап
            cp "$grab_conf" "$grab_conf.original"
            echo "Был создан бэкап $grab_conf.original"
        else
            echo "Конфиг grub по пути: $grab_conf не был найден"
        fi
    fi

    #Проверяем наличие строки
    if grep -q "^.*$srch_grub_default.*" "$grab_conf"; then

        #изменяем строку
        sed -i "s/^$srch_grub_default=.*/$srch_grub_default=\"$grub_params\"/" "$grab_conf"

    else
        echo "$srch_grub_default не был найден по пути $grab_conf. Вставьте строку:\n $srch_grub_default=\"$grub_params\""

    fi
    #создаем конфиг
    grub-mkconfig -o /boot/grub/grub.cfg

else
    echo "Конфигурация grub пропущена"
fi


#Включаем gamemode
sudo -u "$user_nosudo" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNTIME_DIR/bus" XDG_RUNTIME_DIR="$USER_RUNTIME_DIR" systemctl --user enable gamemoded
sudo -u "$user_nosudo" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNTIME_DIR/bus" XDG_RUNTIME_DIR="$USER_RUNTIME_DIR" systemctl --user start gamemoded
sudo -u "$user_nosudo" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNTIME_DIR/bus" XDG_RUNTIME_DIR="$USER_RUNTIME_DIR" systemctl --user status gamemoded


# установка kitty с ranger

echo "Installing ranger and configuring it for image previews in kitty terminal..."
pacman -S --needed --noconfirm ranger kitty extra/kitty-shell-integration extra/kitty-terminfo extra/python-pillow

#Получаем домашнюю директорию пользователя
if [[ $EUID -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
    #$EUID - переменная, которая содержит ID текущего пользователя
    # -eq - аналог == для других языков
    # 0 - это ID суперпользователя (root)
    # [[ $EUID -eq 0 ]] - условие: если текущий пользователь - суперпользователь
    # && - логическое "и"; оба условия должны быть истинными
    # -n - проверка что строка не пустая
    # $SUDO_USER - переменная в которой храниться имя пользователя, который  запустил команду через sudo
    # [[ -n "$SUDO_USER" ]] - проверяется, что в переменной пользователя, который запустил через sudo, не пустая
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    # getent - команда, которая позволяет получать записи из системных баз данных Linux, к примеру passwd, group или hosts
    # Синтаксис: getent <база данных> <ключ> - getent passwd "$SUDO_USER"
    # getent passwd "$SUDO_USER" - ищем в справочнике passwd пользователя, который запустил команду через sudo
    # | (pipe) — это оператор, который перенаправляет вывод одной команды (getent) на вход другой
    # cut - вывод команды в поток
    # -d: - разделитель, который используется в файле passwd (записи разделены двоеточиями)
    # -f6 - вывод шестого поля, которое соответствует домашней директории пользователя
else
    USER_HOME="$HOME"
fi

#домашняя директория пользователя содержиться в $USER_HOME
echo "Домашняя директория пользователя: $USER_HOME"

#Копируем конфигурационные файлы ranger
echo "Copying ranger configuration files..."
sudo -u "$SUDO_USER" ranger --copy-config=all
echo "Ranger configuration"

rcconf="$USER_HOME/.config/ranger/rc.conf"
metpreview="kitty"

# Проверка существования файла rc.conf
if [[ -f "$rcconf" ]]; then
    # Настройка preview_images
    if grep -q "^set preview_images" "$rcconf"; then
        if grep -q "^set preview_images true" "$rcconf"; then
            echo "set preview_images true already exists in $rcconf."
        else
            sed -i 's/^set preview_images.*/set preview_images true/' "$rcconf"
            echo "Updated set preview_images to true in $rcconf."
        fi
    else
        echo "set preview_images true" >> "$rcconf"
        echo "Added set preview_images true to $rcconf."
    fi

    # Настройка preview_images_method
    if grep -q "^set preview_images_method" "$rcconf"; then
        if grep -q "^set preview_images_method $metpreview" "$rcconf"; then
            echo "set preview_images_method $metpreview already exists in $rcconf."
        else
            sed -i "s/^set preview_images_method.*/set preview_images_method $metpreview/" "$rcconf"
            echo "Updated set preview_images_method to $metpreview in $rcconf."
        fi
    else
        echo "set preview_images_method $metpreview" >> "$rcconf"
        echo "Added set preview_images_method $metpreview to $rcconf."
    fi

    echo "kitty terminal installed and ranger configured with image previews."
else
    echo "Error: $rcconf not found."
fi
# окончание установки kitty с ranger

# Заменяем количество одновременных процессов сборки на количество доступных процессоров
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
# Заменяем количество одновременных процессов сборки на количество доступных процессоров

#TEST Копируем конфиг niri

#!/bin/bash

# Директория, где лежит сам скрипт
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Путь к исходному конфигу
SOURCE_CONFIG="$SCRIPT_DIR/.niri-config/config.kdl"

# Определяем домашнюю директорию пользователя
if [[ -n "$SUDO_USER" ]]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME="$HOME"
fi

# Целевые пути
CONFIG_DIR="$USER_HOME/.config/niri"
CONFIG_FILE="$CONFIG_DIR/config.kdl"

# Проверка существования исходного файла
if [[ ! -f "$SOURCE_CONFIG" ]]; then
    echo "Ошибка: исходный конфиг не найден: $SOURCE_CONFIG"
    exit 1
fi

# Создаём директорию
mkdir -p "$CONFIG_DIR"

# Backup
if [[ -f "$CONFIG_FILE" ]]; then
    BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "Создан backup: $BACKUP_FILE"
fi

# Копирование
cp "$SOURCE_CONFIG" "$CONFIG_FILE"
echo "Конфиг скопирован в: $CONFIG_FILE"

# Права
if [[ -n "$SUDO_USER" ]]; then
    chown "$SUDO_USER":"$SUDO_USER" "$CONFIG_FILE"
fi

echo "Готово"
# Копируем конфиг niri

# Установка paru

# Проверяем, установлен ли paru. Если нет — ставим.
if ! command -v paru >/dev/null 2>&1; then
    sudo pacman -S --noconfirm --needed rust rust-wasm cargo debugedit fakeroot pkgconf openssl git base-devel

    sudo -u "$SUDO_USER" bash -c '
        cd ~ || exit 1
        git clone https://aur.archlinux.org/paru.git
        cd paru || exit 1
        makepkg -si --noconfirm
        cd ~ || exit 1
        rm -rf paru
    '
fi
# Установка paru

#Установка пакетов из AUR
# paru -S --needed --noconfirm alacritty fuzzel mako niri neowall-git swayidle swaylock wl-clipboard-history-git xdg-desktop-portal-gnome xorg-xwayland  xwayland-satellite matugen  cava dms-shell-niri qt6-multimedia-ffmpeg noctalia-shell-git noctalia-qs-git pcmanfm-qt gvfs qt6ct kvantum nohang-git aur/minq-ananicy-git aur/stacer-bin xdman8-beta-git firefox-extension-xdman8-browser-monitor-bin aur/php-codesniffer-phpcsutils aur/php-codesniffer-phpcsextra visual-studio-code-bin fastfetch-git flameshot-git
#Установка пакетов из AUR
# aur/neowall-git можно заменить на swaybg or swww-daemon
# waybar
USER_NAME="${SUDO_USER:?Запускай через sudo от обычного пользователя}"
SUDOERS_FILE="/etc/sudoers.d/99-paru-${USER_NAME}"

# Даём пользователю право ставить пакеты через pacman без второго пароля
printf '%s ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/pacman-key\n' "$USER_NAME" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"
visudo -cf "$SUDOERS_FILE" >/dev/null

# В конце всегда удаляем временное правило
trap 'rm -f "$SUDOERS_FILE"' EXIT

# Запускаем paru от обычного пользователя
# --skipreview убирает "Proceed to review?"
# --sudoloop удерживает sudo-сессию во время долгой сборки
sudo -u "$USER_NAME" paru -S --needed --noconfirm --skipreview --sudoloop \
    alacritty fuzzel mako niri neowall-git swayidle swaylock wl-clipboard-history-git xdg-desktop-portal-gnome xorg-xwayland  xwayland-satellite matugen  cava dms-shell-niri qt6-multimedia-ffmpeg noctalia-shell-git noctalia-qs-git pcmanfm-qt gvfs qt6ct kvantum nohang-git aur/minq-ananicy-git aur/stacer-bin xdman8-beta-git firefox-extension-xdman8-browser-monitor-bin aur/php-codesniffer-phpcsutils aur/php-codesniffer-phpcsextra visual-studio-code-bin fastfetch-git flameshot-git



# Установка и настройка greetd для входа в niri
pacman -S --needed --noconfirm greetd greetd-tuigreet
echo "Настраиваем greetd для входа в niri"

systemctl enable greetd.service

cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --user-menu --cmd niri-session"
user = "greeter"
EOF

# Установка и настройка greetd для входа в niri

# TEST Добавляем значения конфига

#TEST Добавляем значения конфига

echo "включение power-profiles-daemon.service"
#включение профилей производительности
systemctl unmask power-profiles-daemon.service
systemctl enable power-profiles-daemon.service #Запуск при старте системы
systemctl start power-profiles-daemon.service
echo "status power-profiles-daemon.service"
systemctl status power-profiles-daemon.service #Чтобы убедиться, что сервис запущен


pacman -S --noconfirm --needed openresolv
systemctl enable systemd-resolved.service
systemctl start systemd-resolved.service

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
# проверяем статусы служб
#Объявляем массив для служб
# -a - объявляем, что это массив
# -r - объявляем, что массив является неизменяемым, то есть только для чтения
declare -a LIST_SERVICE_CHECK=(
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


# настройка reflector
reflector --country 'Russia' --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

# Установка flatpak # Нужно в конце, так как qalculate-qt будет долгим
pacman -S --noconfirm --needed flatpak flatpak-kcm flatpak-xdg-utils
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub io.github.Qalculate.qalculate-qt org.telegram.desktop

# Установка и настройка zsh с ohmyzsh
echo "Начинаем установку и настройку zsh с ohmyzsh"


# устанавливаем zsh и дополнительные пакеты
pacman -S --needed --noconfirm git curl zsh fzf powerline-fonts zsh-syntax-highlighting zsh-autosuggestions

# Установка фреймворка Oh My Zsh
sudo -u "$SUDO_USER" bash -c '
cd ~
sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended
chsh -s $(which zsh)
# chsh — это команда, которая меняет оболочку входа пользователя в систему
'

# Необходимо экранировать кавычки внутри команды bash -c, если открывается с двойных кавычек

# Установка темы Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
# Установка дополнительных плагинов
git clone https://github.com/zsh-users/zsh-completions.git  $USER_HOME/.oh-my-zsh/custom/plugins/zsh-completions
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $USER_HOME/.oh-my-zsh/custom/plugins/you-should-use
git clone https://github.com/Aloxaf/fzf-tab $USER_HOME/.oh-my-zsh/custom/plugins/fzf-tab

# Создаем симлинки на системные плагины
sudo -u "$SUDO_USER" bash << 'EOF'
ln -sf /usr/share/zsh/plugins/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/
ln -sf /usr/share/zsh/plugins/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/
EOF

if [[ -f  $USER_HOME/.zshrc ]]; then
# изменяем тему в .zshrc на powerlevel10k
sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$USER_HOME/.zshrc"
# добавляем плагины
    sed -i 's/plugins=.*/plugins=( git zsh-syntax-highlighting zsh-autosuggestions extract you-should-use fzf-tab)/' $USER_HOME/.zshrc

# Переменные для замены
original='source "$ZSH/oh-my-zsh.sh"'

replacement='fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit
source "$ZSH/oh-my-zsh.sh"'

# Выполняем замену
sed -i "s|$original|$replacement|" $USER_HOME/.zshrc


else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> $USER_HOME/.zshrc
fi


echo "Для вступления изменений в силу, перезайдите в систему или выполните команду: exec zsh"


#возможно стоит добавить выбор локалей
echo "Если вас не устраивает устанволенная локаль, то прмините команды
sudo nano /etc/locale.gen          # Редактирование локалей
sudo locale-gen                    # Генерация локалей"
