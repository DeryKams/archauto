#!/usr/bin/env python3
"""Offline clipboard tests: fake wl-paste only, never touch the real selection."""

import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
HANDLER = ROOT / "desktop/.config/waybar/scripts/clipboard-preview.py"
HISTORY = ROOT / "desktop/.config/waybar/scripts/clipboard-history.sh"


def check(condition, message):
    if not condition:
        raise AssertionError(message)


with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    mock = tmp / "wl-paste"
    mock.write_text("#!/bin/sh\nif [ \"$1\" = --watch ]; then\n  shift\n  if [ \"${MOCK_SEQUENCE:-0}\" = 1 ]; then\n    printf one | CLIPBOARD_STATE=data MOCK_TYPES='text/plain' \"$@\"\n    printf '\\211PNG\\r\\n\\032\\n' | CLIPBOARD_STATE=data MOCK_TYPES='text/plain' \"$@\"\n    printf two | CLIPBOARD_STATE=data MOCK_TYPES='text/plain' \"$@\"\n  else\n    printf event | CLIPBOARD_STATE=data MOCK_TYPES='text/plain' \"$@\"\n  fi\n  exit $?\nfi\n[ \"$1\" = --list-types ] || exit 9\n[ \"${MOCK_FAIL:-0}\" = 1 ] && exit 1\nprintf '%s' \"${MOCK_TYPES:-}\"\n")
    mock.chmod(0o755)
    env = {**os.environ, "PATH": f"{tmp}:/usr/bin:/bin"}

    def run(data=b"", types="", state="data", fail=False, event_type=""):
        local = {**env, "MOCK_TYPES": types, "MOCK_FAIL": "1" if fail else "0", "CLIPBOARD_STATE": state}
        if event_type:
            local["CLIPBOARD_TYPE"] = event_type
        else:
            local.pop("CLIPBOARD_TYPE", None)
        result = subprocess.run(["python3", "-B", str(HANDLER)], input=data, capture_output=True, env=local, timeout=10)
        check(result.returncode == 0, f"handler exit {result.returncode}")
        check(result.stdout.count(b"\n") == 1, "not exactly one JSON line")
        return json.loads(result.stdout)

    for state in ("nil", "clear"):
        check(run(state=state)["class"] == "empty", state)
    watched = subprocess.run(["bash", str(ROOT / "desktop/.config/waybar/scripts/clipboard-preview.sh")], capture_output=True, env=env, timeout=10)
    watch_lines = watched.stdout.splitlines()
    check(json.loads(watch_lines[0])["class"] == "text" and len(watch_lines) == 2, "first watch event")
    sequence = subprocess.run(["bash", str(ROOT / "desktop/.config/waybar/scripts/clipboard-preview.sh")], capture_output=True, env={**env, "MOCK_SEQUENCE": "1"}, timeout=10)
    check([json.loads(line)["class"] for line in sequence.stdout.splitlines()[:3]] == ["text", "image", "text"], "rapid events")
    check(run(b"", "text/plain\n")["tooltip"] == "Пустой текст", "zero-sized text")
    check(run(b" \t\n", "text/plain\n")["text"] == "Пробелы", "whitespace")
    for value in ("Hello", "Привет", "中文", "😀", "<&>", "עברית"):
        check(run(value.encode(), "text/plain\n")["class"] == "text", value)
    check(run(b"hello", "text/html\ntext/plain\n")["text"] == "hello", "plain before HTML")
    check(run(b"<html>body</html>", "text/html\n")["class"] == "html", "raw HTML")
    check(run(b"file:///tmp/a%20b\nfile:///tmp/c\n", "text/uri-list\n")["class"] == "files", "file URI")
    check("2 файла" in run(b"file:///tmp/a\nfile:///tmp/b\n", "text/uri-list\n")["tooltip"], "exact count")
    check("2 файла" not in run((b"file:///tmp/a\n" * 12000), "text/uri-list\n")["tooltip"], "prefix count")
    for data, kind in ((b"\x89PNG\r\n\x1a\n", "image"), (b"%PDF-1.7", "pdf")):
        check(run(data, "text/plain\n")["class"] == kind, "signature before stale MIME")
    for mime, kind in (("audio/ogg", "audio"), ("video/mp4", "video"), ("image/webp", "image")):
        check(run(b"\x00\xff", mime + "\n")["class"] == kind, mime)
    check(run(b"\x00\xff", "application/octet-stream\n")["class"] == "other", "unknown binary")
    check(run(b"hello", "text/plain\n", fail=True)["class"] == "error", "MIME failure")
    check(run(b"hello", "")["class"] == "other", "no CLIPBOARD_TYPE")
    check(run(b"hello", "", fail=True, event_type="text/plain")["class"] == "text", "event MIME")
    check(run(b"hello", "image/png\n")["class"] == "other", "stale MIME fallback")
    check(run(b"a" * (2 * 1024 * 1024), "text/plain\n")["class"] == "text", "large pipe")
    check(run(b"a" * 65535 + "😀".encode() + b"tail", "text/plain\n")["class"] == "text", "cut UTF-8")
    check(run(b"a\xffb", "text/plain\n")["class"] == "other", "invalid UTF-8")
    check(run(b"a\x00b", "text/plain\n")["class"] == "other", "NUL")
    check(len(run(("абв\n" * 300).encode(), "text/plain\n")["tooltip"]) <= 256, "tooltip length")
    check(run(("абв\n" * 300).encode(), "text/plain\n")["tooltip"].count("\n") <= 4, "tooltip lines")

    # The common launcher must report missing Walker and a failed launch.
    missing = subprocess.run(["bash", str(HISTORY)], capture_output=True, env=env)
    check(missing.returncode == 127 and b"Walker" in missing.stderr, "missing Walker")
    walker = tmp / "walker"
    walker.write_text("#!/bin/sh\n[ \"$1 $2\" = '--provider clipboard' ] || exit 8\nexit 7\n")
    walker.chmod(0o755)
    systemctl = tmp / "systemctl"
    systemctl.write_text("#!/bin/sh\n[ \"${MOCK_BACKEND:-up}\" = up ]\n")
    systemctl.chmod(0o755)
    timeout = tmp / "timeout"
    timeout.write_text("#!/bin/sh\nshift\nexec \"$@\"\n")
    timeout.chmod(0o755)
    backend = subprocess.run(["bash", str(HISTORY)], capture_output=True, env={**env, "MOCK_BACKEND": "down"})
    check(backend.returncode == 1 and b"Elephant" in backend.stderr, "Elephant failure")
    failed = subprocess.run(["bash", str(HISTORY)], capture_output=True, env=env)
    check(failed.returncode == 7 and b"Walker" in failed.stderr, "Walker failure")

print("clipboard mocks: OK")
