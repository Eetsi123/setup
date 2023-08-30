from aqt import mw
from anki.cards import CardId
from anki.consts import CardQueue, QUEUE_TYPE_SUSPENDED
from anki.notes import NoteId
from aqt.utils import showInfo, showWarning

from dataclasses import dataclass
from functools import cache
from typing import Optional


@cache
def card_ord_dict(note: str) -> dict[str, int]:
    templates = mw.col.models.by_name(note)["tmpls"]
    cords = {t["name"]: t["ord"] for t in templates}

    return cords


@dataclass
class Rule:
    deck: str
    note: str
    first: list[str]
    then: list[str]

    def query_filter(self, cards: list[str]) -> str:
        cords = card_ord_dict(self.note)
        query_cards = " OR ".join(map(lambda card: f"card:{cords[card]}", cards))

        return f'deck:"{self.deck}" note:"{self.note}" ({query_cards})'

    def query_first(self) -> str:
        return self.query_filter(self.first)

    def query_then(self) -> str:
        return self.query_filter(self.then)


@dataclass
class Rules:
    rules: list[Rule]

    def apply(self, nid: Optional[NoteId] = None):
        note = mw.col.get_note(nid).note_type()["name"] if nid else None
        query_filter = f"nid:{nid}" if nid else ""

        to_suspend: set[CardId] = set()
        for rule in self.rules:
            if note and note != rule.note:
                continue

            # NOTE: Find notes that have a `rule.first` card which is new, in learning or suspended by a preceding rule.
            # NOTE: Using `find_cards` instead of `find_notes` is ~10× faster (70ms -> 7ms).
            # TODO: Test if this is fast enough to remove the check above.
            query_suspended = (
                f'OR cid:{",".join(map(str, to_suspend))}'
                if len(to_suspend) != 0
                else ""
            )
            matched_first = mw.col.find_cards(
                f"{query_filter} {rule.query_first()} (is:new OR is:learn {query_suspended})"
            )
            matched_nids = map(
                lambda card: str(mw.col.get_card(card).nid), matched_first
            )

            # NOTE: No cards need to be suspended.
            if len(matched_first) == 0:
                continue

            # NOTE: Suspend all `rule.then` cards of matched notes.
            query_matched = query_filter if nid else f'nid:{",".join(matched_nids)}'
            matched_then = mw.col.find_cards(
                f"{query_matched} {rule.query_then()} -(is:suspended -flag:6)"
            )
            to_suspend |= set(matched_then)

        existing_suspend = set(mw.col.find_cards(f"{query_filter} is:suspended flag:6"))
        new_suspend = to_suspend - existing_suspend
        unsuspend = existing_suspend - to_suspend

        update_cards(new_suspend, unsuspend)


def update_cards(suspend: set[CardId], unsuspend: set[CardId]):
    if not (suspend or unsuspend):
        return

    if not suspend.isdisjoint(unsuspend):
        showWarning(
            f"the following cards were marked for both suspension and unsuspension: {suspend & unsuspend}"
        )
        unsuspend -= suspend

    sc = list(map(mw.col.get_card, suspend))
    uc = list(map(mw.col.get_card, unsuspend))

    for card in sc:
        card.queue = QUEUE_TYPE_SUSPENDED
        card.set_user_flag(6)

    for card in uc:
        card.queue = CardQueue(card.type)
        card.set_user_flag(0)

    mw.col.update_cards(sc + uc)
    showInfo(f"suspended: {len(suspend)}\nunsuspended: {len(unsuspend)}")
