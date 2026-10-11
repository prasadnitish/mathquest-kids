#!/usr/bin/env python3
"""
Deterministic verifier for the Math Quest Kids question bank.

Every check is exact arithmetic (int / fractions.Fraction / decimal.Decimal),
exact string or structure comparison, or a lookup in a small closed reference
table that is printed in this file. There is no sampling, no randomness and
no model-based judgement, so two runs over the same inputs produce
byte-identical output.

Per item in MathQuestKids/Content/content-pack-v1.json it checks:
  STRUCT    required fields, unique id, known unit, sane difficulty
  MATH      the graded `answer` recomputed independently from the payload
            (the data that draws the visual and drives hints)
  PROMPT    numbers/words in `prompt` agree with the payload
  SPOKEN    numbers/operators in `spokenForm` agree with the prompt
  CHOICES   static choice lists contain the answer once, no duplicates, and
            exactly ONE choice is correct when evaluated independently
  RUNTIME   the app's option generator always offers the answer exactly once
  UI        the Swift views actually display the data the answer depends on
            (scanned from the source, not assumed)
  AUDIO     a clip exists, and the text it was generated from equals the
            current spokenForm where a generation record exists

Severity
  ERROR    child can be marked wrong for a right answer, a question has zero
           or several right answers, prompt/payload/answer disagree, or the
           screen cannot show what the child needs / gives the answer away
  WARNING  answer is right but wording, UX, or audio text is defective, or the
           item cannot be fully verified from the data it carries

Usage
  python3 -I scripts/verify_question_bank.py                 # summary
  python3 -I scripts/verify_question_bank.py --out docs/qa   # + CSV/JSON/MD
Exit status 1 if any ERROR.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter, defaultdict
from decimal import Decimal
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACK = ROOT / "MathQuestKids/Content/content-pack-v1.json"
SPATIAL_BANK = ROOT / "MathQuestKids/Content/spatial-question-bank-v2.json"
AUDIO_DIR = ROOT / "MathQuestKids/Audio"
AUDIO_INDEX = AUDIO_DIR / "audio_index.json"
FUTURE_INDEX = AUDIO_DIR / "future/audio_recording_set_2026_04_26_index.json"
FUTURE_SET = AUDIO_DIR / "future/audio_recording_set_2026_04_26.json"
AUDIO_MANIFEST = ROOT / "scripts/audio_manifest.json"
UI_FILES = [ROOT / "MathQuestKids/Features/Session/SessionInteractionViews.swift",
            ROOT / "MathQuestKids/Features/Session/SessionView.swift"]

SPATIAL_FORMATS = ("shapeHunt", "positionWords", "rotateToMatch", "buildShape",
                   "symmetryMirror", "gridPath", "solidAttributes", "netPreview")

# --------------------------------------------------------------------------
# Closed reference tables (the only external knowledge used)
# --------------------------------------------------------------------------

# sides, corners for the shapes the app can offer as answers
SHAPE_FACTS = {"Triangle": (3, 3), "Square": (4, 4), "Rectangle": (4, 4), "Circle": (0, 0),
               "Pentagon": (5, 5), "Hexagon": (6, 6), "Rhombus": (4, 4), "Trapezoid": (4, 4)}

# order of rotational symmetry as a turn angle: the shape looks identical after
# turning by a multiple of this many degrees (360 = no rotational symmetry)
ROT_SYMMETRY = {"triangle": 360, "rectangle": 180, "diamond": 180, "pentagon": 72,
                "trapezoid": 360, "arrow": 360, "L shape": 360, "T shape": 360}
# shapes that have a mirror line, so a mirrored copy equals some rotation of it
# (the app draws triangle as a right triangle and trapezoid as a right trapezoid, both chiral)
MIRROR_SYMMETRIC = {"rectangle", "diamond", "pentagon", "T shape", "arrow"}

# Which of the four choices on a solidAttributes item can the clue truthfully describe?
CLUE_TRUE_FOR = {
    "6 equal square faces": {"cube"}, "looks like a dice": {"cube"}, "only square faces": {"cube"},
    "6 flat faces that are not all squares": {"rectangular prism"},
    "a box shape with longer rectangle faces": {"rectangular prism"},
    "rectangle faces like a cereal box": {"rectangular prism"},
    "can roll in every direction": {"sphere"}, "no flat faces": {"sphere"}, "round all over": {"sphere"},
    "2 circle faces": {"cylinder"}, "looks like a can": {"cylinder"},
    "one curved side and 2 flat circles": {"cylinder"},
    "1 flat circle and 1 curved side": {"cone"}, "1 point and 1 circle face": {"cone"},
    "looks like a party hat": {"cone"},
    "1 top point above a square base": {"pyramid"}, "triangular faces and 1 square base": {"pyramid"},
    "looks like an Egyptian pyramid": {"pyramid"},
}
# faces, edges, vertices (flat-face convention used consistently by the app's clues)
SOLID_FEV = {"cube": (6, 12, 8), "rectangular prism": (6, 12, 8), "pyramid": (5, 8, 5),
             "cylinder": (2, 2, 0), "cone": (1, 1, 1), "sphere": (0, 0, 0)}

# Can this piece-set assemble the target? (hand-reviewed; finite set found in the data)
CAN_BUILD = {
    ("diamond", "two equal triangles"): True, ("diamond", "two circles"): False,
    ("diamond", "one rectangle"): False, ("diamond", "three squares"): False,
    ("hexagon", "six triangles"): True, ("hexagon", "two squares"): False,
    ("hexagon", "three circles"): False, ("hexagon", "one rectangle"): False,
    ("larger triangle", "four small triangles"): True, ("larger triangle", "two rectangles"): False,
    ("larger triangle", "three circles"): False, ("larger triangle", "one square and one circle"): False,
    ("rectangle", "two squares"): True, ("rectangle", "two pentagons"): False,
    # two (right) triangles placed hypotenuse-to-hypotenuse make a rectangle
    ("rectangle", "two triangles"): True,
    ("rectangle", "two circles"): False, ("rectangle", "one triangle and one circle"): False,
    ("square", "two equal right triangles"): True, ("square", "two circles"): False,
    ("square", "one rectangle and one circle"): False, ("square", "three pentagons"): False,
    ("trapezoid", "one triangle and one rectangle"): True, ("trapezoid", "two circles"): False,
    ("trapezoid", "one hexagon"): False, ("trapezoid", "four squares"): False,
}

# Does a net with this descriptor fold into a cube? (the descriptor text decides it)
#   cross = 1-4-1 with side squares in line  -> always folds
#   T net = four in a row, one above and one below (any columns, 1-4-1 family) -> always folds
#   zigzag net described as "can fold" -> folds
NET_FOLDS = {"cross net": True, "T net": True, "zigzag net": True,
             "strip net": False, "missing-face net": False, "overlap net": False}

NUM_RE = re.compile(r"\d[\d,]*(?:\.\d+)?")


def nums(text: str) -> list[str]:
    return [t.replace(",", "") for t in NUM_RE.findall(text)]


def frac_tokens(text: str):
    return [(int(a), int(b)) for a, b in re.findall(r"(\d+)/(\d+)", text)]


def cmp_symbol(a, b) -> str:
    return "<" if a < b else (">" if a > b else "=")


class Result:
    def __init__(self, item):
        self.item = item
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.checks = Counter()

    def ok(self, name):
        self.checks[name] += 1

    def err(self, name, msg):
        self.checks[name] += 1
        self.errors.append(f"{name}: {msg}")

    def warn(self, name, msg):
        self.checks[name] += 1
        self.warnings.append(f"{name}: {msg}")

    def expect(self, name, cond, msg):
        self.ok(name) if cond else self.err(name, msg)

    @property
    def status(self):
        return "ERROR" if self.errors else ("WARNING" if self.warnings else "PASS")


# --------------------------------------------------------------------------
# UI scan: what does the Swift code actually read / draw?
# --------------------------------------------------------------------------

def scan_ui():
    text = "\n".join(p.read_text() for p in UI_FILES)
    reads = set(re.findall(r"payload\.(\w+)", text))
    return {
        "reads": reads,
        "target_ring": "object.target == true" in text,        # ShapeHuntSceneView highlights targets
        "shows_correct_pieces": "payload.correctPieces" in text,  # buildShape detail line
        "stacks_same_cell": ".position(" in text and "(CGFloat(object.x) + 0.5)" in text,
    }


UI = scan_ui()

# payload data an item's answer is derived from, per spatial format
ANSWER_DEPENDS_ON = {"positionWords": "objects", "rotateToMatch": "options", "symmetryMirror": "halfCells",
                     "netPreview": "options", "shapeHunt": "scene"}


# --------------------------------------------------------------------------
# MATH
# --------------------------------------------------------------------------

def check_math(r: Result):
    it, p, ans = r.item, r.item["payload"], r.item["answer"]
    f, sk, prompt = it["format"], it["skill"], it["prompt"]

    def want(expected):
        r.expect("MATH", str(expected) == ans, f"recomputed {expected!r} but stored answer is {ans!r}")

    def target_agrees(expected):
        if p.get("target") is not None:
            r.expect("MATH.target", Fraction(str(p["target"])) == Fraction(str(expected)),
                     f"payload.target={p['target']!r} but recomputed {expected!r}")

    if f == "addTwoDigit":
        if sk == "mult_multi_digit":
            v = p["left"] * p["right"]; want(v); target_agrees(v)
            r.expect("PROMPT", prompt == f"{p['left']} × {p['right']} = ?", "prompt != payload")
        elif sk == "div_partial_quotients":
            r.expect("MATH.exact", p["dividend"] % p["divisor"] == 0, "division not exact")
            v = p["dividend"] // p["divisor"]; want(v); target_agrees(v)
            r.expect("PROMPT", prompt == f"{p['dividend']} ÷ {p['divisor']} = ?", "prompt != payload")
        elif " - " in prompt:
            v = p["left"] - p["right"]; want(v); target_agrees(v)
            r.expect("PROMPT", prompt == f"{p['left']} - {p['right']} = ?", "prompt != payload")
            r.expect("MATH.nonneg", v >= 0, "negative result")
        else:
            v = p["left"] + p["right"]; want(v); target_agrees(v)
            r.expect("PROMPT", prompt == f"{p['left']} + {p['right']} = ?", "prompt != payload")
        if sk == "add_sub_regroup":
            r.expect("MATH.regroup", (p["left"] % 10) + (p["right"] % 10) >= 10, "skill says regroup but ones do not carry")
    elif f == "additionStory":
        if sk == "multi_step":
            n = [int(x) for x in nums(prompt)]
            r.expect("PROMPT", len(n) == 3, f"expected 3 numbers, got {n}")
            if len(n) == 3:
                a, b, c = n
                v = a + b - c if "gets" in prompt.split("Then")[0] else a - b + c
                want(v); r.expect("MATH.nonneg", v >= 0, "negative result")
        else:
            v = p["left"] + p["right"]; want(v); target_agrees(v)
            r.expect("PROMPT", prompt == f"{p['left']} + {p['right']} = ?", "prompt != payload")
            r.expect("MATH.range", v <= {"add_within_5": 5, "add_within_10": 10, "add_within_20": 20}[sk], "sum exceeds skill range")
    elif f == "subtractionStory":
        v = p["minuend"] - p["subtrahend"]; want(v); target_agrees(v)
        r.expect("MATH.nonneg", v >= 0, "negative result")
        r.expect("PROMPT", [int(x) for x in nums(prompt)] == [p["minuend"], p["subtrahend"]], "prompt numbers != payload")
        r.expect("MATH.range", p["minuend"] <= {"sub_within_10": 10, "sub_within_20": 20}[sk], "minuend exceeds skill range")
    elif f == "subTwoDigit":
        v = p["minuend"] - p["subtrahend"]; want(v); target_agrees(v)
        r.expect("PROMPT", prompt == f"{p['minuend']} - {p['subtrahend']} = ?", "prompt != payload")
    elif f == "factFamily":
        if p.get("left") is not None:
            v = p["target"] - p["left"]; r.expect("PROMPT", prompt == f"{p['left']} + ? = {p['target']}", "prompt != payload")
        else:
            v = p["target"] - p["right"]; r.expect("PROMPT", prompt == f"? + {p['right']} = {p['target']}", "prompt != payload")
        want(v); r.expect("MATH.nonneg", v >= 0, "negative addend")
    elif f == "numberBond":
        known = p["right"] if p.get("right") is not None else p["left"]
        want(p["target"] - known)
        r.expect("PROMPT", [int(x) for x in nums(prompt)] == [known, p["target"]], "prompt numbers != payload")
        if p["target"] != 10:
            r.warn("SKILL", f"skill '{sk}' (bond to 10) but the whole is {p['target']}; math is right, skill label is not")
    elif f == "countAndMatch":
        want(p["target"]); r.expect("MATH.range", 0 <= p["target"] <= 10, "count outside 0..10")
    elif f == "measureLength":
        want(p["target"]); r.expect("MATH.range", 1 <= p["target"] <= 12, "length outside 1..12")
    elif f == "groupComparison":
        want({"<": "Fewer", ">": "More", "=": "Same"}[cmp_symbol(p["left"], p["right"])])
        r.expect("PROMPT", [int(x) for x in nums(prompt)] == [p["left"], p["right"]], "prompt numbers != payload")
    elif f in ("twoDigitComparison", "threeDigitComparison"):
        want(cmp_symbol(p["left"], p["right"]))
        r.expect("PROMPT", [int(x) for x in nums(prompt)] == [p["left"], p["right"]], "prompt numbers != payload")
    elif f == "decimalComparison":
        a, b = Decimal(str(p["decimalLeft"])), Decimal(str(p["decimalRight"]))
        want(cmp_symbol(a, b))
        r.expect("PROMPT", [Decimal(x) for x in nums(prompt)] == [a, b], "prompt numbers != payload")
    elif f == "fractionComparison":
        want(cmp_symbol(Fraction(p["numeratorA"], p["denominatorA"]), Fraction(p["numeratorB"], p["denominatorB"])))
        r.expect("PROMPT", frac_tokens(prompt) == [(p["numeratorA"], p["denominatorA"]), (p["numeratorB"], p["denominatorB"])],
                 "prompt fractions != payload")
    elif f == "fractionAddSub":
        a = Fraction(p["numeratorA"], p["denominatorA"]); b = Fraction(p["numeratorB"], p["denominatorB"])
        res = a - b if " - " in prompt else a + b
        r.expect("MATH.nonneg", res >= 0, "negative result")
        m = re.fullmatch(r"(\d+)/(\d+)", ans)
        r.expect("MATH.format", m is not None, f"answer {ans!r} not n/d")
        if m:
            r.expect("MATH", Fraction(int(m.group(1)), int(m.group(2))) == res,
                     f"exact result is {res} but stored {ans!r} = {Fraction(int(m.group(1)), int(m.group(2)))}")
            if p["denominatorA"] == p["denominatorB"]:
                r.expect("MATH.form", int(m.group(2)) == p["denominatorA"], "like-denominator answer changes denominator")
        r.expect("PROMPT", frac_tokens(prompt) == [(p["numeratorA"], p["denominatorA"]), (p["numeratorB"], p["denominatorB"])],
                 "prompt fractions != payload")
        r.expect("MATH.skill", (p["denominatorA"] == p["denominatorB"]) == (sk == "fraction_add_sub"), "skill vs denominators mismatch")
    elif f == "fractionOfWhole":
        a = Fraction(p["numeratorA"], p["denominatorA"]) * p["whole"]
        r.expect("MATH.integer", a.denominator == 1, f"result {a} is not a whole number")
        want(a.numerator); target_agrees(a)
        r.expect("PROMPT", prompt == f"What is {p['numeratorA']}/{p['denominatorA']} of {p['whole']}?", "prompt != payload")
    elif f == "multiplicationArray":
        v = p["multiplicand"] * p["multiplier"]; want(v); target_agrees(v)
        word = "rows" if sk == "mult_array_basic" else "groups"
        r.expect("PROMPT", prompt == f"{p['multiplicand']} {word} of {p['multiplier']}. How many in all?", "prompt != payload")
    elif f == "divisionGroups":
        r.expect("MATH.exact", p["dividend"] % p["divisor"] == 0, "division not exact")
        want(p["dividend"] // p["divisor"])
        r.expect("PROMPT", nums(prompt) == [str(p["dividend"]), str(p["divisor"])], "prompt numbers != payload")
    elif f == "areaTiling":
        want(p["length"] * p["width"])
        r.expect("PROMPT", nums(prompt) == [str(p["length"]), str(p["width"])], "prompt numbers != payload")
    elif f == "volumePrism":
        v = p["length"] * p["width"] * p["height"]; want(v); target_agrees(v)
        r.expect("PROMPT", nums(prompt) == [str(p["length"]), str(p["width"]), str(p["height"])], "prompt numbers != payload")
    elif f == "angleMeasure":
        want(p["degrees"]); r.expect("MATH.range", 0 < p["degrees"] < 360, "degrees out of range")
    elif f == "ratioTable":
        # RatioTableInteraction draws A = L, 2L, 3L, ? so '?' is the 4th multiple
        want(p["ratioLeft"] * 4); target_agrees(p["ratioLeft"] * 4)
        r.expect("PROMPT", nums(prompt) == [str(p["ratioLeft"]), str(p["ratioRight"])], "prompt numbers != payload")
    elif f == "shapeClassification":
        nm = p["shapeName"]
        r.expect("MATH.facts", nm in SHAPE_FACTS and (p["sides"], p["corners"]) == SHAPE_FACTS[nm], f"{nm} sides/corners wrong")
        if prompt.startswith("How many sides"):
            want(str(p["sides"])); r.expect("PROMPT", nm in prompt, "prompt shape != payload")
        else:
            want(nm)
            m = re.search(r"has (\d+) sides and (\d+) corners", prompt)
            s, c = (int(m.group(1)), int(m.group(2))) if m else (0, 0)
            r.expect("PROMPT", (s, c) == (p["sides"], p["corners"]), "prompt sides/corners != payload")
            others = sorted(k for k, v in SHAPE_FACTS.items() if v == (s, c) and k != nm)
            if others:
                r.warn("CHOICES.ambiguous",
                       f"'{s} sides and {c} corners' also fits {others}; any of these can be offered as a distractor "
                       f"(the screen shows the picture, but a square is also a rectangle)")
    elif f == "teenPlaceValue":
        if sk == "teen_decompose":
            t = p["target"]
            r.expect("MATH", ans == f"{t // 10}|{t % 10}", f"expected {t // 10}|{t % 10}")
            r.expect("MATH.payload", (p["tens"], p["ones"]) == (t // 10, t % 10), "payload tens/ones != target")
            r.expect("PROMPT", nums(prompt) == [str(t)], "prompt number != payload target")
        else:
            h, t, o = [int(x) for x in nums(prompt)]
            total = h * 100 + t * 10 + o
            r.expect("MATH", ans == f"{total // 10}|{total % 10}", f"expected {total // 10}|{total % 10}")
            r.expect("MATH.target", p["target"] == total, "payload.target != value")
            r.expect("MATH.payload", (p["tens"], p["ones"]) == (total // 10, total % 10), "payload tens/ones != value")
            r.warn("UX", f"answer '{ans}' means {total // 10} presses of the Tens '+' button; the screen has no hundreds column "
                         "for a 3-digit prompt")
    elif f == "timeMoney":
        if p.get("hours") is not None:
            want(f"{p['hours']}:{p['minutes']:02d}")
            r.expect("MATH.range", 1 <= p["hours"] <= 12 and 0 <= p["minutes"] < 60, "time out of range")
        else:
            want(p["cents"]); r.expect("MATH.range", p["cents"] >= 1, "cents < 1")
    elif f == "dataPlot":
        vals, labs = p["barValues"], p["barLabels"]
        r.expect("MATH.shape", len(vals) == len(labs), "values/labels length differ")
        val = dict(zip(labs, vals))
        if prompt.startswith(("Which has the most", "Which fraction has the most")):
            mx = max(vals); winners = [l for l, v in zip(labs, vals) if v == mx]
            r.expect("CHOICES.unique", len(winners) == 1, f"{len(winners)} labels tie for most ({winners}); each is a correct answer")
            r.expect("MATH", ans in winners, f"stored {ans!r} is not a maximum")
        elif (m := re.fullmatch(r"How many more (\w+) than (\w+)\?", prompt)):
            a, b = m.group(1), m.group(2)
            r.expect("PROMPT", a in val and b in val, f"labels {a},{b} not in {labs}")
            if a in val and b in val:
                diff = val[a] - val[b]
                r.expect("MATH.negative", diff > 0, f"{a}={val[a]}, {b}={val[b]}: '{a} has {abs(diff)} fewer', "
                                                     f"so 'how many more {a} than {b}' has no positive answer (stored {ans!r})")
                r.expect("MATH", str(diff) == ans, f"{val[a]} - {val[b]} = {diff} but stored {ans!r}")
        elif (m := re.fullmatch(r"How many (?:data points at )?(\S+?)\?", prompt)):
            lab = m.group(1)
            r.expect("PROMPT", lab in val, f"label {lab!r} not in {labs}")
            if lab in val:
                want(val[lab])
        else:
            r.err("COVERAGE", f"unrecognised dataPlot prompt {prompt!r}")
    elif f not in SPATIAL_FORMATS:
        r.err("COVERAGE", f"no independent checker for format {f}")


# --------------------------------------------------------------------------
# RUNTIME: replicate SessionComposer's deterministic option generation
# --------------------------------------------------------------------------

def numeric_options(answer: int):
    cand = {answer}
    for off in (-4, -2, -1, 1, 2, 3):
        cand.add(max(0, answer + off))
    sel = sorted(cand)[:4]
    if answer not in sel:
        sel[-1] = answer
    return sorted(sel)


def check_runtime(r: Result):
    it, ans = r.item, r.item["answer"]
    numeric_formats = {"subtractionStory", "multiplicationArray", "fractionOfWhole", "volumePrism", "additionStory",
                       "countAndMatch", "numberBond", "factFamily", "addTwoDigit", "subTwoDigit", "measureLength",
                       "areaTiling", "angleMeasure", "ratioTable", "divisionGroups"}
    if it["format"] in numeric_formats and ans.isdigit():
        opts = numeric_options(int(ans))
        r.expect("RUNTIME.options", ans in [str(o) for o in opts] and len(set(opts)) == len(opts),
                 f"generated options {opts} do not contain the answer exactly once")


# --------------------------------------------------------------------------
# SPATIAL
# --------------------------------------------------------------------------

def folds_to_cube(rows) -> bool:
    """Roll a cube over the '#' cells; the net folds iff the 6 cells get 6 distinct faces and the roll is consistent."""
    cells = {(x, y) for y, row in enumerate(rows) for x, c in enumerate(row) if c == "#"}
    if len(cells) != 6:
        return False

    def roll(st, d):
        t, b, n, so, e, w = st
        return {"E": (w, e, n, so, t, b), "W": (e, w, n, so, b, t),
                "N": (so, n, t, b, e, w), "S": (n, so, b, t, e, w)}[d]

    step = {"E": (1, 0), "W": (-1, 0), "N": (0, -1), "S": (0, 1)}
    start = min(cells)
    state = {start: (0, 1, 2, 3, 4, 5)}
    queue = [start]
    while queue:
        c = queue.pop(0)
        for d, (dx, dy) in step.items():
            nb = (c[0] + dx, c[1] + dy)
            if nb in cells and nb not in state:
                state[nb] = roll(state[c], d)
                queue.append(nb)
    if len(state) != 6:
        return False                       # not connected
    for c in cells:                        # cycles must roll consistently
        for d, (dx, dy) in step.items():
            nb = (c[0] + dx, c[1] + dy)
            if nb in cells and roll(state[c], d) != state[nb]:
                return False
    return len({st[1] for st in state.values()}) == 6


def reflect_half(half, axis):
    return [r[::-1] for r in half] if axis == "vertical" else half[::-1]


assert folds_to_cube([".#..", "####", ".#.."]) and folds_to_cube([".#..", "####", "..#."]) and folds_to_cube(["##..", ".##.", "..##"])
assert not folds_to_cube(["######"]) and not folds_to_cube([".#..", "####"]) and not folds_to_cube(["###", "###"])


def check_spatial(r: Result):
    it, p, ans, ch = r.item, r.item["payload"], r.item["answer"], r.item.get("choices") or []
    f = it["format"]

    if f == "shapeHunt":
        scene = p["scene"]
        cnt = sum(1 for s in scene if s["shape"] == p["targetShape"])
        flagged = sum(1 for s in scene if s.get("target"))
        r.expect("MATH", str(cnt) == ans, f"scene contains {cnt} {p['targetShape']}(s), stored {ans!r}")
        r.expect("MATH.payload", cnt == p["targetCount"] == flagged, f"targetCount={p['targetCount']} flagged={flagged} actual={cnt}")
        r.expect("MATH.flags", all(bool(s.get("target")) == (s["shape"] == p["targetShape"]) for s in scene),
                 "a shape's `target` flag disagrees with its shape")
        gx, gy = p["gridSize"]["columns"], p["gridSize"]["rows"]
        r.expect("VISUAL.bounds", all(0 <= s["x"] < gx and 0 <= s["y"] < gy for s in scene), "shape outside grid")
        cells = defaultdict(list)
        for s in scene:                      # scene order == draw order (later draws on top)
            cells[(s["x"], s["y"])].append(s)
        for cell, group in cells.items():
            if len(group) > 1:
                covered = [g["shape"] for i, g in enumerate(group[:-1]) if g["shape"] == p["targetShape"]]
                msg = f"cell {cell} holds {len(group)} shapes ({[g['shape'] for g in group]}) drawn on top of each other"
                if covered:
                    r.err("VISUAL.overlap", msg + f"; a target {covered[0]} is drawn first and is covered by a later shape, "
                                                  "so the visible count can be lower than the answer")
                else:
                    r.warn("VISUAL.overlap", msg + " (no target shape is covered)")
        if UI["target_ring"]:
            r.warn("UI.leak", "every target shape is drawn with a highlight ring, so the answer is visible without finding shapes")
    elif f == "positionWords":
        objs = {o["name"]: o for o in p["objects"]}
        a = objs[p["anchor"]]
        offsets = {"above": [(0, -1)], "below": [(0, 1)], "left of": [(-1, 0)], "right of": [(1, 0)],
                   "beside": [(-1, 0), (1, 0)]}.get(p["relation"])
        if offsets is None:
            r.err("MATH.relation", f"unknown relation {p['relation']!r}")
        else:
            ok_cells = {(a["x"] + dx, a["y"] + dy) for dx, dy in offsets}
            valid = sorted(n for n, o in objs.items() if n != p["anchor"] and (o["x"], o["y"]) in ok_cells)
            good = sorted(c for c in ch if c in valid)
            r.expect("CHOICES.unique", len(good) == 1,
                     f"{len(good)} choices are '{p['relation']}' the {p['anchor']}: {good}")
            r.expect("MATH", ans in valid, f"stored {ans!r} is not {p['relation']} the {p['anchor']} (valid objects: {valid})")
        gx, gy = p["gridSize"]["columns"], p["gridSize"]["rows"]
        r.expect("VISUAL.bounds", all(0 <= o["x"] < gx and 0 <= o["y"] < gy for o in p["objects"]), "object outside grid")
        cells = Counter((o["x"], o["y"]) for o in p["objects"])
        shared = [c for c, n in cells.items() if n > 1]
        if shared:
            r.warn("VISUAL.overlap", f"objects share cell(s) {shared}")
    elif f == "rotateToMatch":
        step = ROT_SYMMETRY.get(p["shape"])
        r.expect("MATH.known", step is not None, f"no symmetry data for {p['shape']}")
        plain = [o for o in p["options"] if not o["mirrored"]]
        exact = [o["label"] for o in plain if o["rotation"] % 360 == p["rotationDegrees"] % 360]
        r.expect("MATH", exact == [ans], f"options with exactly the asked rotation: {exact}, stored {ans!r}")
        if step:
            same = [o["label"] for o in plain if (o["rotation"] - p["rotationDegrees"]) % step == 0]
            r.expect("CHOICES.unique", len(same) == 1,
                     f"a {p['shape']} looks identical after turns of {step}°, so options {same} are indistinguishable")
        if p["shape"] in MIRROR_SYMMETRIC and any(o["mirrored"] for o in p["options"]):
            r.warn("CHOICES.mirror", f"'{p['shape']}' has a mirror line, so its mirrored distractors equal some rotation of it")
        if step:
            keys = [((o["rotation"] % 360) % step, bool(o["mirrored"]) and p["shape"] not in MIRROR_SYMMETRIC) for o in p["options"]]
            r.expect("CHOICES.distinct", len(set(keys)) == 4, f"options are not four distinct pictures: {keys}")
        r.expect("CHOICES.labels", [o["label"] for o in p["options"]] == ch, "option labels != choices")
        if re.search(r"\d+ degrees", it["prompt"]):
            r.expect("PROMPT", str(p["rotationDegrees"]) in it["prompt"], "prompt degrees != payload.rotationDegrees")
    elif f == "buildShape":
        cp, tgt = p["correctPieces"], p["targetShape"]
        r.expect("MATH", ans == cp, f"stored {ans!r} != payload.correctPieces {cp!r}")
        r.expect("CHOICES.set", sorted(ch) == sorted([cp] + p["distractorPieces"]), "choices != correct + distractors")
        unknown = [c for c in ch if (tgt, c) not in CAN_BUILD]
        if unknown:
            r.err("COVERAGE", f"no geometry entry for {tgt}: {unknown}")
        else:
            can = [c for c in ch if CAN_BUILD[(tgt, c)]]
            r.expect("CHOICES.unique", len(can) == 1,
                     f"{len(can)} choices can build a {tgt}: {can} (e.g. two right triangles make a rectangle)")
            r.expect("MATH.geometry", ans in can, f"stored {ans!r} cannot build a {tgt}")
        if UI["shows_correct_pieces"]:
            r.err("UI.leak", f"the screen text reads 'Build a {tgt} with {cp}.' - it states the correct answer")
    elif f == "symmetryMirror":
        marked = [o["label"] for o in p["options"] if o["mirrorsCorrectly"]]
        r.expect("CHOICES.unique", len(marked) == 1, f"{len(marked)} options flagged correct: {marked}")
        r.expect("MATH", marked == [ans] == [p["answerChoice"]], f"flags {marked}, answerChoice {p['answerChoice']!r}, answer {ans!r}")
        r.expect("CHOICES.labels", [o["label"] for o in p["options"]] == ch, "option labels != choices")
        half = p.get("halfCells")
        if not half or any("cells" not in o for o in p["options"]):
            r.err("VERIFY.limit", "no drawable half-picture / option cells; correctness cannot be derived")
        else:
            want = reflect_half(half, p["axis"])
            match = [o["label"] for o in p["options"] if o["cells"] == want]
            r.expect("MATH.reflect", match == [ans], f"options equal to the true {p['axis']}-mirror image: {match}, stored {ans!r}")
            r.expect("CHOICES.distinct", len({tuple(o["cells"]) for o in p["options"]}) == 4, "option pictures are not four distinct pictures")
            r.expect("MATH.asym", half != want, "the half-picture is its own mirror image, so the question is trivial")
    elif f == "gridPath":
        sx, sy = p["startPosition"]["x"], p["startPosition"]["y"]
        dx = dy = 0
        for n, d in re.findall(r"(\d+) (right|left|up|down)", p["moves"]):
            n = int(n)
            dx += n if d == "right" else -n if d == "left" else 0
            dy += n if d == "down" else -n if d == "up" else 0
        r.expect("MATH.delta", (dx, dy) == (p["delta"]["x"], p["delta"]["y"]), f"moves give {(dx, dy)}, delta {p['delta']}")
        tx, ty = sx + dx, sy + dy
        r.expect("MATH.target", (tx, ty) == (p["targetPosition"]["x"], p["targetPosition"]["y"]),
                 f"start+moves={(tx, ty)} but targetPosition={p['targetPosition']}")
        gx, gy = p["gridSize"]["columns"], p["gridSize"]["rows"]
        r.expect("VISUAL.bounds", 0 <= tx < gx and 0 <= ty < gy,
                 f"the path ends at {(tx, ty)}, outside the {gx}x{gy} grid, so no object can be there (answer {ans!r})")
        r.expect("MATH", ans == p["targetObject"], f"stored {ans!r} != payload.targetObject")
        r.expect("PROMPT", p["start"] in it["prompt"] and p["moves"] in it["prompt"], "on-screen prompt lacks the start object or the moves")
        if p["moves"] not in (it.get("spokenForm") or ""):
            r.warn("SPOKEN.incomplete", f"narration '{it.get('spokenForm')}' never says the moves ('{p['moves']}'); a child who only "
                                        "listens cannot answer (audio is deferred)")
        lay = p.get("objects")
        if not lay:
            r.err("VERIFY.limit", "payload has no object layout, so the object at the end cell cannot be verified or drawn")
        else:
            cells = Counter((o["x"], o["y"]) for o in lay)
            r.expect("VISUAL.layout", all(n == 1 for n in cells.values()), "two objects share a cell")
            r.expect("VISUAL.layout", all(0 <= o["x"] < gx and 0 <= o["y"] < gy for o in lay), "layout object outside grid")
            at_end = [o["name"] for o in lay if (o["x"], o["y"]) == (tx, ty)]
            r.expect("CHOICES.unique", at_end == [ans], f"objects at the end cell: {at_end}, stored {ans!r}")
            at_start = [o["name"] for o in lay if (o["x"], o["y"]) == (sx, sy)]
            r.expect("VISUAL.layout", at_start == [p["start"]], f"objects at the start cell: {at_start}, expected {p['start']!r}")
            names = {o["name"] for o in lay}
            r.expect("VISUAL.layout", set(ch) <= names, f"choices {sorted(set(ch) - names)} are not drawn on the map")
    elif f == "solidAttributes":
        nm, clue = p["solidName"], p["attribute"]
        r.expect("MATH", ans == nm, f"stored {ans!r} != payload.solidName")
        fev = (p["faces"], p["edges"], p["vertices"])
        r.expect("MATH.facts", SOLID_FEV.get(nm) == fev, f"{nm}: faces/edges/vertices {fev} != {SOLID_FEV.get(nm)}")
        if nm in ("cube", "rectangular prism", "pyramid"):
            r.expect("MATH.euler", fev[0] - fev[1] + fev[2] == 2, "Euler F-E+V != 2")
        if clue not in CLUE_TRUE_FOR:
            r.err("COVERAGE", f"no truth entry for clue {clue!r}")
        else:
            good = sorted(c for c in ch if c in CLUE_TRUE_FOR[clue] or (c == nm and nm in CLUE_TRUE_FOR[clue]))
            r.expect("CHOICES.unique", good == [ans], f"choices satisfying clue '{clue}': {good}, stored {ans!r}")
    elif f == "netPreview":
        r.expect("MATH.solid", p["targetSolid"] == "cube", "only cube nets are modelled")
        if any("cells" not in o for o in p["options"]):
            r.err("VERIFY.limit", "net options carry no drawable cells; folding cannot be verified or drawn")
        else:
            real = {o["label"]: folds_to_cube(o["cells"]) for o in p["options"]}
            truth = [lab for lab, ok in real.items() if ok]
            flagged = [o["label"] for o in p["options"] if o["foldsToCube"]]
            r.expect("CHOICES.unique", len(truth) == 1, f"{len(truth)} drawn nets really fold into a cube: {truth}")
            wrong = [lab for lab, ok in real.items() if ok != next(o for o in p["options"] if o["label"] == lab)["foldsToCube"]]
            r.expect("MATH.label", not wrong, f"foldsToCube flag contradicts the folding simulation for {wrong}")
            r.expect("MATH", flagged == [ans] == [p["answerChoice"]] == truth, f"flags {flagged}, simulation {truth}, answerChoice {p['answerChoice']!r}, answer {ans!r}")
        r.expect("CHOICES.labels", [o["label"] for o in p["options"]] == ch, "option labels != choices")

    # UI: does any view display the data the answer depends on?
    need = ANSWER_DEPENDS_ON.get(f)
    if need and need not in UI["reads"]:
        r.err("UI.undisplayed", f"the answer depends on payload.{need}, but no Swift view reads it - the child sees only the "
                                 f"text prompt and choices {ch}")
    if f == "gridPath" and "objects" not in UI["reads"]:
        r.err("UI.undisplayed", "no map of the grid is drawn, so the child cannot know which object is at the end cell")

    if ch:
        r.expect("CHOICES.contains", ans in ch, f"answer {ans!r} not in choices")
        r.expect("CHOICES.dupes", len(set(ch)) == len(ch), f"duplicate choices {ch}")
        r.expect("CHOICES.count", len(ch) == 4, f"{len(ch)} choices")


# --------------------------------------------------------------------------
# STRUCT / SPOKEN / AUDIO
# --------------------------------------------------------------------------

def check_struct(r: Result, units, ids_seen):
    it = r.item
    for k in ("id", "unit", "skill", "format", "difficulty", "prompt", "answer", "supports", "payload"):
        r.expect("STRUCT.field", k in it and it[k] not in (None, ""), f"missing/empty field {k}")
    r.expect("STRUCT.unique_id", it["id"] not in ids_seen, f"duplicate id {it['id']}")
    ids_seen.add(it["id"])
    r.expect("STRUCT.unit", it["unit"] in units, f"unknown unit {it['unit']}")
    r.expect("STRUCT.difficulty", isinstance(it["difficulty"], int) and 1 <= it["difficulty"] <= 5, f"difficulty {it['difficulty']!r}")
    r.expect("STRUCT.answer", isinstance(it["answer"], str) and it["answer"] == it["answer"].strip(), "answer not a trimmed string")


WORD_NUM = {"zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8,
            "nine": 9, "ten": 10, "eleven": 11, "twelve": 12}
DEN_WORDS = {"half": 2, "halves": 2, "halfs": 2, "third": 3, "thirds": 3, "fourth": 4, "fourths": 4, "fifth": 5,
             "fifths": 5, "sixth": 6, "sixths": 6, "seventh": 7, "sevenths": 7, "eighth": 8, "eighths": 8,
             "ninth": 9, "ninths": 9, "tenth": 10, "tenths": 10, "eleventh": 11, "elevenths": 11,
             "twelfth": 12, "twelfths": 12}
_DEN_ALT = "|".join(sorted(DEN_WORDS, key=len, reverse=True))
_WORD_ALT = "|".join(WORD_NUM)


def spoken_values(text: str):
    t = text.lower().replace(",", "")
    out = []
    for m in re.finditer(rf"\b(\d+|{_WORD_ALT})\s+({_DEN_ALT})\b", t):
        n = int(m.group(1)) if m.group(1).isdigit() else WORD_NUM[m.group(1)]
        out.append(("frac", n, DEN_WORDS[m.group(2)]))
    t = re.sub(rf"\b(\d+|{_WORD_ALT})\s+({_DEN_ALT})\b", " ", t)
    for m in re.finditer(rf"\b(\d)\s+point\s+((?:(?:{'|'.join(list(WORD_NUM)[:10])})\s*)+)", t):
        out.append(("num", Decimal(f"{m.group(1)}.{''.join(str(WORD_NUM[w]) for w in m.group(2).split())}")))
    t = re.sub(rf"\b(\d)\s+point\s+((?:(?:{'|'.join(list(WORD_NUM)[:10])})\s*)+)", " ", t)
    for a, b in re.findall(r"(\d+)/(\d+)", t):
        out.append(("frac", int(a), int(b)))
    t = re.sub(r"\d+/\d+", " ", t)
    for m in re.finditer(r"\d+(?:\.\d+)?", t):
        out.append(("num", Decimal(m.group(0))))
    return out


def prompt_values(text: str):
    t = text.replace(",", "")
    out = [("frac", int(a), int(b)) for a, b in re.findall(r"(\d+)/(\d+)", t)]
    t = re.sub(r"\d+/\d+", " ", t)
    out += [("num", Decimal(m.group(0))) for m in re.finditer(r"\d+(?:\.\d+)?", t)]
    return out


def _norm(vs):
    return sorted(((k, *(x.normalize() if isinstance(x, Decimal) else x for x in rest)) for k, *rest in vs), key=repr)


def check_spoken(r: Result):
    it = r.item
    sp = it.get("spokenForm")
    if not sp:
        r.err("SPOKEN", "missing spokenForm")
        return
    pn, sn = _norm(prompt_values(it["prompt"])), _norm(spoken_values(sp))
    if pn == sn:
        r.ok("SPOKEN.numbers")
    elif all(sn.count(v) <= pn.count(v) for v in sn):
        r.warn("SPOKEN.omits", f"narration leaves out numbers shown on screen {[v for v in pn if pn.count(v) > sn.count(v)]} :: {sp!r}")
    else:
        r.err("SPOKEN.numbers", f"numbers in prompt {pn} != spoken {sn} :: {sp!r}")
    for sym, word in {"+": "plus", "-": "minus", "×": "times", "÷": "divided by"}.items():
        if f" {sym} " in it["prompt"]:
            r.expect("SPOKEN.operator", word in sp.lower(), f"prompt has '{sym}' but spoken form lacks '{word}': {sp!r}")
    low = sp.lower()
    if re.search(r"\b(1|one)\s+(halfs|halves|thirds|fourths|fifths|sixths|sevenths|eighths|ninths|tenths|elevenths|twelfths)\b", low) \
            or "halfs" in low:
        r.warn("SPOKEN.grammar", f"ungrammatical audio text: {sp!r}")
    if re.search(r"\d+/\d+", sp):
        r.warn("SPOKEN.tts", f"spoken form keeps '{re.search(r'[0-9]+/[0-9]+', sp).group(0)}' as digits; TTS may read it as a date or "
                             f"'slash'. Write it in words: {sp!r}")
    if it["format"] in ("twoDigitComparison", "threeDigitComparison", "fractionComparison", "decimalComparison") \
            and it["answer"] == "=" and "bigger" in low:
        r.warn("SPOKEN.semantics", f"narration asks 'which is bigger' but the numbers are equal (answer '='): {sp!r}")


def check_audio(r: Result, base_index, future_index, manifest, future_text):
    it = r.item
    aid = it.get("audioID") or it["id"]
    spoken = it.get("spokenForm") or it["prompt"]
    if it.get("audioID"):
        rel = future_index.get(aid)
        src = future_text.get(aid)
    else:
        rel = base_index.get(aid)
        src = manifest.get(aid)
    if rel is None:
        r.err("AUDIO.index", f"no audio index entry for {aid}")
        return
    path = AUDIO_DIR / rel
    if not path.is_file():
        r.err("AUDIO.file", f"indexed clip missing on disk: {rel} (the app falls back to system TTS)")
        return
    r.expect("AUDIO.size", path.stat().st_size > 1000, f"clip suspiciously small: {rel}")
    if src is None:
        r.warn("AUDIO.unproven", "no generation record for this clip, so it cannot be proven to say the current spokenForm")
    else:
        r.expect("AUDIO.text", src == spoken, f"clip was generated from {src!r} but spokenForm is now {spoken!r} (stale audio)")


# --------------------------------------------------------------------------
# Markdown report
# --------------------------------------------------------------------------

DEFECTS = {
    ("MATH.negative", "dataPlot"): ("A", "No positive answer exists",
        "Prompt asks 'How many more X than Y?' but X has fewer than Y. The key stores the absolute difference (1) for a true difference of -1.",
        "Swap X and Y in the prompt (and spokenForm), or reword to 'How many fewer'."),
    ("MATH", "dataPlot"): ("A", "Stored key differs from recomputed value",
        "Same four items: bar values give a difference of -1, key says 1.", "Same fix as above."),
    ("CHOICES.unique", "dataPlot"): ("A", "Several correct answers (tie for 'most')",
        "Two or three bars share the maximum, so more than one label is a right answer. The app grades only the stored label.",
        "Change one bar value so a single maximum exists."),
    ("CHOICES.unique", "positionWords"): ("A", "Several correct answers (two objects in the same cell)",
        "Two objects occupy the single cell directly above/below/beside the anchor, and both appear in the choices.",
        "Move one of the two objects to a different cell or drop it from the choices."),
    ("CHOICES.unique", "rotateToMatch"): ("A", "Several indistinguishable choices (rotational symmetry)",
        "A rectangle or diamond looks identical after a 180 degree turn, so two options show the same picture.",
        "Use an asymmetric shape for these items or avoid options that differ by exactly 180 degrees."),
    ("CHOICES.unique", "buildShape"): ("A", "Distractor is also correct",
        "Distractor 'two triangles' can build a rectangle (two right triangles joined along the long side).",
        "Replace the distractor with a piece set that cannot make a rectangle, e.g. 'two circles and one triangle'."),
    ("CHOICES.unique", "netPreview"): ("A", "Several options really fold into a cube",
        "Cross nets and T nets (four in a row, one above, one below) always fold into a cube, yet they are used as non-folding distractors in some items.",
        "Use only nets that cannot fold (strip, five-square, overlapping) as distractors; keep exactly one foldable net."),
    ("MATH.label", "netPreview"): ("A", "foldsToCube flag contradicts the net's own description",
        "The same descriptor is flagged both True and False in different items (see net table below); at least one set is wrong.",
        "Make the flag a function of the pattern, then regenerate answerChoice from it."),
    ("VISUAL.bounds", "gridPath"): ("A", "Path ends outside the grid",
        "Start plus moves lands at x = -1 on a 6x6 grid, so no object can be there; the stored answer cannot be right.",
        "Regenerate with moves that stay inside the grid."),
    ("VISUAL.overlap", "shapeHunt"): ("A", "Target shape can be hidden under another shape",
        "A target is drawn first in a cell that holds a second shape; all shapes share one frame size, so the later shape covers it.",
        "Generate scenes with at most one shape per cell."),
    ("UI.leak", "buildShape"): ("B", "Screen text reveals the answer",
        "The detail line reads 'Build a <target> with <correct pieces>.' using payload.correctPieces.",
        "Change the detail line to 'Which pieces build a <target>?' without the pieces."),
    ("UI.undisplayed", "positionWords"): ("B", "Data needed to answer is never drawn",
        "No view renders payload.objects; the child sees 'Look above the rocket.' with four object names and no picture.",
        "Add a grid view that draws payload.objects at (x, y)."),
    ("UI.undisplayed", "rotateToMatch"): ("B", "Data needed to answer is never drawn",
        "Choices A-D are labels only; payload.options (shape, rotation, mirrored) is not rendered.", "Draw each option rotated/mirrored."),
    ("UI.undisplayed", "symmetryMirror"): ("B", "Data needed to answer is never drawn",
        "Choices A-D are labels only, and the options carry no geometry at all, only a boolean.",
        "Define drawable geometry for each option, then render it."),
    ("UI.undisplayed", "gridPath"): ("B", "Data needed to answer is never drawn",
        "There is no map; the payload has no object layout, so 'which object is at the end cell' cannot be derived or shown.",
        "Add an object layout to the payload and draw the grid."),
    ("UI.undisplayed", "netPreview"): ("B", "Data needed to answer is never drawn",
        "Choices A-D are labels only; payload.options (pattern, description) is not rendered.", "Draw each net or show its description."),
    ("AUDIO.file", "threeDigitComparison"): ("C", "Audio clip indexed but missing from the bundle",
        "audio_index.json points to questions/pvm-001..035.mp3, which do not exist (pvm-036..040 do). The app falls back to system TTS.",
        "Generate pvm-001..035 (about 1,100 characters)."),
}
TIER_TITLE = {"A": "A. Answer-key and question-validity defects", "B": "B. Presentation defects (screen cannot support the question)",
              "C": "C. Audio defects"}


def _ids(rs, limit=14):
    ids = [r.item["id"] for r in rs]
    return ", ".join(ids[:limit]) + (f" ... (+{len(ids) - limit} more)" if len(ids) > limit else "")


def write_markdown(path, results, by_fmt, counts, assertions, codes):
    groups = defaultdict(list)
    for r in results:
        seen = set()
        for m in r.errors:
            c = m.split(":")[0]
            if (c, r.item["format"]) not in seen:
                seen.add((c, r.item["format"]))
                groups[(c, r.item["format"])].append(r)
    tier_items = defaultdict(set)
    for (c, f), rs in groups.items():
        t = DEFECTS.get((c, f), ("A",))[0]
        tier_items[t].update(r.item["id"] for r in rs)
    n = len(results)
    pv = [int(r.item["answer"].split("|")[0]) for r in results if r.item["skill"] == "place_value_1000"]
    robust = sum(1 for r in results if r.item["format"] == "netPreview" and (
        len(real := [o["label"] for o in r.item["payload"]["options"] if o["pattern"] in ("cross net", "T net")]) > 1
        or (len(real) == 1 and real[0] != r.item["answer"])))
    base = [r for r in results if r.item["format"] not in SPATIAL_FORMATS]
    sp = [r for r in results if r.item["format"] in SPATIAL_FORMATS]
    a_ids = tier_items["A"]
    L = []
    w = L.append
    w("# Question Bank Verification Report\n")
    w("Generated by `scripts/verify_question_bank.py` (deterministic: exact integer / Fraction / Decimal arithmetic, exact string "
      "comparison, closed reference tables; no sampling and no model judgement). Re-run: "
      "`python3 -I scripts/verify_question_bank.py --out docs/qa`.\n")
    w("## 1. Verdict\n")
    base_a = [r for r in base if r.item["id"] in a_ids]
    sp_ok = sum(1 for r in sp if r.status != "ERROR")
    base_ok = len(base) - len(base_a)
    b_only = tier_items["B"] - a_ids
    audio_missing = len(tier_items["C"])
    unproven = codes.get("W AUDIO.unproven", 0)
    w(f"- **Items checked:** {n} (`content-pack-v1.json`: {len(base)} numeric/visual-math items + {len(sp)} spatial items). "
      f"**Assertions evaluated:** {assertions}.")
    if not a_ids and not b_only:
        w("- **Every answer key is verified.** No question has a wrong key, several correct answers or an impossible setup, "
          "and the Swift views read every payload field the answer depends on (a source scan; see section 4).")
    else:
        w(f"- **Not every question is correct.** {len(a_ids)} items have an answer-key or question-validity defect (tier A) and "
          f"{len(b_only)} more are unanswerable or give the answer away on screen (tier B).")
    w(f"- **Core bank:** {base_ok} of {len(base)} non-spatial items have a verified-correct key"
      + (f"; the others are in: {', '.join(sorted({r.item['format'] for r in base_a}))}." if base_a else "."))
    w(f"- **Spatial bank (all live in the app):** {sp_ok} of {len(sp)} items have no error.")
    w(f"- **Audio (deferred, not changed):** {audio_missing} clips are indexed but missing from the bundle, and {unproven} clips "
      "have no generation record, so their text cannot be proven current.")
    w("- The data fixes applied to the bank are listed in `docs/qa/CORRECTED_QUESTIONS.md`.\n")
    w("| Status | Items |\n|---|---:|")
    for k in ("PASS", "WARNING", "ERROR"):
        w(f"| {k} | {counts[k]} |")
    w("")
    w("## 2. Results by format\n")
    w("| Format | Items | PASS | WARNING | ERROR |\n|---|---:|---:|---:|---:|")
    for f, c in sorted(by_fmt.items()):
        w(f"| {f}{' (spatial)' if f in SPATIAL_FORMATS else ''} | {sum(c.values())} | {c['PASS']} | {c['WARNING']} | {c['ERROR']} |")
    w("")
    for tier in ("A", "B", "C"):
        keys = sorted((k for k in groups if DEFECTS.get(k, ("A",))[0] == tier and k in DEFECTS))
        if not keys:
            continue
        w(f"## {TIER_TITLE[tier]}\n")
        w("| Format | Defect | Items | Affected ids | Why | Suggested fix |\n|---|---|---:|---|---|---|")
        for k in keys:
            _, title, why, fix = DEFECTS[k]
            rs = groups[k]
            w(f"| {k[1]} | {title} | {len(rs)} | {_ids(rs)} | {why} | {fix} |")
        w("")
    unmapped = sorted(k for k in groups if k not in DEFECTS)
    if unmapped:
        w("## Unclassified errors\n")
        for k in unmapped:
            w(f"- `{k[0]}` in {k[1]}: {len(groups[k])} items, e.g. {_ids(groups[k], 5)}")
        w("")
    # net descriptor consistency (geometry-free evidence)
    net = defaultdict(Counter)
    for r in results:
        if r.item["format"] == "netPreview":
            for o in r.item["payload"]["options"]:
                net[o["pattern"]][o["foldsToCube"]] += 1
    w(f"### Evidence: `netPreview` flag consistency\n\nOn cross nets and T nets alone (which always fold), {robust} of {sum(1 for r in results if r.item['format'] == 'netPreview')} "
      "items already contradict their key; the rest additionally rely on the 'zigzag net ... that can fold' description.\n")
    w("| Net descriptor | flagged foldsToCube=True | flagged False | Real geometry |\n|---|---:|---:|---|")
    for pat, c in sorted(net.items()):
        w(f"| {pat} | {c[True]} | {c[False]} | {'folds' if NET_FOLDS.get(pat) else 'does not fold'} |")
    w("\nA descriptor that is flagged both ways is wrong at least half the time whatever the geometry.\n")
    w("## 3. Warnings (answer is right, delivery is defective or not fully verifiable)\n")
    w("| Code | Items | Meaning |\n|---|---:|---|")
    meaning = {
        "AUDIO.unproven": "No generation record for the clip, so it cannot be proven to say the current spokenForm. Re-generate or log the text at generation time.",
        "CHOICES.ambiguous": "'4 sides and 4 corners' fits Square, Rectangle, Rhombus and Trapezoid; the picture disambiguates, the words do not (and a square is a rectangle).",
        "CHOICES.mirror": "Mirrored distractors on mirror-symmetric shapes equal a rotation of the shape.",
        "DUPLICATE": "Identical question (same prompt, payload, answer) appears more than once.",
        "SKILL": "Skill id says 'bond to 10' but the item bonds to 5 or 8 (math is right).",
        "SPOKEN.grammar": "Narration contains '1 sixths' / '1 halfs' style text; the voice will say it as written.",
        "SPOKEN.incomplete": "Narration omits the moves (they are on screen only).",
        "SPOKEN.semantics": "Narration asks 'which is bigger' when the numbers are equal.",
        "SPOKEN.tts": "Narration keeps '4/7' as digits; a TTS engine may read it as a date or 'slash'.",
        "UI.leak": "shapeHunt draws a highlight ring around every target shape, revealing the answer.",
        "UX": f"Place-value 1000 items need {min(pv)}-{max(pv)} presses of the Tens '+' button (no hundreds column).",
        "VERIFY.limit": "The payload lacks the data (geometry/layout) needed to verify the key independently.",
        "VISUAL.overlap": "Overlapping shapes where no target is covered.",
    }
    for c, nn in sorted(codes.items()):
        if c.startswith("W "):
            w(f"| {c[2:]} | {nn} | {meaning.get(c[2:], '')} |")
    w("")
    w("## 4. What this report does not cover\n")
    w("- **Hints and lesson text** (`hints`, `lesson-plans-k5.json`) were not checked.")
    w("- **Spoken audio content.** Whether an MP3 actually says its text needs a transcript; that is not deterministic and was not attempted. "
      "Only file existence and, where a generation record exists, text equality were checked.")
    w("- **Visual rendering of the iOS views** was inferred from the Swift source (which payload fields are read), not from running the app. "
      "The spatial SwiftUI code was written without a Swift toolchain in the authoring environment and has **not been compiled or run**; "
      "build and run `MathQuestKidsTests` in Xcode before shipping.")
    w("- Reference tables (shape facts, rotational symmetry, solid clues, piece-set geometry, net folding) are small closed sets printed at the top of the script; "
      "they are the only external knowledge used and are open to review.")
    w("- `symmetryMirror` correctness cannot be verified independently: its options contain only a boolean flag.\n")
    w("## 5. Per-question results\n")
    w("`docs/qa/question_verification.csv` has one row per item (id, unit, skill, format, prompt, stored answer, status, assertion count, errors, warnings).\n")
    Path(path).write_text("\n".join(L))


# --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", help="directory for CSV/JSON/MD reports")
    ap.add_argument("--ignore", action="append", default=[], metavar="CODE_PREFIX",
                    help="error codes starting with this prefix do not affect the exit status (repeatable), e.g. AUDIO.file")
    args = ap.parse_args()

    pack = json.loads(PACK.read_text())
    units = {u["id"] for u in pack["units"]}
    base_index = json.loads(AUDIO_INDEX.read_text())
    future_index = json.loads(FUTURE_INDEX.read_text())
    manifest = {m["id"]: m["text"] for m in json.loads(AUDIO_MANIFEST.read_text())}
    future_text = {c["id"]: c["text"] for c in json.loads(FUTURE_SET.read_text())["clips"]}

    results, ids_seen = [], set()
    for it in pack["itemTemplates"]:
        r = Result(it)
        check_struct(r, units, ids_seen)
        try:
            check_math(r)
            check_runtime(r)
            if it["format"] in SPATIAL_FORMATS:
                check_spatial(r)
        except Exception as e:  # a malformed payload is itself a defect
            r.err("EXCEPTION", f"{type(e).__name__}: {e}")
        check_spoken(r)
        check_audio(r, base_index, future_index, manifest, future_text)
        results.append(r)

    dup = defaultdict(list)
    for r in results:
        it = r.item
        dup[(it["format"], it["prompt"], it["answer"], json.dumps(it["payload"], sort_keys=True))].append(r)
    for rs in dup.values():
        if len(rs) > 1:
            for r in rs:
                r.warn("DUPLICATE", "identical question also appears as " + ", ".join(x.item["id"] for x in rs if x is not r))

    # spatial-bank file must match what the app actually loads
    byid = {r.item["id"]: r for r in results}
    for s in json.loads(SPATIAL_BANK.read_text())["items"]:
        r = byid.get(s["id"])
        if r is None:
            continue
        for k in ("prompt", "answer", "choices", "payload", "format", "unit", "skill", "spokenForm"):
            r.expect("CROSSCHECK", s.get(k) == r.item.get(k), f"{k!r} differs between spatial-question-bank-v2.json and content pack")

    counts = Counter(r.status for r in results)
    by_fmt = defaultdict(Counter)
    for r in results:
        by_fmt[r.item["format"]][r.status] += 1
    assertions = sum(sum(r.checks.values()) for r in results)
    codes = Counter()
    for r in results:
        for m in r.errors:
            codes["E " + m.split(":")[0]] += 1
        for m in r.warnings:
            codes["W " + m.split(":")[0]] += 1

    print(f"Items checked : {len(results)}")
    print(f"Assertions run: {assertions}")
    print(f"PASS={counts['PASS']}  WARNING={counts['WARNING']}  ERROR={counts['ERROR']}\n")
    print(f"{'format':24s} {'n':>5s} {'PASS':>6s} {'WARN':>6s} {'ERROR':>6s}")
    for f, c in sorted(by_fmt.items()):
        print(f"{f:24s} {sum(c.values()):5d} {c['PASS']:6d} {c['WARNING']:6d} {c['ERROR']:6d}")
    print()
    for k, n in sorted(codes.items()):
        print(f"  {k:26s} {n}")

    if args.out:
        out = Path(args.out)
        out.mkdir(parents=True, exist_ok=True)
        with open(out / "question_verification.csv", "w", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(["id", "unit", "skill", "format", "prompt", "stored_answer", "status", "assertions", "errors", "warnings"])
            for r in results:
                it = r.item
                w.writerow([it["id"], it["unit"], it["skill"], it["format"], it["prompt"], it["answer"], r.status,
                            sum(r.checks.values()), " | ".join(r.errors), " | ".join(r.warnings)])
        (out / "question_verification.json").write_text(json.dumps({
            "itemsChecked": len(results), "assertions": assertions, "counts": dict(counts),
            "byFormat": {f: dict(c) for f, c in sorted(by_fmt.items())}, "codes": dict(sorted(codes.items())),
            "ui": {"payloadKeysReadByViews": sorted(UI["reads"]), "targetRing": UI["target_ring"],
                   "showsCorrectPieces": UI["shows_correct_pieces"]},
            "findings": [{"id": r.item["id"], "format": r.item["format"], "unit": r.item["unit"], "prompt": r.item["prompt"],
                          "answer": r.item["answer"], "status": r.status, "errors": r.errors, "warnings": r.warnings}
                         for r in results if r.status != "PASS"]}, indent=1, sort_keys=True))
        write_markdown(out / "QUESTION_BANK_VERIFICATION.md", results, by_fmt, counts, assertions, codes)
        print(f"\nWrote {out}/question_verification.csv, .json and QUESTION_BANK_VERIFICATION.md")
    blocking = sum(1 for r in results for m in r.errors if not any(m.startswith(p) for p in args.ignore))
    if args.ignore:
        print(f"\nExit status counts {blocking} blocking error(s); ignored prefixes: {', '.join(args.ignore)}")
    return 1 if blocking else 0


if __name__ == "__main__":
    sys.exit(main())
