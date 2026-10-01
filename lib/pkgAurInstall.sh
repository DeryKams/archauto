#!/bin/bash

# Модуль установки пакетов из AUR (lib/pkgAurInstall.sh)
# Поддерживает два сценария запуска:
#   1) source из archscript.sh — aur_choice/yay_packages наследуются из основного скрипта;
#   2) прямой запуск (sudo ./lib/pkgAurInstall.sh) — хелпер определяется автоматически:
#      установлен один — берём его; установлены оба — спрашиваем пользователя;
#      не установлен ни один — скрипт завершается с ошибкой.
# Работает от root (нужен для конфигов и служб); сами пакеты ставятся
# от имени обычного пользователя через sudo -u, потому что makepkg и
# AUR-хелперы отказываются работать под root.

# --- Определение источника запуска ---
# $0 — имя запущенного процесса; BASH_SOURCE[0] — файл с выполняющимся кодом.
# При прямом запуске они совпадают; при source из другого скрипта — различаются.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    standalone=1   # внешний запуск как самостоятельный скрипт
else
    standalone=0   # вызван через source из основного скрипта
fi

# Проверка прав суперпользователя 
if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: модуль установки AUR-пакетов должен вызываться из-под root" >&2
    if [[ $standalone -eq 1 ]]; then
        exit 1
    else
        return 1 2>/dev/null
    fi
fi

# Список AUR пакетов
aur_pkgs=(
    nohang-git
    minq-ananicy-git
    stacer-bin
    # xdman8-beta-git
    firefox-extension-xdman8-browser-monitor-bin
    php-codesniffer-phpcsutils
    carbonyl
    php-codesniffer-phpcsextra
    visual-studio-code-bin
)

# Карта конфликтов: пакет -> уже установленные аналоги, с которыми он несовместим.
# Проверка выполняется ДО запуска хелпера: с --noconfirm pacman на вопрос
# «удалить конфликтующий пакет?» отвечает дефолтным N и прерывает ВСЮ транзакцию,
# поэтому конфликтный пакет отсеивается заранее, а остальные ставятся.
declare -A CONFLICTS=(
    ["minq-ananicy-git"]="ananicy-cpp ananicy-cpp-git ananicy"
    ["nohang-git"]="nohang"
    ["xdman8-beta-git"]="xdman xdman9-beta-git"
    ["visual-studio-code-bin"]="code code-oss vscodium vscodium-bin"
)

# --- Автодетект установленного AUR-хелпера (для внешнего запуска) ---
detect_aur_helper() {
    # Печатает имя найденного хелпера или возвращает ошибку.
    # Двойная проверка каждого: pacman -Q — «установлен ли в системе»,
    # command -v — «достижим ли бинарник по PATH» (под sudo PATH подменяется
    # на secure_path из sudoers, и установленное можно не увидеть — это надо отловить).
    local h answer
    local installed=()
    for h in paru yay; do
        if pacman -Q "$h" >/dev/null 2>&1; then
            if command -v "$h" >/dev/null 2>&1; then
                installed+=("$h")
            else
                echo "Предупреждение: $h установлен, но недоступен в PATH (проверь secure_path в sudoers)" >&2
            fi
        fi
    done

    case ${#installed[@]} in
        0)
            return 1
            ;;
        1)
            echo "${installed[0]}"
            return 0
            ;;
        2)
            # установлены оба — спрашиваем пользователя
            read -rp "Найдены оба AUR-хелпера (paru, yay). Каким ставить пакеты? [paru/yay] " answer
            case "$answer" in
                paru) echo "paru"; return 0 ;;
                yay)  echo "yay";  return 0 ;;
                *)    echo "Ошибка: выбор '$answer' не распознан, завершаюсь" >&2; return 1 ;;
            esac
            ;;
    esac
}

# --- Источник переменных aur_choice / yay_packages ---
if [[ $standalone -eq 1 ]]; then
    # Внешний запуск: переменные основного скрипта недоступны,
    # хелпер определяем по факту установки в системе
    if detected="$(detect_aur_helper)"; then
        aur_choice="$detected"
        echo "AUR-хелпер определён автоматически: $aur_choice"
    else
        echo "Ошибка: не найден ни paru, ни yay. Установи AUR-хелпер и повтори" >&2
        exit 1
    fi
    # Внешний запуск сам по себе означает явное намерение ставить пакеты
    yay_packages="yes"
else
    # Sourced-режим: aur_choice/yay_packages пришли из основного скрипта.
    # Если основной скрипт их не задал — трактуем как отказ, не как аварию.
    aur_choice="${aur_choice:-none}"
    yay_packages="${yay_packages:-no}"
fi

# Модуль имеет смысл только при выбранном AUR-хелпере и согласии на установку
if [[ "$aur_choice" != "paru" && "$aur_choice" != "yay" ]] || [[ "$yay_packages" != "yes" ]]; then
    echo "AUR-пакеты пропущены (хелпер не выбран или установка отклонена)"
    if [[ $standalone -eq 1 ]]; then
        exit 0
    else
        return 0 2>/dev/null
    fi
fi

if ! command -v "$aur_choice" >/dev/null 2>&1; then
    echo "Ошибка: AUR-хелпер $aur_choice не найден в PATH" >&2
    if [[ $standalone -eq 1 ]]; then
        exit 1
    else
        return 1 2>/dev/null
    fi
fi

# Пользователь, от имени которого ставим пакеты (makepkg не работает под root)
aur_user="$SUDO_USER"
if [[ -z "$aur_user" ]]; then
    # если скрипт запущен прямиком от root без sudo — берём первого обычного пользователя
    aur_user="$(getent passwd 1000 | cut -d: -f1)"
    echo "SUDO_USER не задан, использую первого обычного пользователя: $aur_user"
fi
if [[ -z "$aur_user" ]]; then
    echo "Ошибка: не найден пользователь для установки AUR-пакетов" >&2
    if [[ $standalone -eq 1 ]]; then
        exit 1
    else
        return 1 2>/dev/null
    fi
fi

echo "Установка AUR-пакетов через $aur_choice (от пользователя $aur_user)"

# TODO Переписать, чтобы ставилось сразу несколько пакетов одной транзакцией, а не по одному. Сейчас сбой одного пакета останавливает весь процесс и каждый раз просится пароль.

install_aur_pkg() {
    # $1 — имя пакета; каждый пакет ставится отдельной транзакцией,
    # чтобы сбой одного не остановил остальные
    sudo -u "$aur_user" "$aur_choice" -S --needed --noconfirm "$1"
}

for pkg in "${aur_pkgs[@]}"; do
    # уже установлен — пропускаем, не дёргая хелпер
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
        echo "  $pkg: уже установлен, пропускаю"
        continue
    fi

    # проверка на установленные аналоги (конфликты)
    skip=0
    for conflict in ${CONFLICTS[$pkg]:-}; do
        if pacman -Qq "$conflict" >/dev/null 2>&1; then
            echo "  $pkg: ПРОПУСК — конфликтует с установленным '$conflict'"
            echo "         (чтобы заменить: sudo pacman -Rns $conflict, затем поставить $pkg)"
            skip=1
        fi
    done
    if [[ $skip -eq 1 ]]; then
        continue
    fi

    echo "  $pkg: устанавливаю..."
    if ! install_aur_pkg "$pkg"; then
        echo "  $pkg: ошибка установки, продолжаю со следующими" >&2
    fi
done

# Чистка кэша сборок, если выбран yay
if [[ "$aur_choice" == "yay" ]]; then
    yay -Yc --noconfirm
fi

# Конфигурация nohang: пакет кладёт пресеты (nohang-desktop.conf, nohang-gaming.conf, ...),
# но читает он именно /etc/nohang/nohang.conf — поэтому применяем десктоп-пресет как основной.
# Всё с проверками: пакет мог не поставиться, пресет может отсутствовать.
if pacman -Qq nohang-git >/dev/null 2>&1; then
    if [[ -f /etc/nohang/nohang-desktop.conf ]]; then
        # бэкап перед перезаписью, если старый конфиг отличается от пресета
        if [[ -f /etc/nohang/nohang.conf ]] && ! cmp -s /etc/nohang/nohang.conf /etc/nohang/nohang-desktop.conf; then
            cp /etc/nohang/nohang.conf "/etc/nohang/nohang.conf.bak.$(date +%Y%m%d%H%M%S)"
            echo "nohang: старый конфиг сохранён как nohang.conf.bak.*"
        fi
        cp /etc/nohang/nohang-desktop.conf /etc/nohang/nohang.conf
        echo "nohang: nohang-desktop.conf применён как основной конфиг"
    else
        echo "nohang: пресет nohang-desktop.conf не найден, конфиг не трогаю" >&2
    fi

    # nohang без запущенной службы ничего не делает — включаем, если юнит есть
    if [[ -f /usr/lib/systemd/system/nohang.service ]]; then
        systemctl enable --now nohang.service
        if systemctl is-active --quiet nohang.service; then
            echo "nohang: служба запущена"
        else
            echo "nohang: служба НЕ запустилась, проверь: systemctl status nohang" >&2
        fi
    fi
else
    echo "nohang не установлен (пропущен или сбой) — конфиг не трогаю"
fi

echo "AUR-пакеты обработаны"