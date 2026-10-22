#!/usr/bin/env bash

# Shared Waybar/Niri entry point for the existing Walker clipboard provider.
report() {
    printf 'clipboard-history: %s\n' "$1" >&2
    if command -v notify-send >/dev/null 2>&1; then
        notify-send 'История буфера' "$1" >/dev/null 2>&1 || :
    fi
}

if ! command -v walker >/dev/null 2>&1; then
    report 'Walker не установлен; история буфера недоступна'
    exit 127
fi

# A bounded probe avoids opening an empty history when the user backend is down.
if command -v systemctl >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
    if ! timeout 2 systemctl --user is-active --quiet elephant.service >/dev/null 2>&1; then
        report 'Elephant не работает в пользовательской сессии'
        exit 1
    fi
fi

walker --provider clipboard
status=$?
if (( status != 0 )); then
    report "Walker не открыл историю (код $status); проверьте elephant listproviders"
fi
exit "$status"
