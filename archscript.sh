#!/bin/bash
exec > >(tee -a "outputarchauto.log") 2>&1

journalctl --vacuum-size=30M
journalctl --verify
systemctl restart systemd-journald
#gitpush
y="yes"
yay="yes"
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

user_nosudo="$SUDO_USER"
path_yay_cfg="/home/$user_nosudo/.config/yay/config.json"
srch_yay_config="cleanAfter"
nohang="yes"
ananicy="yes"
trim="yes"


grab_conf="/etc/default/grub"
srch_grub_default="GRUB_CMDLINE_LINUX_DEFAULT"

irqbalance="yes"
stacer_xdman="yes"
grub_configurator="yes"

USER_RUNTIME_DIR="/run/user/$(id -u $user_nosudo)"

#$search_maxuse и так далее - переменные



sudo pacman -S --needed --noconfirm man-db xorg xorg-xinit xf86-video-amdgpu plasma-meta konsole dolphin sddm ttf-dejavu ttf-liberation noto-fonts pipewire pipewire-pulse wireplumber amd-ucode power-profiles-daemon acpi acpid plasma-nm networkmanager-openvpn mesa mesa-vdpau libva-mesa-driver vulkan-radeon ark spectacle gwenview kate kscreen kdeconnect gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc ntfs-3g exfatprogs bluez bluez-utils xdg-user-dirs xdg-utils plasma-wayland-session plasma-nano plasma-browser-integration plasma-thunderbolt plasma-zeroconf plasma-disks plasma-systemmonitor plasma-pa openssh

systemctl enable --now acpid.service
systemctl enable --now sddm.service
systemctl enable --now NetworkManager.service
systemctl enable --now bluetooth.service

# select sshEnable in "Yes" "No"; do 
# case $sshEnable in
#     Yes )

# systemctl enable --now sshd.service
# systemctl status sshd
# ;;
# break
#     No )
# echo "SSH service not enabled."
# ;;
# break

#     * )
# echo "Invalid option. Please select Yes or No."
# ;;
# esac 
# done

# if [ -f /etc/ssh/sshd_config ]; then

# sed -i 's/#Port 22/#Port 2414/' /etc/ssh/sshd_config
# sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
# sudo systemctl restart sshd
# ip a
# else 
# echo "sshd_config not found, please check your SSH installation."

# fi



#Проверка для создания бэкапа
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
echo "*^$search_maxuse был заменен"
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

if grep -q "^$search_parallel_dow.*" "$pacman_config"; then

sed -i "s/^$search_parallel_dow.*/$search_parallel_dow = $new_parallel_dow/" "$pacman_config"

echo "$search_parallel_dow было заменено значение на $new_parallel_dow"

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

pacman -Sy --noconfirm
pacman -Su --noconfirm
echo "Обновление завершено"

echo "Идет установка пакетов"
if [ "$y" == "yes" ]; then
pacman -S --needed --noconfirm bash-completion xf86-video-ati mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon gamemode plasma-sdk kio-extras lib32-gamemode chromium cpupower openssh networkmanager git wget xdg-user-dirs pacman-contrib ntfs-3g timeshift apparmor ufw fail2ban libpwquality tor nyx tailscale extra/linux-hardened-headers multilib/steam-native-runtime pavucontrol plasma-browser-integration gwenview filelight unrar zip power-profiles-daemon fastfetch terminator code
else
echo "Пакеты пропущены"
fi
echo "Пакеты установлены"

#Включение apparmor
systemctl enable apparmor
systemctl start apparmor

echo "включение power-profiles-daemon.service"
#включение профилей производительности
systemctl unmask power-profiles-daemon.service
systemctl enable power-profiles-daemon.service #Запуск при старте системы
systemctl start power-profiles-daemon.service
echo "status power-profiles-daemon.service"
systemctl status power-profiles-daemon.service #Чтобы убедиться, что сервис запущен

#Добавление правил
ufw default allow outgoing
ufw default deny incoming
ufw enable #Включение фаервола
echo "ufw status"
ufw status verbose #Проверка статуса фаервола

if [ "$y" == "yes" ]; then

echo "Обновление микрокода"
pacman -S --noconfirm amd-ucode
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg

#Нужно уточнить, нужно ли проводить процедуру после перекомпиляции ядра
else
echo "Микрокод пропущен"
fi
echo "Микрокод обновлен"

#возможно стоит добавить выбор локалей
echo "Если вас не устраивает устанволенная локаль, то прмините команды
sudo nano /etc/locale.gen          # Редактирование локалей
sudo locale-gen                    # Генерация локалей"

#установка yay
if [ "$yay" = "yes" ]; then
#проверяем равно ли значение пременной
{
#Создается subshell; Все команды выполняеются в отдельном процессе; Изменения не влияют на родительский процесс
#sudo -u - это опция конкретной команды sudo, поэтому без нее нельзя запускать
#-u опция, которая указывает от имени какого пользователя необходимо запустить команду
sudo -u "$SUDO_USER" bash -c '
cd ~
pacman -Sy --noconfirm
pacman -Su --noconfirm
pacman -S --needed --noconfirm base-devel git

git clone https://aur.archlinux.org/yay.git
cd yay
yes | makepkg -si
cd ~
rm -rf yay
yay -Y --gendb --noconfirm && yay -Y --devel --save
yay --version
'
yay -Syu
#SUDO_USER - переменная системы, это пользователь, который вызвал SUDO
#sudo -u "$SUDO_USER" bash -c - вызывает subshell от имени пользователя, который вызвал команду sudo
#Все команды выполняются в отдельном subshell
#Кавычки должны быть одинарные
}
else
echo "Установка yay пропущена"
fi

#Создание конфигурационного файла и редактирование конфига yay

if grep -q "\"$srch_yay_config\".*" "$path_yay_cfg"; then
#Проверяем существование сроки в конфиге
if grep -q "\"$srch_yay_config\": true," "$path_yay_cfg"; then
echo "$srch_yay_config уже true"
#проверяем не является ли false
else
sed -i "s/\"$srch_yay_config\".*/\"$srch_yay_config\": true,/" "$path_yay_cfg"
echo "$srch_yay_config был изменен на true"
#Изменяем на true
fi
else
echo "Строка \"$srch_yay_config\": true, не существует по пути $path_yay_cfg"
if grep -q "{" "$path_yay_cfg"; then
sed -i '/^{/a\
\t"'"$srch_yay_config"'": true,' "$path_yay_cfg"
#\t - символ табуляции
echo "Строка \"$srch_yay_config\": true, была добавлена по пути $path_yay_cfg"
else
echo "Возникла критическая ошибка в редактировании конфигурационного файла yay. Строка \"$srch_yay_config\": true, не была добавлена по пути $path_yay_cfg"
fi
fi

#Установка nohang
if [ "$nohang" = "yes" ]; then
sudo -u "$SUDO_USER" bash -c '
cd ~
yay -S --needed  --noconfirm nohang-git
yay -Yc --noconfirm'
cp /etc/nohang/nohang-desktop.conf /etc/nohang/nohang.conf
systemctl enable --now nohang-desktop
echo "nohang status:"
systemctl status nohang-desktop.service
else
echo "nohang-git был пропущен"
fi

#Установка ananicy
if [ "$ananicy" = "yes" ]; then
sudo -u "$SUDO_USER" bash -c '

yay -S --needed  --noconfirm aur/minq-ananicy-git
yay -Yc --noconfirm
'

systemctl enable --now ananicy
echo "ananict-git status: "
systemctl status ananicy
else
echo "ananicy-git был пропущен"
fi

#Установка stacer and xdman
if [ "$stacer_xdman" = "yes" ]; then
sudo -u "$SUDO_USER" bash -c "
yay -S --needed --noconfirm aur/stacer-bin
yay -S --needed --noconfirm aur/xdman
yay -S --needed --noconfirm aur/firefox-extension-xdman8-browser-monitor-bin
yay -Yc --noconfirm"
else
echo "stacer и xdman были пропщуены"
fi

#установка irqbalance
if [ "$irqbalance" = "yes" ]; then
sudo -u "$SUDO_USER" bash -c "
yay -S --needed --noconfirm extra/irqbalance
yay -Yc --noconfirm"
systemctl enable --now irqbalance
echo "Статус irqbalance:"
systemctl status irqbalance
else
echo "irqbalance был пропущен"
fi

#Включение trim
if [ "$trim" = "yes" ]; then
systemctl enable fstrim.timer
fstrim -va
echo "Статус службы fstrim"
systemctl status fstrim.timer
else
echo "trim был пропущен"
fi

if [ "$grub_configurator" = "yes" ]; then
#определяем тип файловой системы для корневого диска
# fstype=$(mount | grep ' on / ')

#Создаем переменную с командой, которая ищет строку, где смонтирован корень
fstype_var=$(findmnt -n -o FSTYPE / 2>/dev/null || awk '$2 == "/" {print $3}' /proc/mounts)
# fstype_var=$(echo "$fstype" | awk '{for(i=1;i<=NF;i++) if($i=="type") print $(i+1)}')
# fstype_var=$(findmnt -n -o FSTYPE /)
#awk - перебирает слова и строки, находит слово type и выводит следующее за ним значение
grub_params="quiet loglevel=0 rd.systemd.show_status=auto rd.udev.log_level=0 splash rootfstype=$fstype_var selinux=0 raid=noautodetect elevator=noop nowatchdog"
#lpj=3499912
#noibpb - Отключает защиту от атак типа Spectre v2, Позволяет злоумышленнику обходить изоляцию между процессами 
# no_stf_barrier - Отключает защиту от атак типа Microarchitectural Data Sampling, Позволяет атаковать секретные данные (пароли, ключи шифрования) через уязвимости типа RIDL, Fallout, ZombieLoad
# tsx=on - Активирует Intel Transactional Synchronization Extensions — технологию для ускорения многопоточных операций.
# tsx_async_abort=off - Полностью отключает защиту от атаки TSX Asynchronous Abort TAA позволяет атакующему читать произвольные данные из памяти ядра 



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
echo "$srch_grub_default не был найден по пути $grab_conf. Вставьте строку:\n
$srch_grub_default=\"$grub_params\""

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

#установка reflector
pacman -S --noconfirm --needed reflector
reflector --country 'Russia' --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyu
systemctl enable reflector.service
systemctl start reflector.service
systemctl enable reflector.timer




pacman -Scc --noconfirm












