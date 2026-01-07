# Установка yay
if [ "$yay" = "yes" ]; then
#проверяем равно ли значение пременной
{

if [ -f "/etc/resolv.conf" ]; then 

echo "Файл найден"
echo "
nameserver 8.8.8.8
nameserver 1.1.1.1
" > /etc/resolv.conf

else 
echo "Файл  не найден"

fi
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

yay -Syu
#SUDO_USER - переменная системы, это пользователь, который вызвал SUDO
#sudo -u "$SUDO_USER" bash -c - вызывает subshell от имени пользователя, который вызвал команду sudo
#Все команды выполняются в отдельном subshell
#Кавычки должны быть одинарные
}
else
echo "Установка yay пропущена"
fi

# Можно попробовать один из этих сопособов
# sudo pacman -S --needed base-devel git
# git clone https://aur.archlinux.org/yay-bin.git
# cd yay-bin
# makepkg -si
# sudo -u "$SUDO_USER" bash -c '
# cd ~
# wget https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz
# tar -xvf yay.tar.gz
# cd yay
# makepkg -si --noconfirm
# '

#Создание конфигурационного файла и редактирование конфига yay

path_yay_cfg="/home/$user_nosudo/.config/yay/config.json"
srch_yay_config="cleanAfter"

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

#Установка пакетов из yay
if [ "$yay_packages" = "yes" ]; then
sudo -u "$SUDO_USER" bash -c '
cd ~
yay -S --needed  --noconfirm nohang-git aur/minq-ananicy-git aur/stacer-bin xdman firefox-extension-xdman8-browser-monitor-bin 
yay -Yc --noconfirm
'
# extra/irqbalance extra/libqalculate
cp /etc/nohang/nohang-desktop.conf /etc/nohang/nohang.conf
else
echo "yay_packages был пропущен"
fi