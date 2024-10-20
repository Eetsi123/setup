#!/usr/bin/python3
# TODO: check if layout already matches
import sys, dbus
from collections import defaultdict
bus = dbus.SessionBus()

dc_well_known = "org.gnome.Mutter.DisplayConfig"
dc_object_path = "/org/gnome/Mutter/DisplayConfig"

dc_proxy = bus.get_object(dc_well_known, dc_object_path)
dc_interface = dbus.Interface(dc_proxy, dbus_interface=dc_well_known)

serial, physical_monitors, _, _ = dc_interface.GetCurrentState()

modes = defaultdict(list)
for monitor_info, monitor_modes, _ in physical_monitors:
    connector, _, _, _ = monitor_info

    for mode_id, mode_w, mode_h, mode_r, _, _, _ in monitor_modes:
        modes[connector].append((mode_w, mode_h, mode_r, mode_id))

def mode(connector, rate):
    best_w = best_h = best_r = 0
    best_id = None

    for mode_w, mode_h, mode_r, mode_id in modes[connector]:
        if mode_w == 4096 and mode_h == 2160:
            continue

        if rate and abs(rate - mode_r) > 2:
            continue

        if mode_w >= best_w and mode_h >= best_h and mode_r >= best_r:
            best_w, best_h, best_r = mode_w, mode_h, mode_r
            best_id = mode_id

    assert best_id is not None, f"failed to find a valid mode for {connector}"
    return best_w, best_h, best_r, best_id


def lay(monitors, primary=None):
    parsed = {}
    for monitor in monitors:
        monitor,   _, scale = monitor.partition("/")
        connector, _, rate  = monitor.partition("@")

        rate  = rate  and float(rate)  or None
        scale = scale and float(scale) or 1.0

        if connector in modes:
            parsed[connector] = rate, scale

    layout   = []
    position = 0

    if primary is None:
        primary = max(parsed, key=lambda c: max(modes[c]), default=None)

    for connector, (rate, scale) in parsed.items():
        mode_w, mode_h, mode_r, mode_id = mode(connector, rate)

        layout.append((position, 0, scale, 0, connector == primary, [(connector, mode_id, {})]))
        position += mode_w

    return layout

layout = lay(sys.argv[1:])

if layout:
    dc_interface.ApplyMonitorsConfig(serial, 1, layout, {})
