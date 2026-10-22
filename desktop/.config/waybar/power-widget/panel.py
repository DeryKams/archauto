#!/usr/bin/env python3
"""Compact GTK3 layer-shell popup for battery stats and power-profiles-daemon."""

import importlib.util
import os
import socket
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gdk, GLib, Gtk, GtkLayerShell

CONFIG_DIR = Path(__file__).resolve().parent
BATTERY_SOURCE = CONFIG_DIR.parent / 'waybar' / 'scripts' / 'battery-status.py'
PROFILE_NAMES = {
    'power-saver': 'Экономия',
    'balanced': 'Баланс',
    'performance': 'Максимум',
}
RUNTIME = Path(os.environ.get('XDG_RUNTIME_DIR') or f'/run/user/{os.getuid()}')
SOCKET = RUNTIME / 'archauto-power-widget.sock'


def load_battery_module():
    """Reuse the same battery measurement logic as Waybar."""
    spec = importlib.util.spec_from_file_location('battery_status', BATTERY_SOURCE)
    if spec is None or spec.loader is None:
        raise RuntimeError('Не найден battery-status.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def powerctl(*args):
    """Run supported powerprofilesctl commands with a timeout."""
    try:
        result = subprocess.run(['powerprofilesctl', *args], text=True,
                                capture_output=True, timeout=4, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return None, 'powerprofilesctl недоступен'
    if result.returncode != 0:
        return None, (result.stderr.strip() or 'Ошибка управления профилями')[:180]
    return result.stdout.strip(), None


def profiles_available():
    """Extract profile IDs from powerprofilesctl list output."""
    output, error = powerctl('list')
    if error:
        return set(), error
    import re
    return set(re.findall(r'^\s*\*?\s*(power-saver|balanced|performance):', output,
                          flags=re.MULTILINE)), None


def label(text, css_class=None):
    """Create a themed GTK label."""
    widget = Gtk.Label(label=text)
    widget.set_xalign(0)
    if css_class:
        widget.get_style_context().add_class(css_class)
    return widget


def format_minutes(minutes):
    """Show a compact estimated time or missing-data marker."""
    if minutes is None:
        return 'Нет данных'
    return f'{minutes // 60} ч {minutes % 60:02d} мин' if minutes >= 60 else f'{minutes} мин'


class PowerPanel:
    """Single floating power panel anchored below Waybar."""

    def __init__(self, battery_module):
        self.battery = battery_module
        self.available = set()
        self.buttons = {}
        self.checks = {}
        self.window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
        self.window.set_title('Питание')
        self.window.set_decorated(False)
        self.window.set_resizable(False)
        self.window.set_default_size(280, -1)
        self.window.set_app_paintable(True)
        # Request a real alpha-capable surface for the translucent GTK window.
        visual = self.window.get_screen().get_rgba_visual()
        if visual is not None:
            self.window.set_visual(visual)
        self.window.get_style_context().add_class('power-panel')
        self.window.connect('destroy', Gtk.main_quit)
        self.window.connect('key-press-event', self.on_key)
        self.window.connect('focus-out-event', self.on_focus_out)

        # Layer shell positions the panel under the right side of Waybar.
        GtkLayerShell.init_for_window(self.window)
        GtkLayerShell.set_layer(self.window, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.TOP, 38)
        GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.RIGHT, 10)
        GtkLayerShell.set_exclusive_zone(self.window, 0)
        GtkLayerShell.set_keyboard_mode(self.window, GtkLayerShell.KeyboardMode.ON_DEMAND)

        provider = Gtk.CssProvider()
        provider.load_from_path(str(CONFIG_DIR / 'style.css'))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=9)
        card.set_name('power-card')
        # Leave room so the border and soft box shadow are not clipped.
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        outer.set_margin_top(9)
        outer.set_margin_bottom(9)
        outer.set_margin_start(9)
        outer.set_margin_end(9)
        outer.add(card)
        self.window.add(outer)

        heading = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        heading.pack_start(label('Питание', 'power-heading'), True, True, 0)
        self.percent = label('—', 'power-percentage')
        self.percent.set_xalign(1)
        heading.pack_end(self.percent, False, False, 0)
        card.pack_start(heading, False, False, 0)

        card.pack_start(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL), False, False, 0)
        card.pack_start(label('Профиль энергопотребления', 'power-muted'), False, False, 0)

        for profile, title in PROFILE_NAMES.items():
            button = Gtk.Button()
            button.get_style_context().add_class('profile-row')
            content = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            content.pack_start(label(title), True, True, 0)
            check = label('', 'power-check')
            check.set_xalign(1)
            content.pack_end(check, False, False, 0)
            button.add(content)
            button.connect('clicked', self.change_profile, profile)
            card.pack_start(button, False, False, 0)
            self.buttons[profile] = button
            self.checks[profile] = check

        self.error = label('', 'power-error')
        self.error.set_line_wrap(True)
        self.error.set_no_show_all(True)
        card.pack_start(self.error, False, False, 0)
        card.pack_start(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL), False, False, 0)

        self.rate = self.metric_row(card, 'Мощность батареи')
        card.pack_start(label('Ёмкость · осталось / всего', 'power-muted'), False, False, 0)
        self.capacity = label('Нет данных', 'power-value')
        card.pack_start(self.capacity, False, False, 0)
        self.time = self.metric_row(card, 'Время')

        self.refresh()
        GLib.timeout_add_seconds(3, self.refresh)

    @staticmethod
    def metric_row(parent, title):
        """Add a compact label-value row."""
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        row.pack_start(label(title, 'power-muted'), True, True, 0)
        value = label('—', 'power-value')
        value.set_xalign(1)
        row.pack_end(value, False, False, 0)
        parent.pack_start(row, False, False, 0)
        return value

    def refresh(self):
        """Refresh battery measurements and selected/available power profiles."""
        stats = self.battery.read_battery()
        self.percent.set_text(f'{stats["percent"]}%' if stats['percent'] is not None else '—')
        if not stats['present']:
            self.rate.set_text('Нет батареи')
            self.capacity.set_text('Нет данных')
            self.time.set_text('Нет данных')
        else:
            state = stats['status']
            title = ('Заряд батареи' if state == 'charging' else
                     'Разряд батареи' if state == 'discharging' else 'Мощность батареи')
            # Update metric label when charging/discharging changes.
            row_label = self.rate.get_parent().get_children()[0]
            row_label.set_text(title)
            self.rate.set_text(f'{stats["rate"]:.1f} Вт' if stats['rate'] is not None else 'Нет данных')
            if stats['energy_now'] is not None and stats['energy_full'] is not None:
                self.capacity.set_text(f'{stats["energy_now"]:.1f} / {stats["energy_full"]:.1f} Вт·ч')
            else:
                self.capacity.set_text('Нет данных')
            self.time.set_text(format_minutes(stats['minutes']))

        available, error = profiles_available()
        current, get_error = powerctl('get')
        self.available = available
        for profile, button in self.buttons.items():
            button.set_sensitive(profile in available)
            ctx = button.get_style_context()
            if current == profile:
                ctx.add_class('active')
                self.checks[profile].set_text('✓')
            else:
                ctx.remove_class('active')
                self.checks[profile].set_text('')
        if error or get_error:
            self.show_error(error or get_error)
        elif self.error.get_text().startswith('powerprofilesctl'):
            self.show_error(None)
        return True

    def show_error(self, message):
        """Show errors without crashing the popup."""
        if message:
            self.error.set_text(message)
            self.error.show()
        else:
            self.error.hide()
            self.error.set_text('')

    def change_profile(self, _button, profile):
        """Apply only a profile actually offered by the daemon."""
        if profile not in self.available:
            return
        _, error = powerctl('set', profile)
        self.show_error(error)
        self.refresh()

    def on_key(self, _window, event):
        """Close with Escape."""
        if event.keyval == Gdk.KEY_Escape:
            self.window.destroy()
            return True
        return False

    def on_focus_out(self, *_args):
        """Dismiss the popup when focus moves elsewhere."""
        self.window.destroy()
        return False


def run_once():
    """Toggle an existing popup or start the only GTK instance."""
    if not RUNTIME.is_dir():
        raise RuntimeError(f'Нет каталога XDG_RUNTIME_DIR: {RUNTIME}')
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        client.connect(str(SOCKET))
        client.sendall(b'toggle\n')
        return
    except (ConnectionRefusedError, FileNotFoundError):
        # A previous crash can leave a stale socket name.
        try:
            SOCKET.unlink()
        except FileNotFoundError:
            pass
    finally:
        client.close()

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        server.bind(str(SOCKET))
        os.chmod(SOCKET, 0o600)
        server.listen(3)
        server.setblocking(False)

        def on_socket(_source, _condition):
            try:
                connection, _ = server.accept()
                with connection:
                    connection.recv(64)
                GLib.idle_add(Gtk.main_quit)
            except BlockingIOError:
                pass
            return True

        GLib.io_add_watch(server.fileno(), GLib.IO_IN, on_socket)
        panel = PowerPanel(load_battery_module())
        panel.window.show_all()
        panel.error.hide()
        Gtk.main()
    finally:
        server.close()
        try:
            SOCKET.unlink()
        except FileNotFoundError:
            pass


if __name__ == '__main__':
    try:
        run_once()
    except Exception as exc:
        print(f'power-widget: {exc}', file=sys.stderr)
        sys.exit(1)
