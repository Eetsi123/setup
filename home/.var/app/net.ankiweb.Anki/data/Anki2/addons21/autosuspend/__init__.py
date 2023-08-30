from aqt import mw, gui_hooks
from aqt.qt import QAction, qconnect

from .rules import Rules, Rule

rules = Rules([Rule(**r) for r in mw.addonManager.getConfig(__name__)["rules"]])


# NOTE: button
action = QAction("Autosuspend Cards", mw)
qconnect(action.triggered, rules.apply)
mw.form.menuTools.addAction(action)


# NOTE: answer hook
def answer_card(_r, card, _e):
    undo = mw.col.undo_status()

    rules.apply(nid=card.nid)

    assert undo.undo == "Answer Card"
    mw.col.merge_undo_entries(undo.last_step)


gui_hooks.reviewer_did_answer_card.append(answer_card)
