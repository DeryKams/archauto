#!/usr/bin/env bash

# One JSON line per selection event; Waybar keeps this process running.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == "--from-stdin" ]]; then
    exec python3 "$script_dir/clipboard-preview.py"
fi

# Only the watcher may supply a per-event MIME on versions that support it.
unset CLIPBOARD_TYPE
wl-paste --watch "$BASH" "${BASH_SOURCE[0]}" --from-stdin
status=$?
printf '%s\n' '{"text":"Буфер: ошибка","tooltip":"Наблюдение за буфером остановлено","class":"error"}'
printf 'clipboard-preview: wl-paste --watch exited with status %s\n' "$status" >&2
exit 1
