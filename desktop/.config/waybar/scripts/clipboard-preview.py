#!/usr/bin/env python3
"""Bounded, one-event clipboard preview for Waybar; never stores the selection."""

import json
import os
import subprocess
import sys
from pathlib import PurePosixPath
from urllib.parse import unquote, urlsplit

PREFIX = 64 * 1024
PANEL = 8
TOOLTIP = 256


def emit(kind, label, detail=None):
    value = label if detail is None else detail
    value = value.replace("\x00", "�")
    tooltip = "\n".join(value.splitlines()[:5])[:TOOLTIP]
    flat = " ".join(value.split()) if value.strip() else value
    panel_value = {"empty": "Пусто", "error": "Ошибка"}.get(kind, flat)
    if label == "Пустой текст":
        panel_value = "Текст ∅"
    text = panel_value[:PANEL] + ("…" if len(panel_value) > PANEL else "")
    print(json.dumps({"text": text, "tooltip": tooltip, "class": kind}, ensure_ascii=False), flush=True)


def read_prefix():
    # Hold at most 64 KiB; consume the remainder so the source can finish.
    stream = sys.stdin.buffer
    data = stream.read(PREFIX + 1)
    truncated = len(data) > PREFIX
    data = data[:PREFIX]
    while stream.read(64 * 1024):
        truncated = True
    return data, truncated


def mime_types():
    # On wl-clipboard 2.3.0 this queries the CURRENT offer, not the watch event.
    try:
        result = subprocess.run(["wl-paste", "--list-types"], capture_output=True, timeout=2, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise RuntimeError("MIME query failed") from exc
    if result.returncode:
        raise RuntimeError("MIME query failed")
    return [line.strip().lower() for line in result.stdout.decode("utf-8", "replace").splitlines()]


def file_label(value, truncated):
    lines = value.splitlines()
    if lines and lines[0] in ("copy", "cut"):
        lines = lines[1:]
    uris = [line for line in lines if line and not line.startswith("#")]
    if not uris or any(not line.startswith("file://") for line in uris):
        return None
    first = urlsplit(uris[0])
    if first.netloc not in ("", "localhost"):
        return None
    name = PurePosixPath(unquote(first.path)).name
    if not name:
        return None
    count = f"{len(uris)} файла: " if len(uris) > 1 and not truncated else "Файл: "
    return count + name + ("…" if truncated else "")


def preview(data, truncated, types):
    # Recognizable bytes take precedence over MIME metadata from a later offer.
    if data.startswith((b"\x89PNG\r\n\x1a\n", b"\xff\xd8\xff", b"GIF87a", b"GIF89a")):
        return "image", "Изображение", None
    if data.startswith(b"%PDF-"):
        return "pdf", "PDF", None
    plain = next((t for t in types if t.startswith("text/plain")), None)
    plain = plain or next((t for t in types if t in ("utf8_string", "string", "text")), None)
    files = any(t in ("text/uri-list", "x-special/gnome-copied-files") for t in types)
    media = next((t for t in types if t.startswith(("image/", "audio/", "video/"))), None)
    other = next((t for t in types if "/" in t and not t.startswith("application/x-gtk-")), None)
    if b"\x00" in data:
        if media:
            kind = media.split("/")[0]
            return kind, {"image": "Изображение", "audio": "Аудио", "video": "Видео"}[kind], None
        return "other", "Данные", other
    try:
        decoded = data.decode("utf-8")
        invalid = False
    except UnicodeDecodeError as exc:
        # A bounded prefix may end in the middle of an otherwise valid character.
        if truncated and exc.reason == "unexpected end of data" and exc.end == len(data):
            decoded = data[:exc.start].decode("utf-8", "replace")
            invalid = "�" in decoded
        else:
            decoded = ""
            invalid = True
    if files and not invalid:
        label = file_label(decoded, truncated)
        if label:
            return "files", label, label
    if data.lstrip().lower().startswith((b"<!doctype html", b"<html", b"<p", b"<div")) and not plain:
        return "html", "HTML", None
    if plain and not invalid:
        if not data:
            return "text", "Пустой текст", None
        if not decoded.strip():
            return "text", "Пробелы", None
        return "text", decoded, decoded + ("…" if truncated else "")
    if media and (not decoded.strip() or media == "image/svg+xml" or invalid):
        kind = media.split("/")[0]
        return kind, {"image": "Изображение", "audio": "Аудио", "video": "Видео"}[kind], None
    if "application/pdf" in types:
        return "pdf", "PDF", None
    if "text/html" in types:
        return "html", "HTML", None
    if other in ("application/json", "application/xml") and not invalid and decoded.strip():
        return "text", decoded, decoded
    return "other", "Данные", other if not invalid else None


def main():
    state = os.environ.get("CLIPBOARD_STATE")
    if state in ("nil", "clear"):
        emit("empty", "Буфер пуст")
        return
    try:
        data, truncated = read_prefix()
        # Newer wl-paste passes the MIME selected for this very stdin stream.
        event_type = os.environ.get("CLIPBOARD_TYPE")
        types = [event_type.lower()] if event_type else mime_types()
        kind, label, detail = preview(data, truncated, types)
        emit(kind, label, detail)
    except (OSError, RuntimeError) as exc:
        print(f"clipboard-preview: {type(exc).__name__}", file=sys.stderr)
        emit("error", "Буфер: ошибка", "Не удалось определить содержимое буфера")


if __name__ == "__main__":
    main()
