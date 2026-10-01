#!/bin/bash

exec > >(tee -a "outputarchauto.log") 2>&1

# set -euo pipefail
#TODO Переписать редактирование json на утилиту jq
#TODO Пользовательские службы systemd требуют доступа к пользовательской сессии D-Bus. Скрипт пытается передать переменные DBUS_SESSION_BUS_ADDRESS и XDG_RUNTIME_DIR, но это не гарантирует успех. Если у пользователя нет активной графической сессии в момент запуска скрипта, D-Bus не будет доступен, и команда завершится ошибкой. Это крайне ненадежный метод.
# Проверка на root
#Установка Arch Linux
#TODO добавить функции вывода сообщений
# info() {
#     echo -e "\033[1;34m[INFO]\033[0m $1"
# }

# success() {
#     echo -e "\033[1;32m[SUCCESS]\033[0m $1"
# }

# warning() {
#     echo -e "\033[1;33m[WARNING]\033[0m $1"
# }

# выбор aur helper

aur_choice="none"

echo "=== Выбор помощника для установки ==="
echo ""
echo "Пожалуйста, выберите вариант:"
echo "1) Paru - Современный помощник для Arch Linux"
echo "2) Yay - Yet Another Yogurt (популярный AUR-хелпер)"
echo "3) Do not install - Не устанавливать ничего"
echo ""

read -p "Введите номер вариант (1-3): " choice
# read - команда, которая читает ввод пользователя и сохраняет его в $REPLY
# -p - флаг, который выводит сообщение пользовтелю перед его вводом
# choice - переменная, в которую мы сохраняем ввод пользователя

case $choice in
    
    # case - конструкция для ветвления различных условий
    # case- начало контрукции выбора
    # $choice - переменная, которую мы проверяем
    # in - ключевое слово, которое обозначает начало блока условий
    
    1)
        echo "Вы выбрали Paru в качестве помощника для установки."
        aur_choice="paru"
        # 1) шаблон сравнения для переменной $choice
        
    ;;
    # ;; - разделитель, обозначающий конец блока условий
    
    2)
        echo "Вы выбрали Yay в качестве помощника для установки."
        aur_choice="yay"
        
    ;;
    
    3|*)
        echo "Вы выбрали не устанавливать помощника для установки или выбрали недопустимый параметр."
        aur_choice="none"
        
    ;;
    # * - обработка всех остальных случаев, не входящий в другие
esac

# esac - обратное написание case, обозначающее конец конструкции выбора
# выбор aur helper


#Ограничение журнала systemd
if [[ -f "./lib/journal.sh" ]]; then
    source "./lib/journal.sh"
else
    echo "Модуль ограничения журнала отсутствует в папке lib или нет доступа" >&2
fi

# Настройка swap и cache pressure в systemctl
if [[ -f "./lib/sysctl.sh" ]]; then
    source "./lib/sysctl.sh"
else
    echo "Модуль настройки sysctl отсутствует в папке lib или нет доступа" >&2
fi

# Настройка ILoveCandy, Color и ParallelDownloads в pacman
if [[ -f "./lib/pacman.sh" ]]; then
    source "./lib/pacman.sh"
else
    echo "Модуль настройки pacman отсутствует в папке lib или нет доступа" >&2
fi

y="yes"
mkinitcpio="yes"
yay_packages="yes"
trim="yes"
grab_conf="/etc/default/grub"
srch_grub_default="GRUB_CMDLINE_LINUX_DEFAULT"
grub_configurator="yes"
user_nosudo="$SUDO_USER"
USER_RUNTIME_DIR="/run/user/$(id -u $user_nosudo)"
#$search_maxuse и так далее - переменные

echo "Идет обновление системы"

pacman -Syu --noconfirm
echo "Обновление завершено"


echo "Идет установка пакетов"
if [ "$y" == "yes" ]; then
   
# Скрипт установки пакетов из pacman
# Список пакетов лежит по соотвествующему пути в lib/pkginstall.sh
if [[ -f "./lib/pkginstall.sh" ]]; then
    source "./lib/pkginstall.sh"
else
    echo "Модуль пакетов отсутствует в папке lib или нет доступа" >&2
fi

echo "Пакеты установлены"

else
    echo "Пакеты пропущены"
fi


#Добавление правил
# ufw default allow outgoing
# ufw default deny incoming
# ufw enable #Включение фаервола
# echo "ufw status"
# ufw status verbose #Проверка статуса фаервола



if [ "$mkinitcpio" == "yes" ]; then
    
if [[ -f "./lib/mkinitcpio.sh" ]]; then
    source "./lib/mkinitcpio.sh"
else
    echo "Модуль установки микрокода отсутствует в папке lib или нет доступа" >&2
fi
echo "Микрокод обновлен"

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


# Установка kitty с ranger
if [[ -f "./lib/kitty.sh" ]]; then
    source "./lib/kitty.sh"
else
    echo "Модуль установки kitty отсутствует в папке lib или нет доступа" >&2
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


# Начало установки aur helper
if [ "$aur_choice" != "none" ]; then
    # Проверяем, необходимо ли устанавливать aur helper
    
    # Настройка DNS
    if [ -f "/etc/resolv.conf" ]; then
        
        echo "Файл найден"
        echo "
nameserver 8.8.8.8
nameserver 1.1.1.1
        " > /etc/resolv.conf
        
    else
        echo "Файл  не найден"
        
    fi
    # Настройка DNS
    
    # Установка paru
    
    if [[ "$aur_choice" == "paru" ]]; then
        
        # зависимости для сборки paru
        sudo pacman -S --noconfirm --needed rust rust-wasm cargo debugedit fakeroot pkgconf openssl
        
        sudo -u "$SUDO_USER" bash -c '
cd ~
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ~
rm -rf paru
        '
        
    fi
    # Установка paru
    
    # Установка yay
    if [ "$aur_choice" == "yay" ]; then
        #Создается subshell; Все команды выполняеются в отдельном процессе; Изменения не влияют на родительский процесс
        #sudo -u - это опция конкретной команды sudo, поэтому без нее нельзя запускать
        #-u опция, которая указывает от имени какого пользователя необходимо запустить команду
        sudo -u "$SUDO_USER" bash -c '
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
yes | makepkg -si
cd ~
rm -rf yay
yay -Y --gendb --noconfirm && yay -Y --devel --save
yay --version
        '
        #SUDO_USER - переменная системы, это пользователь, который вызвал SUDO
        #sudo -u "$SUDO_USER" bash -c - вызывает subshell от имени пользователя, который вызвал команду sudo
        #Все команды выполняются в отдельном subshell
        #Кавычки должны быть одинарные
        
        # Обновляем систему
        yay -Syu
        
        
        
    fi
    # Установка yay
    
    
fi
# Окончание установки aur helper

#Установка пакетов из aur helper
# Список пакетов, проверка конфликтов с установленными аналогами и
# настройка nohang вынесены в модуль lib/pkgAurInstall.sh
if [[ -f "./lib/pkgAurInstall.sh" ]]; then
    source "./lib/pkgAurInstall.sh"
else
    echo "Модуль AUR-пакетов отсутствует в папке lib или нет доступа" >&2
fi
#Установка пакетов из aur helper

###################

#Включение apparmor
# systemctl enable apparmor
# systemctl start apparmor

echo "включение power-profiles-daemon.service"
#включение профилей производительности
systemctl unmask power-profiles-daemon.service
systemctl enable power-profiles-daemon.service #Запуск при старте системы
systemctl start power-profiles-daemon.service
echo "status power-profiles-daemon.service"
systemctl status power-profiles-daemon.service #Чтобы убедиться, что сервис запущен

#Включение trim
if [ "$trim" = "yes" ]; then
    systemctl enable --now fstrim.timer
    fstrim -va
    echo "Статус службы fstrim"
    systemctl status fstrim.timer
else
    echo "trim был пропущен"
fi

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
flatpak install -y io.github.Qalculate.qalculate-qt org.telegram.desktop

pacman -Scc --noconfirm

# Установка и настройка zsh с ohmyzsh
echo "Начинаем установку и настройку zsh с ohmyzsh"

USER_HOME=$(eval echo ~$SUDO_USER)

# устанавливаем zsh и дополнительные пакеты
pacman -S --needed --noconfirm git curl zsh fzf powerline-fonts zsh-syntax-highlighting zsh-autosuggestions 

# Установка фреймворка Oh My Zsh
sudo -u "$SUDO_USER" bash -c "
cd ~
sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended
chsh -s $(which zsh)
# chsh — это команда, которая меняет оболочку входа пользователя в систему
"
# Необходимо экранировать кавычки внутри команды bash -c, если открывается с двойных кавычек

# Установка темы Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k
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
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' $USER_HOME/.zshrc
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

