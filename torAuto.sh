#!/bin/bash

#Переменные
pkgtor="tor"
pkgnyx="nyx"
pkgtorsocks="torsocks"
pathTorc="/etc/tor/torrc"


#Проверяем установлен ли пакет
if pacman -Qi "$pkgtor" &>/dev/null; then
echo "Package $pkgtor is exist in your system"
else
#Проверяем существует ли в pacman пакет
if pacman -Ss "$pkgtor" &>/dev/null; then
echo "$pkgtor is exist in pacman"
echo "$pkgtor installing"
sudo pacman -Syu
sudo pacman -S --needed --noconfirm "$pkgtor"
else
echo "pls, install tor"
fi
fi

if pacman -Qi "$pkgnyx" &>/dev/null; then
echo "Package $pkgnyx is esist in your system"
else
if pacman -Ss "$pkgnyx" &>/dev/null; then
echo "$pkgnyx is exist in pacman"
echo "$pkgtor installing"
sudo pacman -S --needed --noconfirm "$pkgnyx"
else
echo "pls, install $pkgnyx"
fi
fi

if pacman -Qi "$pkgtorsocks" &>/dev/null; then
echo "Package $pkgtorsocks is exist in your system"
else
if pacman -Ss "$pkgtorsocks" &>/dev/null; then
echo "$pkgtorsocks is exist in pacman"
echo "$pkgtorsocks installing"
sudo pacman -S --needed --noconfirm "$pkgtorsocks"
else
echo "pls, install $pkgtorsocks"
fi
fi

while true; do
# while true; do done
#while - цикл, который выполняется, пока блок истинный
#true - передача истины
read -r -p "Введите имя пакета, который вы хотите запустить: " appName
#read - команда для считывания ввода пользователя
#-r - заставляет read воспринимать все символы буквально
#-p - Отображение текста перед вводом пользователя
#appName - имя переменной

if [[ -n $appName ]]; then
# [[]] - расширенный синтаксис bash
#-n - проверка, что длинна строки больше нуля
echo "$appName"
break
#break - прерывание ближайшего цикла, в данном случае выход из while
fi
done

if grep -qF "ControlPort" "$pathTorc"; then
echo "is exist"
if [[ "ControlPort" == "9051" ]] "$pathTorc"; then
fi
fi






