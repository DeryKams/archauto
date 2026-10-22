#!/usr/bin/env python3
"""Battery metrics from Linux power_supply; compact Waybar JSON or --details JSON."""

import json
import sys
from pathlib import Path

POWER_SUPPLY = Path('/sys/class/power_supply')


def _read(path, name):
    """Read a sysfs field; return None when unavailable."""
    try:
        return (path / name).read_text(encoding='utf-8').strip()
    except (OSError, UnicodeError):
        return None


def _number(path, name):
    """Read an optional numeric sysfs field."""
    value = _read(path, name)
    try:
        return float(value) if value is not None else None
    except ValueError:
        return None


def _energy(battery):
    """Return remaining/full energy in Wh, or (None, None)."""
    now = _number(battery, 'energy_now')
    full = _number(battery, 'energy_full')
    if now is not None and full is not None and full > 0:
        return max(0, now) / 1_000_000, full / 1_000_000

    # Some batteries expose charge (µAh) instead of energy (µWh).
    charge_now = _number(battery, 'charge_now')
    charge_full = _number(battery, 'charge_full')
    voltage = _number(battery, 'voltage_now') or _number(battery, 'voltage_min_design')
    if charge_now is not None and charge_full is not None and charge_full > 0 and voltage:
        return max(0, charge_now) * voltage / 1_000_000_000_000, charge_full * voltage / 1_000_000_000_000
    return None, None


def _rate(battery):
    """Read battery-side power in watts, not system wall power."""
    rate = _number(battery, 'power_now')
    if rate is not None:
        return abs(rate) / 1_000_000
    current = _number(battery, 'current_now')
    voltage = _number(battery, 'voltage_now')
    if current is not None and voltage is not None:
        return abs(current * voltage) / 1_000_000_000_000
    return None


def read_battery():
    """Aggregate system batteries; omit incomplete energy/power totals."""
    try:
        candidates = sorted(POWER_SUPPLY.iterdir())
    except OSError:
        candidates = []

    batteries = []
    for path in candidates:
        if _read(path, 'type') != 'Battery':
            continue
        if _read(path, 'scope') == 'Device' or _read(path, 'present') == '0':
            continue
        now, full = _energy(path)
        batteries.append({
            'name': path.name,
            'status': (_read(path, 'status') or 'Unknown').lower(),
            'percent': _number(path, 'capacity'),
            'energy_now': now,
            'energy_full': full,
            'rate': _rate(path),
        })

    if not batteries:
        return {'present': False, 'percent': None, 'status': 'missing',
                'energy_now': None, 'energy_full': None, 'rate': None,
                'minutes': None, 'batteries': 0}

    complete_energy = all(b['energy_now'] is not None and b['energy_full'] is not None for b in batteries)
    if complete_energy:
        now = sum(b['energy_now'] for b in batteries)
        full = sum(b['energy_full'] for b in batteries)
        percent = round(min(100, max(0, 100 * now / full))) if full > 0 else None
    else:
        now = full = None
        percentages = [b['percent'] for b in batteries]
        percent = round(sum(percentages) / len(percentages)) if all(p is not None for p in percentages) else None

    statuses = {b['status'] for b in batteries}
    if 'charging' in statuses and 'discharging' in statuses:
        status = 'mixed'
    elif 'discharging' in statuses:
        status = 'discharging'
    elif 'charging' in statuses:
        status = 'charging'
    elif statuses == {'full'}:
        status = 'full'
    elif 'not charging' in statuses:
        status = 'idle'
    else:
        status = 'unknown'

    changing = [b for b in batteries if b['status'] in ('charging', 'discharging')]
    if changing and status in ('charging', 'discharging') and all(b['rate'] is not None for b in changing):
        rate = sum(b['rate'] for b in changing)
    else:
        rate = None

    minutes = None
    if rate is not None and rate > 0.01 and complete_energy:
        if status == 'discharging':
            minutes = round(60 * now / rate)
        elif status == 'charging':
            minutes = round(60 * max(0.0, full - now) / rate)

    return {'present': True, 'percent': percent, 'status': status,
            'energy_now': now, 'energy_full': full, 'rate': rate,
            'minutes': minutes, 'batteries': len(batteries)}


def waybar_payload(info):
    """Build documented Waybar custom-module JSON fields."""
    percent = info['percent']
    if not info['present']:
        return {'text': '—', 'tooltip': 'Аккумулятор не обнаружен',
                'class': ['no-battery'], 'percentage': 0}
    value = f'{percent}%' if percent is not None else '—'
    status_names = {'charging': 'Заряжается', 'discharging': 'Разряжается',
                    'full': 'Полный заряд', 'idle': 'Не заряжается',
                    'mixed': 'Смешанный режим', 'unknown': 'Состояние неизвестно'}
    tooltip = f'{status_names.get(info["status"], "Батарея")} · {value}'
    if info['rate'] is not None:
        tooltip += f'\nМощность батареи: {info["rate"]:.1f} Вт'
    classes = [info['status']]
    if percent is not None:
        classes.append(f'charge-{max(0, min(100, percent))}')
        if percent <= 20:
            classes.append('low')
    return {'text': value, 'tooltip': tooltip, 'class': classes,
            'percentage': percent if percent is not None else 0}


if __name__ == '__main__':
    info = read_battery()
    print(json.dumps(info if '--details' in sys.argv[1:] else waybar_payload(info),
                     ensure_ascii=False, separators=(',', ':')))
