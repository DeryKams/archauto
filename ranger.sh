#!/bin/bash
rcconf="$HOME/.config/ranger/rc.conf"
metpreview="kitty"

echo "Installing ranger and configuring it for image previews in kitty terminal..."
pacman -S --needed --noconfirm ranger kitty extra/kitty-shell-integration extra/kitty-terminfo extra/python-pillow

echo "Copying ranger configuration files..."
ranger --copy-config=all
echo "Ranger configuration"

# Проверка существования файла rc.conf
if [[ -f "$rcconf" ]]; then
    # Настройка preview_images
    if grep -q "set preview_images" "$rcconf"; then
        if grep -q "set preview_images true" "$rcconf"; then
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
    if grep -q "set preview_images_method" "$rcconf"; then
        if grep -q "set preview_images_method $metpreview" "$rcconf"; then
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