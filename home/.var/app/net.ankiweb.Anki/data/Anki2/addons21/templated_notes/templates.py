from aqt import mw

from dataclasses import dataclass
from itertools import chain
from typing import Iterator


@dataclass
class ExpandedTemplate:
    # NOTE: Patterns have been expanded.
    name: str
    front: str
    back: str


@dataclass
class Template:
    # NOTE: Can contain patterns.
    name: str
    front: str
    back: str
    # NOTE: A card is generated for each list item. The dict keys are replaced with the values.
    patterns: list[dict[str, str]]

    def expand(self) -> Iterator[ExpandedTemplate]:
        def expand_card(patterns: dict[str, str]) -> ExpandedTemplate:
            name = self.name
            front = self.front
            back = self.back

            for p, v in patterns.items():
                name = name.replace(p, v)
                front = front.replace(p, v)
                back = back.replace(p, v)

            return ExpandedTemplate(name, front, back)

        if self.patterns:
            return map(expand_card, self.patterns)
        else:
            return iter([ExpandedTemplate(self.name, self.front, self.back)])


@dataclass
class TemplatedModel:
    name: str
    css: str
    fields: list[str]
    templates: list[Template]

    def apply(self):
        models = mw.col.models

        model = models.by_name(self.name)
        if model is None:
            model = models.new(self.name)

        model["css"] = self.css

        fields = models.field_map(model)

        fields = {f["name"]: f for f in model["flds"]}
        for i, name in enumerate(self.fields):
            if name not in fields:
                f = models.new_field(name)
                models.add_field(model, f)
                fields[name] = f

            models.reposition_field(model, fields[name], i)

        templates = {t["name"]: t for t in model["tmpls"]}
        for i, template in enumerate(
            chain.from_iterable(map(Template.expand, self.templates))
        ):
            if template.name not in templates:
                t = models.new_template(template.name)
                models.add_template(model, t)
                templates[template.name] = t

            t = templates[template.name]
            t["qfmt"] = template.front
            t["afmt"] = template.back
            models.reposition_template(model, t, i)

        # NOTE: is this necessary?
        if models.id_for_name(self.name):
            models.update_dict(model)
        else:
            models.add_dict(model)
