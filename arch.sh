#Установка Arch Linux
#git remote add origin https://github.com/DeryKams/archauto.git
#git remote -v
#git commit -m "commit1"
#git push

#Установка Arch Linux

#Установка видеодрайверов
pacman -S --needed --noconfirm xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa
# Для Intel: sudo pacman -S xf86-video-intel
# Для NVIDIA: sudo pacman -S nvidia nvidia-utils

# Установка шрифтов 
pacman -S --needed --noconfirm ttf-dejavu noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-liberation ttf-fira-code ttf-jetbrains-mono ttf-hack ttf-nerd-fonts-symbols

#Установите Xorg:
pacman -S --needed --noconfirm xorg xorg-xinit xorg-apps xorg-server mesa-libgl xorg-server-xwayland wayland libxkbcommon

# Установите KDE Plasma:
pacman -S --needed --noconfirm plasma plasma-wayland-session egl-wayland sddm sddm-kcm packagekit-qt5 kde-applications network-manager-applet system-settings git wget
pacman -S --needed --noconfirm  konsole dolphin ark kalk kate kclock kcolorchooser gwenview spectacle partitionmanager plasma-systemmonitor vlc firefox ffmpegthumbs xdg-desktop-portal-gtk xwaylandvideobridge qt6-imageformats kimageformats kdialog

#pipwire
pacman -S --needed --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber pipewire-jack pipewire-audio pavucontrol helvum qpwgraph 

systemctl enable --now pipewire pipewire-pulse wireplumber

#Включите SDDM:
systemctl enable sddm
systemctl status sddm
#запускаем оболочку
systemctl start sddm

#аплете отображения сетевых подключений
systemctl enable NetworkManager
systemctl start NetworkManager
systemctl status NetworkManager
systemctl enable pipewire pipewire-pulse

#протокол динамической конфигурации узла
systemctl enable dhcpd
systemctl start dhcpd
systemctl status dhcpd




#Уменьшаем журнал
journalctl --vacuum-size=30M  
journalctl --verify
sudo systemctl restart systemd-journald


nano /etc/systemd/journald.conf
systemmaxuse=50M
systemmaxfilesize=40M

#проценты после которой начинается выгрузка из ОЗУ; параметр оперативная память будет выгружаться в своп при достижении 90% занятости.
/etc/sysctl.conf
vm.swappiness=10
sysctl -p

#параметр определяет, на сколько ваша операционная система готова держать кэши в оперативной памяти или же сливать их своп
/etc/sysctl.conf
vm.swappiness=30
vm.vfs_cache_pressure=80
sysctl -p

#Настройка Pacman
sudo nano /etc/pacman.conf
color
ParallelDowloads = 10
ILoveCandy

###################
#установка пакетов
sudo pacman -Syu && sudo pacman -S --needed bash-completion xf86-video-ati mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon gamemode plasma-sdk kio-extras lib32-gamemode chromium cpupower openssh networkmanager git wget xdg-user-dirs pacman-contrib ntfs-3g timeshift apparmor ufw fail2ban libpwquality tor nyx tailscale extra/linux-hardened-headers multilib/steam-native-runtime pavucontrol plasma-browser-integration gwenview filelight unrar zip power-profiles-daemon fastfetch terminator code

systemctl unmask power-profiles-daemon.service systemctl start power-profiles-daemon.service #включение профилей производительности

sudo ufw enable                    # Включение фаервола

###################
#обновляем микрокод
sudo pacman -S amd-ucode 
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg


###################
#Добавление локалей
sudo nano /etc/locale.gen          # Редактирование локалей
sudo locale-gen                    # Генерация локалей

# Добавление языков
# Отредактируйте файл локалей:
# nano /etc/locale.gen
# Раскомментируйте или добавьте строки:
# en_US.UTF-8 UTF-8
# ru_RU.UTF-8 UTF-8
# Генерация локалей
# Сгенерируйте локали:
# locale-gen
# Установка языка системы
# Установите язык системы:
# echo "LANG=en_US.UTF-8" > /etc/locale.conf


###################
# Клонируем репозиторий yay
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si --noconfirm
cd ~ && rm -rf yay
yay -Y --gendb && yay -Y --devel --save

#Создание конфигурационного файла
nano ~/.config/yay/config.json
{
"cleanafter": true,
}

###################
#Nohang - следит за потреблением озу

git clone https://aur.archlinux.org/nohang-git.git

cd nohang-git

makepkg -sric  

sudo systemctl enable --now nohang-desktop 

## или
yay -S ananicy-git
sudo systemctl enable --now ananicy

#Демон управляющий приоритетом распределения ресусов между задачами Ananicy

git clone https://aur.archlinux.org/ananicy-git.git 

cd ananicy-git

makepkg -sric

sudo systemctl enable ananicy 
## или 

yay -S ananicy-git
sudo systemctl enable --now ananicy

#Включаем службу Trim файловой системы

sudo systemctl enable fstrim.timer

sudo fstrim -v /  (зпустить трим вручную) 

если предыдущая не сработала используй эту  sudo fstrim -va / 

sudo systemctl enable fstrim.timer

###################
#Оптимизация загрузки системы , следующими параметрами

sudo nano /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=0 rd.systemd.show_status=auto rd.udev.log_level=0 splash rootfstype=btrfs selinux=0 lpj=3499912 raid=noautodetect noibpb no_stf_barrier tsx=on tsx_async_abort=off elevator=noop nowatchdog"
sudo grub-mkconfig -o /boot/grub/grub.cfg

#Парамертры оптимизации SSD
sudo nano /etc/fstab
rw,relatime,ssd,ssd_spread,space_cache=v2,max_inline=256,compress=zstd:3,commit=120 #перед subvol, commit=120

###################
#Установка Stacer и Xdman

yay -S irqbalance stacer-bin xdman
sudo systemctl enable irqbalance
# irqbalance - Служба, которая распределяет аппаратные прерывания (interrupts) между ядрами процессора в многоядерной системе
# stacer-bin - Позволяет удобно видеть загрузку процессора, использование памяти, управлять автозагрузкой, очисткой кэша и другими параметрами системы
# xdman - Для удобного и быстрого скачивания файлов из интернета с возможностью возобновления прерванных загрузок.


#Установка Stacer --
git clone https://aur.archlinux.org/stacer-bin.git
cd stacer-bin 
makepkg -sric

#Установка Xdman
git clone https://aur.archlinux.org/xdman.git
cd xdman 
makepkg -sric

#tool that distributes hardware interrupts across processors to improve system performance
yay -Sy irqbalane

###################
#Очистка пакетов 
Pacman -Scc
sudo pacman -S pacman-contrib

# включаем gamemode
sudo systemctl enable gamemoded.

#установка reflector
sudo pacman -S reflector
sudo reflector --country 'Russia,' --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syyu
sudo systemctl enable reflector.service
sudo systemctl start reflector.service
sudo systemctl enable reflector.timer

###################

#Ошибка unprivileged_userns_clone =0

cat /proc/sys/kernel/unprivileged_userns_clone

sudo sysctl kernel.unprivileged_userns_clone=1

nano ~/.bashrc
alias steam='sudo sysctl kernel.unprivileged_userns_clone=1 && setsid /usr/bin/steam-native'

1.2. Оптимизация mkinitcpio
initramfs (первоначальный RAM-диск) загружается перед основной системой. Его можно и нужно оптимизировать.
Использовать сжатие lz4 или zstd: Они намного быстрее, чем стандартный gzip, при распаковке во время загрузки. Это один из самых простых и эффективных способов ускорить загрузку. В файле /etc/mkinitcpio.conf измени строку:
Generated code
COMPRESSION="zstd" 
```*   **Уменьшить количество хуков**: В строке `HOOKS=(...)` в том же файле оставь только то, что тебе действительно нужно. Например, если у тебя нет LVM или шифрования, хуки `lvm2` и `encrypt` не нужны.
Use code with caution.
1.3. Оптимизация Systemd-boot или другого загрузчика
Уменьшить таймаут: В файле loader.conf (для systemd-boot) или grub.cfg установи таймаут выбора ОС на 0 или 1 секунду, если тебе не нужно меню загрузки.
2. Оптимизация Файловой Системы и Дисковых Операций
2.1. Выбор и настройка файловой системы
Btrfs: Современная и быстрая ФС. Позволяет использовать прозрачное сжатие на лету (compress=zstd), что не только экономит место, но и может ускорить чтение/запись на медленных дисках (особенно HDD), так как сжатые данные занимают меньше места и быстрее считываются.
Опции монтирования в /etc/fstab: rw,noatime,compress=zstd,space_cache=v2,discard=async
F2FS: Оптимизирована специально для флеш-памяти (SSD, NVMe). Часто показывает лучшие результаты в тестах производительности на SSD.
2.2. Preloading (Предварительная загрузка)
Сервисы, которые анализируют часто запускаемые приложения и заранее подгружают их библиотеки в ОЗУ.
preload: Старый, но все еще рабочий демон.
prelockd: Более современный и интеллектуальный аналог, разработанный создателем nohang. Он анализирует использование и "закрепляет" (mlock) нужные файлы в памяти.
systemd-readahead (устарел, но концепция важна): Раньше systemd пытался делать это автоматически. Сейчас эта функциональность удалена, но идея остается актуальной.
4.1. Использование альтернативных аллокаторов памяти
Стандартный аллокатор памяти в Linux (glibc malloc) — это универсальное решение. Специализированные аллокаторы могут быть быстрее в многопоточных приложениях (игры, компиляция).
mimalloc или jemalloc: Могут быть использованы для всей системы или для отдельных приложений через LD_PRELOAD. Это может дать заметный прирост производительности в некоторых сценариях.
Generated bash
# Запуск приложения с mimalloc
LD_PRELOAD="/usr/lib/libmimalloc.so" steam
Use code with caution.
Bash
4.2. Оптимизация makepkg для сборки из AUR
Ты уже используешь yay, который под капотом вызывает makepkg. Его можно настроить.
В /etc/makepkg.conf:
CFLAGS и CXXFLAGS: Добавь -march=native -O2 (или -O3, но это может быть менее стабильно) для оптимизации сборки под твой CPU.
MAKEFLAGS: Установи -j$(nproc) для использования всех ядер процессора при компиляции. Yay часто делает это автоматически, но проверить стоит.
4.3. Сетевые оптимизации (sysctl)
Для уменьшения задержек в онлайн-играх и улучшения отзывчивости сети можно добавить в твой 99-custom.conf:
Generated code
# Уменьшить задержку TCP
net.ipv4.tcp_low_latency = 1
# Включить TCP Fast Open
net.ipv4.tcp_fastopen = 3
