#!/usr/bin/python3
from aqt import mw, gui_hooks
from aqt.qt import QAction, qconnect

from typing import Iterator

from importlib.machinery import SourceFileLoader

tomllib = SourceFileLoader(
    "tomli",
    mw.addonManager.addonsFolder("templated_notes") + "/tomli/src/tomli/__init__.py",
).load_module()

from .templates import TemplatedModel, Template


def parse_config(toml) -> Iterator[TemplatedModel]:
    global_css = toml.get("css", "")
    global_js = toml.get("js", "")

    def parse_template(toml_t) -> Template:
        toml_t["front"] += "\n<script>\n" + global_js + "</script>\n"
        toml_t["back"] += "\n<script>\n" + global_js + "</script>\n"

        if not "patterns" in toml_t:
            toml_t["patterns"] = []

        return Template(**toml_t)

    def parse_model(toml_m) -> TemplatedModel:
        name = toml_m["name"]
        css = global_css + toml_m.get("css", "")
        fields = toml_m["fields"]
        templates = map(parse_template, toml_m["templates"])

        return TemplatedModel(name, css, fields, list(templates))

    return map(parse_model, toml["models"])

def apply_templates():
    with open(
        mw.addonManager.addonsFolder("templated_notes") + "/config.toml", "rb"
    ) as file:
        toml = tomllib.load(file)
    
    for template in parse_config(toml):
        template.apply()

# NOTE: apply on startup
gui_hooks.main_window_did_init.append(apply_templates)

# NOTE: button
action = QAction("Apply Note Models")
qconnect(action.triggered, apply_templates)
mw.form.menuTools.addAction(action)
