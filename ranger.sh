#!/bin/bash

pacman -S --needed --noconfirm ranger kitty extra/kitty-shell-integration extra/kitty-terminfo extra/python-pillow
ranger --copy-config=all

rcconf="~/.config/ranger/rc.conf"
metpreview="kitty"
# В rc.conf добавить:
if [[ -f $rcconf ]]; then

#проверяем существует ли set preview_images в файле rc.conf
if grep -q "set preview_images" "$rcconf"; then
#проверяем равна ли она true
if grep -q "set preview_images true" "$rcconf"; then
  echo "set preview_images true already exists in $rcconf."
else
#Если set preview_images есть, но не true, то заменяем на true
  sed -i 's/^set preview_images.*/set preview_images true/' "$rcconf"
  echo "Updated set preview_images to true in $rcconf."
fi
else
sed -i 's/^set preview_images.*/set preview_images true/' "$rcconf"
#sed - команда для заменты строки
#-i - замена в файле на месте 
# типовая конструкция sed -i 's/шаблон/замена/' файл
fi
else
#Если set preview_images нет, то добавляем в конец файла
echo "set preview_images true" >> "$rcconf"
fi
else
    echo "Error: $rcconf not found."
fi

if grep -q "set preview_images_method" "$rcconf"; then
if grep -q "set preview_images_method $metpreview" "$rcconf"; then
    echo "set preview_images_method $metpreview already exists in $rcconf."
    else
    sed -i 's/^set preview_images_method.*/set preview_images_method $metpreview/' "$rcconf"
    echo "Updated set preview_images_method to $metpreview in $rcconf."
    fi
    else
    echo "set preview_images_method $metpreview" >> "$rcconf"
    echo "Added set preview_images_method $metpreview to $rcconf."
else
fi
echo "kitty terminal installed and ranger configured with image previews."