#!/usr/bin/env python3
"""
Generate question templates for ALL 38 MathQuestKids units.

- 8 existing K-2 units with only 5 templates each: adds 25 more (total 30)
- 22 new units: generates 30-35 templates each
- Adds unit definitions, lesson definitions, and hint templates for new units
- All answers are computed correctly
- All prompts are unique
- Payload always has ALL fields (null for unused)
"""

import json
import os
import random
import math
from fractions import Fraction

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
CONTENT_PATH = os.path.join(PROJECT_ROOT, "MathQuestKids", "Content", "content-pack-v1.json")

# Full payload with all null fields
ALL_PAYLOAD_KEYS = [
    "left", "right", "minuend", "subtrahend", "target", "tens", "ones",
    "multiplicand", "multiplier", "numeratorA", "denominatorA",
    "numeratorB", "denominatorB", "whole", "length", "width", "height",
    "decimalLeft", "decimalRight", "sides", "corners", "shapeName",
    "hours", "minutes", "cents", "dividend", "divisor", "degrees",
    "barValues", "barLabels", "ratioLeft", "ratioRight"
]

def make_payload(**kwargs):
    """Create a full payload dict with all keys, non-specified ones set to null."""
    p = {k: None for k in ALL_PAYLOAD_KEYS}
    p.update(kwargs)
    return p

def make_template(id_, unit, skill, fmt, difficulty, prompt, answer, spoken, payload_kwargs, supports=None):
    if supports is None:
        supports = ["visual"]
    return {
        "id": id_,
        "unit": unit,
        "skill": skill,
        "format": fmt,
        "difficulty": difficulty,
        "prompt": prompt,
        "answer": str(answer),
        "supports": supports,
        "payload": make_payload(**payload_kwargs),
        "spokenForm": spoken,
    }

# Word problem contexts
ANIMAL_CONTEXTS = [
    ("cats", "playing"), ("dogs", "running"), ("birds", "singing"),
    ("fish", "swimming"), ("rabbits", "hopping"), ("frogs", "jumping"),
    ("butterflies", "flying"), ("ducks", "waddling"), ("turtles", "crawling"),
    ("horses", "galloping"), ("penguins", "sliding"), ("pandas", "eating"),
]
FRUIT_CONTEXTS = [
    ("apples", "picking"), ("oranges", "peeling"), ("bananas", "eating"),
    ("strawberries", "collecting"), ("grapes", "sharing"), ("cherries", "counting"),
    ("pears", "sorting"), ("mangoes", "slicing"), ("watermelons", "growing"),
    ("peaches", "washing"), ("lemons", "squeezing"), ("blueberries", "gathering"),
]
OBJECT_CONTEXTS = [
    ("crayons", "drawing"), ("stickers", "collecting"), ("marbles", "rolling"),
    ("toy cars", "racing"), ("blocks", "stacking"), ("books", "reading"),
    ("balloons", "popping"), ("cookies", "baking"), ("stars", "counting"),
    ("shells", "finding"), ("coins", "saving"), ("buttons", "sorting"),
    ("pencils", "sharpening"), ("flowers", "planting"), ("balls", "bouncing"),
    ("puzzles", "solving"), ("stamps", "collecting"), ("beads", "stringing"),
    ("cards", "dealing"), ("ribbons", "cutting"), ("leaves", "raking"),
]

ALL_CONTEXTS = ANIMAL_CONTEXTS + FRUIT_CONTEXTS + OBJECT_CONTEXTS

def get_context(idx):
    """Get a unique context by index."""
    return ALL_CONTEXTS[idx % len(ALL_CONTEXTS)]


# ──────────────────────────────────────────────
# Generator functions for each unit
# ──────────────────────────────────────────────

def gen_kCountObjects(start_idx=6):
    """Count objects 1-10. Already has 5 templates (cnt-01 to cnt-05)."""
    templates = []
    objects = ["stars", "hearts", "circles", "triangles", "squares",
               "flowers", "butterflies", "fish", "birds", "apples",
               "cookies", "balls", "blocks", "bells", "dots",
               "ladybugs", "acorns", "raindrops", "mushrooms", "leaves",
               "snails", "bees", "kites", "clouds", "shells"]
    for i, obj in enumerate(objects):
        idx = start_idx + i
        target = (i % 10) + 1  # 1 to 10
        diff = 1 if target <= 5 else 2 if target <= 8 else 3
        prompt = f"Count the {obj}. How many are there?"
        spoken = f"Count the {obj}. How many are there?"
        templates.append(make_template(
            f"cnt-{idx:03d}", "kCountObjects", "count_objects_10", "countAndMatch",
            diff, prompt, target, spoken,
            {"target": target},
            supports=["counters"]
        ))
    return templates

def gen_kComposeDecompose(start_idx=6):
    """Number bonds to 10. Already has 5 templates."""
    templates = []
    pairs = []
    for a in range(0, 11):
        b = 10 - a
        pairs.append((a, b))
    # Remove pairs already used (3+7, 4+6, 5+5, 2+8, 1+9)
    used = {(3,7),(4,6),(5,5),(2,8),(1,9)}
    pairs = [(a,b) for a,b in pairs if (a,b) not in used and (b,a) not in used]

    idx = start_idx
    # Missing right side
    for a, b in pairs:
        prompt = f"{a} and ? make 10. What is ?"
        spoken = f"{a} and what number make 10?"
        templates.append(make_template(
            f"bnd-{idx:03d}", "kComposeDecompose", "number_bond_10", "numberBond",
            1, prompt, b, spoken,
            {"left": a, "target": 10},
            supports=["tenFrame"]
        ))
        idx += 1

    # Missing left side, different combos
    combos_left = [(7,3),(6,4),(8,2),(9,1),(3,7),(4,6),(2,8),(1,9),(0,10),(10,0)]
    for a, b in combos_left:
        if idx - start_idx >= 25:
            break
        prompt = f"? and {a} make 10. What is ?"
        spoken = f"What number and {a} make 10?"
        templates.append(make_template(
            f"bnd-{idx:03d}", "kComposeDecompose", "number_bond_10", "numberBond",
            2 if a >= 5 else 1, prompt, b, spoken,
            {"right": a, "target": 10},
            supports=["tenFrame"]
        ))
        idx += 1

    # Bonds to other totals (5, 6, 7, 8, 9)
    for total in [5, 6, 7, 8, 9]:
        for a in range(0, total + 1):
            if idx - start_idx >= 25:
                break
            b = total - a
            prompt = f"{a} + ? = {total}"
            spoken = f"{a} plus what equals {total}?"
            templates.append(make_template(
                f"bnd-{idx:03d}", "kComposeDecompose", "number_bond_10", "numberBond",
                1 if total <= 6 else 2, prompt, b, spoken,
                {"left": a, "target": total},
                supports=["tenFrame"]
            ))
            idx += 1
    return templates[:25]

def gen_kAddWithin5(start_idx=6):
    """Addition within 5. Already has 5 templates."""
    templates = []
    # All unique pairs where a+b <= 5
    problems = []
    for a in range(0, 6):
        for b in range(0, 6):
            if a + b <= 5 and (a, b) not in [(2,1),(1,3),(0,4),(3,2),(4,1)]:
                problems.append((a, b))

    idx = start_idx
    contexts = list(ALL_CONTEXTS)
    for i, (a, b) in enumerate(problems):
        if idx - start_idx >= 15:
            break
        s = a + b
        ctx_name, ctx_verb = contexts[i % len(contexts)]
        prompt = f"You see {a} {ctx_name} and {b} more come. How many {ctx_name} now?"
        spoken = f"You see {a} {ctx_name} and {b} more come. How many {ctx_name} now?"
        templates.append(make_template(
            f"add5-{idx:03d}", "kAddWithin5", "add_within_5", "additionStory",
            1, prompt, s, spoken,
            {"left": a, "right": b, "target": s},
            supports=["counters"]
        ))
        idx += 1

    # Bare equation style
    for a in range(0, 6):
        for b in range(0, 6):
            if a + b <= 5 and idx - start_idx < 25:
                prompt = f"What is {a} + {b}?"
                if any(t["prompt"] == prompt for t in templates):
                    continue
                spoken = f"What is {a} plus {b}?"
                templates.append(make_template(
                    f"add5-{idx:03d}", "kAddWithin5", "add_within_5", "additionStory",
                    1, prompt, a + b, spoken,
                    {"left": a, "right": b, "target": a + b},
                    supports=["counters"]
                ))
                idx += 1
    return templates[:25]

def gen_kAddWithin10(start_idx=6):
    """Addition within 10. Already has 5 templates."""
    templates = []
    # Avoid duplicates with existing: (4,3), (5,2), (3,6), (7,2), (6,3)
    existing = {(4,3),(5,2),(3,6),(7,2),(6,3)}
    problems = []
    for a in range(1, 10):
        for b in range(1, 10):
            if a + b <= 10 and (a, b) not in existing:
                problems.append((a, b))

    random.seed(42)
    random.shuffle(problems)
    idx = start_idx
    contexts = list(ALL_CONTEXTS)
    # Word problems
    for i in range(min(12, len(problems))):
        a, b = problems[i]
        s = a + b
        ctx_name, _ = contexts[i % len(contexts)]
        diff = 1 if s <= 5 else 2 if s <= 8 else 3
        prompt = f"There are {a} {ctx_name}. {b} more arrive. How many in all?"
        spoken = f"There are {a} {ctx_name}. {b} more arrive. How many in all?"
        templates.append(make_template(
            f"add10-{idx:03d}", "kAddWithin10", "add_within_10", "additionStory",
            diff, prompt, s, spoken,
            {"left": a, "right": b, "target": s},
            supports=["counters"]
        ))
        idx += 1

    # Equation problems
    for i in range(12, min(25, len(problems))):
        a, b = problems[i]
        s = a + b
        diff = 1 if s <= 5 else 2 if s <= 8 else 3
        prompt = f"{a} + {b} = ?"
        spoken = f"What is {a} plus {b}?"
        templates.append(make_template(
            f"add10-{idx:03d}", "kAddWithin10", "add_within_10", "additionStory",
            diff, prompt, s, spoken,
            {"left": a, "right": b, "target": s},
            supports=["counters"]
        ))
        idx += 1
    return templates[:25]

def gen_g1AddWithin20(start_idx=6):
    """Addition within 20. Already has 5 templates."""
    templates = []
    existing = {(8,5),(9,4),(7,6),(6,8),(5,9)}
    problems = []
    for a in range(2, 15):
        for b in range(2, 15):
            if 11 <= a + b <= 20 and (a, b) not in existing:
                problems.append((a, b))

    random.seed(43)
    random.shuffle(problems)
    idx = start_idx
    contexts = list(ALL_CONTEXTS)
    for i in range(min(13, len(problems))):
        a, b = problems[i]
        s = a + b
        ctx_name, _ = contexts[i % len(contexts)]
        diff = 1 if s <= 14 else 2 if s <= 17 else 3
        prompt = f"A child has {a} {ctx_name} and finds {b} more. How many total?"
        spoken = f"A child has {a} {ctx_name} and finds {b} more. How many total?"
        templates.append(make_template(
            f"add20-{idx:03d}", "g1AddWithin20", "add_within_20", "additionStory",
            diff, prompt, s, spoken,
            {"left": a, "right": b, "target": s},
            supports=["numberLine"]
        ))
        idx += 1
    for i in range(13, min(25, len(problems))):
        a, b = problems[i]
        s = a + b
        diff = 1 if s <= 14 else 2 if s <= 17 else 3
        prompt = f"{a} + {b} = ?"
        spoken = f"What is {a} plus {b}?"
        templates.append(make_template(
            f"add20-{idx:03d}", "g1AddWithin20", "add_within_20", "additionStory",
            diff, prompt, s, spoken,
            {"left": a, "right": b, "target": s},
            supports=["numberLine"]
        ))
        idx += 1
    return templates[:25]

def gen_g1FactFamilies(start_idx=6):
    """Fact families. Already has 5 templates."""
    templates = []
    idx = start_idx
    # a + ? = total, ? + b = total, total - a = ?, total - ? = b
    combos = []
    for total in range(5, 19):
        for a in range(1, total):
            b = total - a
            combos.append((a, b, total))

    random.seed(44)
    random.shuffle(combos)

    existing_prompts = {"6 + ? = 9", "? + 4 = 7", "8 - ? = 5", "? + 7 = 12", "11 - ? = 6"}
    seen = set()
    for a, b, total in combos:
        if idx - start_idx >= 25:
            break
        # Vary format
        fmt_choice = (idx - start_idx) % 4
        if fmt_choice == 0:
            prompt = f"{a} + ? = {total}"
            spoken = f"{a} plus what equals {total}?"
            answer = b
            payload = {"left": a, "target": total}
        elif fmt_choice == 1:
            prompt = f"? + {b} = {total}"
            spoken = f"What plus {b} equals {total}?"
            answer = a
            payload = {"right": b, "target": total}
        elif fmt_choice == 2:
            prompt = f"{total} - {a} = ?"
            spoken = f"What is {total} minus {a}?"
            answer = b
            payload = {"minuend": total, "subtrahend": a, "target": b}
        else:
            prompt = f"{total} - ? = {b}"
            spoken = f"{total} minus what equals {b}?"
            answer = a
            payload = {"minuend": total, "target": b}

        if prompt in existing_prompts or prompt in seen:
            continue
        seen.add(prompt)
        diff = 1 if total <= 10 else 2 if total <= 15 else 3
        templates.append(make_template(
            f"fact-{idx:03d}", "g1FactFamilies", "fact_family", "factFamily",
            diff, prompt, answer, spoken,
            payload,
            supports=["numberLine"]
        ))
        idx += 1
    return templates[:25]

def gen_g2AddWithin100(start_idx=6):
    """Add two-digit numbers within 100. Already has 5 templates."""
    templates = []
    existing = {(23,14),(31,25),(42,33),(15,24),(51,36)}
    idx = start_idx
    contexts = list(ALL_CONTEXTS)
    problems = []
    random.seed(45)
    for _ in range(100):
        a = random.randint(11, 70)
        b = random.randint(11, 99 - a)
        if (a, b) not in existing and a + b <= 99:
            problems.append((a, b))
    # deduplicate
    seen = set()
    unique = []
    for p in problems:
        if p not in seen:
            seen.add(p)
            unique.append(p)
    problems = unique

    for i in range(min(12, len(problems))):
        a, b = problems[i]
        s = a + b
        ctx_name, _ = contexts[i % len(contexts)]
        diff = 1 if s <= 50 else 2 if s <= 80 else 3
        prompt = f"A farmer has {a} {ctx_name} and gets {b} more. How many now?"
        spoken = f"A farmer has {a} {ctx_name} and gets {b} more. How many now?"
        templates.append(make_template(
            f"a2d-{idx:03d}", "g2AddWithin100", "add_2digit", "addTwoDigit",
            diff, prompt, s, spoken,
            {"left": a, "right": b, "target": s},
            supports=["placeValueMat"]
        ))
        idx += 1
    for i in range(12, min(25, len(problems))):
        a, b = problems[i]
        s = a + b
        diff = 1 if s <= 50 else 2 if s <= 80 else 3
        prompt = f"{a} + {b} = ?"
        spoken = f"What is {a} plus {b}?"
        templates.append(make_template(
            f"a2d-{idx:03d}", "g2AddWithin100", "add_2digit", "addTwoDigit",
            diff, prompt, s, spoken,
            {"left": a, "right": b, "target": s},
            supports=["placeValueMat"]
        ))
        idx += 1
    return templates[:25]

def gen_g2SubWithin100(start_idx=6):
    """Subtract two-digit numbers within 100. Already has 5 templates."""
    templates = []
    existing = {(45,21),(67,34),(58,23),(73,41),(86,52)}
    idx = start_idx
    contexts = list(ALL_CONTEXTS)
    problems = []
    random.seed(46)
    for _ in range(100):
        a = random.randint(20, 99)
        b = random.randint(10, a - 1)
        if (a, b) not in existing and a - b > 0:
            problems.append((a, b))
    seen = set()
    unique = []
    for p in problems:
        if p not in seen:
            seen.add(p)
            unique.append(p)
    problems = unique

    for i in range(min(12, len(problems))):
        a, b = problems[i]
        d = a - b
        ctx_name, _ = contexts[i % len(contexts)]
        diff = 1 if a <= 50 else 2 if a <= 80 else 3
        prompt = f"There are {a} {ctx_name}. {b} leave. How many remain?"
        spoken = f"There are {a} {ctx_name}. {b} leave. How many remain?"
        templates.append(make_template(
            f"s2d-{idx:03d}", "g2SubWithin100", "sub_2digit", "subTwoDigit",
            diff, prompt, d, spoken,
            {"minuend": a, "subtrahend": b, "target": d},
            supports=["placeValueMat"]
        ))
        idx += 1
    for i in range(12, min(25, len(problems))):
        a, b = problems[i]
        d = a - b
        diff = 1 if a <= 50 else 2 if a <= 80 else 3
        prompt = f"{a} - {b} = ?"
        spoken = f"What is {a} minus {b}?"
        templates.append(make_template(
            f"s2d-{idx:03d}", "g2SubWithin100", "sub_2digit", "subTwoDigit",
            diff, prompt, d, spoken,
            {"minuend": a, "subtrahend": b, "target": d},
            supports=["placeValueMat"]
        ))
        idx += 1
    return templates[:25]


# ──────────────────────────────────────────────
# Generators for 22 NEW units
# ──────────────────────────────────────────────

def gen_kCompareGroups():
    templates = []
    idx = 1
    objects = ["circles", "stars", "hearts", "squares", "triangles",
               "dots", "flowers", "birds", "fish", "butterflies",
               "apples", "oranges", "cookies", "toys", "balloons",
               "bees", "leaves", "shells", "clouds", "mushrooms",
               "acorns", "feathers", "pebbles", "beads", "gems",
               "buttons", "marbles", "stickers", "bells", "ribbons",
               "coins", "stamps", "cherries", "grapes", "berries"]
    seen = set()
    for i in range(35):
        obj = objects[i % len(objects)]
        a = random.randint(1, 10)
        b = random.randint(1, 10)
        while (a, b, obj) in seen:
            a = random.randint(1, 10)
            b = random.randint(1, 10)
        seen.add((a, b, obj))

        if i % 3 == 0:
            question = "more"
            if a > b:
                answer = f"{a} {obj}"
            elif b > a:
                answer = f"{b} {obj}"
            else:
                answer = "same"
            prompt = f"Which group has more? {a} {obj} or {b} {obj}?"
            spoken = f"Which group has more? {a} {obj} or {b} {obj}?"
        elif i % 3 == 1:
            question = "fewer"
            if a < b:
                answer = f"{a} {obj}"
            elif b < a:
                answer = f"{b} {obj}"
            else:
                answer = "same"
            prompt = f"Which group has fewer? {a} {obj} or {b} {obj}?"
            spoken = f"Which group has fewer? {a} {obj} or {b} {obj}?"
        else:
            diff_val = abs(a - b)
            answer = str(diff_val)
            prompt = f"How many more? {max(a,b)} {obj} vs {min(a,b)} {obj}."
            spoken = f"How many more? {max(a,b)} {obj} versus {min(a,b)} {obj}."

        diff = 1 if max(a, b) <= 5 else 2 if max(a, b) <= 8 else 3
        templates.append(make_template(
            f"cmpg-{idx:03d}", "kCompareGroups", "compare_groups", "groupComparison",
            diff, prompt, answer, spoken,
            {"left": a, "right": b},
            supports=["counters"]
        ))
        idx += 1
    return templates

def gen_kShapeAttributes():
    templates = []
    shapes = [
        ("circle", 0, 0), ("triangle", 3, 3), ("square", 4, 4),
        ("rectangle", 4, 4), ("pentagon", 5, 5), ("hexagon", 6, 6),
    ]
    idx = 1
    # "I have N sides and N corners. What shape am I?"
    for shape_name, sides, corners in shapes:
        if sides > 0:
            prompt = f"I have {sides} sides and {corners} corners. What shape am I?"
            spoken = f"I have {sides} sides and {corners} corners. What shape am I?"
            templates.append(make_template(
                f"shp-{idx:03d}", "kShapeAttributes", "shape_classify", "shapeClassification",
                1, prompt, shape_name, spoken,
                {"sides": sides, "corners": corners, "shapeName": shape_name},
                supports=["visual"]
            ))
            idx += 1
        else:
            prompt = f"I have no corners and no straight sides. What shape am I?"
            spoken = f"I have no corners and no straight sides. What shape am I?"
            templates.append(make_template(
                f"shp-{idx:03d}", "kShapeAttributes", "shape_classify", "shapeClassification",
                1, prompt, shape_name, spoken,
                {"sides": 0, "corners": 0, "shapeName": shape_name},
                supports=["visual"]
            ))
            idx += 1

    # "How many sides does a ___ have?"
    for shape_name, sides, corners in shapes:
        prompt = f"How many sides does a {shape_name} have?"
        spoken = f"How many sides does a {shape_name} have?"
        templates.append(make_template(
            f"shp-{idx:03d}", "kShapeAttributes", "shape_classify", "shapeClassification",
            1, prompt, sides, spoken,
            {"sides": sides, "corners": corners, "shapeName": shape_name},
            supports=["visual"]
        ))
        idx += 1

    # "How many corners does a ___ have?"
    for shape_name, sides, corners in shapes:
        prompt = f"How many corners does a {shape_name} have?"
        spoken = f"How many corners does a {shape_name} have?"
        templates.append(make_template(
            f"shp-{idx:03d}", "kShapeAttributes", "shape_classify", "shapeClassification",
            2, prompt, corners, spoken,
            {"sides": sides, "corners": corners, "shapeName": shape_name},
            supports=["visual"]
        ))
        idx += 1

    # "True or false" style: "A square has 3 sides."
    tf_qs = [
        ("A triangle has 4 sides.", "false", "triangle", 3, 3),
        ("A square has 4 corners.", "true", "square", 4, 4),
        ("A circle has 0 sides.", "true", "circle", 0, 0),
        ("A hexagon has 5 sides.", "false", "hexagon", 6, 6),
        ("A rectangle has 4 sides.", "true", "rectangle", 4, 4),
        ("A pentagon has 5 corners.", "true", "pentagon", 5, 5),
        ("A triangle has 3 corners.", "true", "triangle", 3, 3),
        ("A hexagon has 6 corners.", "true", "hexagon", 6, 6),
        ("A circle has 1 corner.", "false", "circle", 0, 0),
        ("A square has 5 sides.", "false", "square", 4, 4),
        ("A pentagon has 4 sides.", "false", "pentagon", 5, 5),
        ("A rectangle has 2 corners.", "false", "rectangle", 4, 4),
    ]
    for q, ans, sn, si, co in tf_qs:
        prompt = f"True or false: {q}"
        spoken = f"True or false: {q}"
        templates.append(make_template(
            f"shp-{idx:03d}", "kShapeAttributes", "shape_classify", "shapeClassification",
            2, prompt, ans, spoken,
            {"sides": si, "corners": co, "shapeName": sn},
            supports=["visual"]
        ))
        idx += 1
    return templates[:35]

def gen_g1AddSub100():
    templates = []
    idx = 1
    random.seed(50)
    contexts = list(ALL_CONTEXTS)
    seen = set()
    # Addition problems
    for i in range(18):
        a = random.randint(10, 70)
        b = random.randint(5, 99 - a)
        while (a, b, '+') in seen:
            a = random.randint(10, 70)
            b = random.randint(5, 99 - a)
        seen.add((a, b, '+'))
        s = a + b
        diff = 1 if s <= 50 else 2 if s <= 80 else 3
        if i < 9:
            ctx_name, _ = contexts[i % len(contexts)]
            prompt = f"A box has {a} {ctx_name}. You add {b} more. How many?"
            spoken = prompt
        else:
            prompt = f"{a} + {b} = ?"
            spoken = f"What is {a} plus {b}?"
        templates.append(make_template(
            f"as100-{idx:03d}", "g1AddSub100", "add_sub_100", "additionStory",
            diff, prompt, s, spoken,
            {"left": a, "right": b, "target": s},
            supports=["numberLine"]
        ))
        idx += 1

    # Subtraction problems
    for i in range(17):
        a = random.randint(20, 99)
        b = random.randint(5, a - 1)
        while (a, b, '-') in seen:
            a = random.randint(20, 99)
            b = random.randint(5, a - 1)
        seen.add((a, b, '-'))
        d = a - b
        diff = 1 if a <= 50 else 2 if a <= 80 else 3
        if i < 8:
            ctx_name, _ = contexts[(i + 9) % len(contexts)]
            prompt = f"You have {a} {ctx_name}. You give away {b}. How many left?"
            spoken = prompt
        else:
            prompt = f"{a} - {b} = ?"
            spoken = f"What is {a} minus {b}?"
        templates.append(make_template(
            f"as100-{idx:03d}", "g1AddSub100", "add_sub_100", "additionStory",
            diff, prompt, d, spoken,
            {"left": a, "right": b, "target": d, "minuend": a, "subtrahend": b},
            supports=["numberLine"]
        ))
        idx += 1
    return templates

def gen_g1MeasureLength():
    templates = []
    idx = 1
    objects_to_measure = [
        "pencil", "crayon", "ribbon", "stick", "string",
        "bookmark", "leaf", "caterpillar", "worm", "feather",
        "paper clip chain", "eraser", "shoe", "hand span", "spoon",
        "straw", "ruler segment", "yarn", "twig", "finger",
        "key", "brush", "comb", "fork", "marker",
        "tape strip", "noodle", "bread stick", "carrot", "celery",
        "pipe cleaner", "shoelace", "candy bar", "glue stick", "clothespin",
    ]
    for i, obj in enumerate(objects_to_measure[:35]):
        target = random.randint(2, 12)
        diff = 1 if target <= 5 else 2 if target <= 9 else 3
        if i % 3 == 0:
            prompt = f"The {obj} is how many units long?"
            spoken = f"The {obj} is how many units long?"
        elif i % 3 == 1:
            prompt = f"Measure the {obj}. How many paper clips long is it?"
            spoken = f"Measure the {obj}. How many paper clips long is it?"
        else:
            prompt = f"How many cubes long is the {obj}?"
            spoken = f"How many cubes long is the {obj}?"
        templates.append(make_template(
            f"mlen-{idx:03d}", "g1MeasureLength", "measure_length", "measureLength",
            diff, prompt, target, spoken,
            {"target": target},
            supports=["visual"]
        ))
        idx += 1
    return templates

def gen_g2PlaceValue1000():
    templates = []
    idx = 1
    random.seed(51)

    # "What digit is in the hundreds/tens/ones place?"
    for i in range(15):
        n = random.randint(100, 999)
        h = n // 100
        t = (n // 10) % 10
        o = n % 10
        place_choice = i % 3
        if place_choice == 0:
            prompt = f"What digit is in the hundreds place of {n}?"
            spoken = prompt
            answer = h
        elif place_choice == 1:
            prompt = f"What digit is in the tens place of {n}?"
            spoken = prompt
            answer = t
        else:
            prompt = f"What digit is in the ones place of {n}?"
            spoken = prompt
            answer = o
        templates.append(make_template(
            f"pv1k-{idx:03d}", "g2PlaceValue1000", "place_value_1000", "teenPlaceValue",
            2, prompt, answer, spoken,
            {"target": n, "tens": t, "ones": o},
            supports=["placeValueMat"]
        ))
        idx += 1

    # "__ hundreds + __ tens + __ ones = ?"
    for i in range(10):
        h = random.randint(1, 9)
        t = random.randint(0, 9)
        o = random.randint(0, 9)
        n = h * 100 + t * 10 + o
        prompt = f"{h} hundreds + {t} tens + {o} ones = ?"
        spoken = f"{h} hundreds plus {t} tens plus {o} ones equals what?"
        templates.append(make_template(
            f"pv1k-{idx:03d}", "g2PlaceValue1000", "place_value_1000", "teenPlaceValue",
            2, prompt, n, spoken,
            {"target": n, "tens": t, "ones": o},
            supports=["placeValueMat"]
        ))
        idx += 1

    # "What is the value of the digit __ in __?"
    for i in range(10):
        n = random.randint(100, 999)
        h = n // 100
        t = (n // 10) % 10
        o = n % 10
        place_choice = i % 3
        if place_choice == 0:
            prompt = f"What is the value of the digit {h} in {n}?"
            answer = h * 100
            spoken = prompt
        elif place_choice == 1:
            prompt = f"What is the value of the digit {t} in {n}?"
            answer = t * 10
            spoken = prompt
        else:
            prompt = f"What is the value of the digit {o} in {n}?"
            answer = o
            spoken = prompt
        templates.append(make_template(
            f"pv1k-{idx:03d}", "g2PlaceValue1000", "place_value_1000", "teenPlaceValue",
            3, prompt, answer, spoken,
            {"target": n, "tens": t, "ones": o},
            supports=["placeValueMat"]
        ))
        idx += 1
    return templates[:35]

def gen_g2AddSubRegroup():
    templates = []
    idx = 1
    random.seed(52)
    contexts = list(ALL_CONTEXTS)
    seen = set()

    # Addition requiring regrouping (ones sum >= 10)
    for i in range(18):
        while True:
            a = random.randint(15, 70)
            b = random.randint(15, 99 - a)
            ones_sum = (a % 10) + (b % 10)
            if ones_sum >= 10 and (a, b) not in seen:
                break
        seen.add((a, b))
        s = a + b
        diff = 2 if s <= 60 else 3
        if i < 9:
            ctx_name, _ = contexts[i % len(contexts)]
            prompt = f"A store has {a} {ctx_name} and receives {b} more. How many total?"
            spoken = prompt
        else:
            prompt = f"{a} + {b} = ?"
            spoken = f"What is {a} plus {b}?"
        templates.append(make_template(
            f"asrg-{idx:03d}", "g2AddSubRegroup", "add_sub_regroup", "addTwoDigit",
            diff, prompt, s, spoken,
            {"left": a, "right": b, "target": s},
            supports=["placeValueMat"]
        ))
        idx += 1

    # Subtraction requiring regrouping (ones of minuend < ones of subtrahend)
    for i in range(17):
        while True:
            a = random.randint(30, 99)
            b = random.randint(10, a - 1)
            if (a % 10) < (b % 10) and (a, b) not in seen:
                break
        seen.add((a, b))
        d = a - b
        diff = 2 if a <= 60 else 3
        if i < 8:
            ctx_name, _ = contexts[(i + 9) % len(contexts)]
            prompt = f"There were {a} {ctx_name}. {b} were taken. How many remain?"
            spoken = prompt
        else:
            prompt = f"{a} - {b} = ?"
            spoken = f"What is {a} minus {b}?"
        templates.append(make_template(
            f"asrg-{idx:03d}", "g2AddSubRegroup", "add_sub_regroup", "addTwoDigit",
            diff, prompt, d, spoken,
            {"minuend": a, "subtrahend": b, "left": a, "right": b, "target": d},
            supports=["placeValueMat"]
        ))
        idx += 1
    return templates

def gen_g2EqualGroups():
    templates = []
    idx = 1
    contexts = list(ALL_CONTEXTS)
    seen = set()
    random.seed(53)

    for i in range(35):
        groups = random.randint(2, 10)
        per_group = random.randint(2, 10)
        while (groups, per_group) in seen:
            groups = random.randint(2, 10)
            per_group = random.randint(2, 10)
        seen.add((groups, per_group))
        total = groups * per_group
        diff = 1 if total <= 20 else 2 if total <= 50 else 3
        ctx_name, _ = contexts[i % len(contexts)]

        if i % 3 == 0:
            prompt = f"{groups} groups of {per_group} {ctx_name}. How many in all?"
            spoken = prompt
        elif i % 3 == 1:
            prompt = f"There are {groups} bags with {per_group} {ctx_name} each. How many total?"
            spoken = prompt
        else:
            prompt = f"{groups} × {per_group} = ?"
            spoken = f"What is {groups} times {per_group}?"

        templates.append(make_template(
            f"eqgr-{idx:03d}", "g2EqualGroups", "equal_groups", "multiplicationArray",
            diff, prompt, total, spoken,
            {"multiplicand": per_group, "multiplier": groups, "target": total},
            supports=["arrayGrid"]
        ))
        idx += 1
    return templates

def gen_g2TimeMoney():
    templates = []
    idx = 1

    # Time: "What time does the clock show?"
    for h in range(1, 13):
        for m in [0, 30]:
            if idx > 15:
                break
            m_str = f"{m:02d}"
            time_str = f"{h}:{m_str}"
            if m == 0:
                spoken_time = f"{h} o'clock"
            else:
                spoken_time = f"{h} thirty"
            prompt = f"The clock shows {time_str}. What time is it?"
            spoken = f"The clock shows {spoken_time}. What time is it?"
            templates.append(make_template(
                f"tm-{idx:03d}", "g2TimeMoney", "time_money", "timeMoney",
                1, prompt, time_str, spoken,
                {"hours": h, "minutes": m},
                supports=["visual"]
            ))
            idx += 1

    # Time with quarter hours
    for h in [2, 4, 6, 8, 10, 12]:
        for m in [15, 45]:
            if idx > 22:
                break
            time_str = f"{h}:{m:02d}"
            prompt = f"What time does the clock show? It reads {time_str}."
            spoken = f"What time does the clock show? It reads {h} {m}."
            templates.append(make_template(
                f"tm-{idx:03d}", "g2TimeMoney", "time_money", "timeMoney",
                2, prompt, time_str, spoken,
                {"hours": h, "minutes": m},
                supports=["visual"]
            ))
            idx += 1

    # Money: counting coins
    coin_problems = [
        (25, "1 quarter"),
        (50, "2 quarters"),
        (10, "1 dime"),
        (35, "1 quarter and 1 dime"),
        (60, "2 quarters and 1 dime"),
        (15, "1 dime and 1 nickel"),
        (30, "1 quarter and 1 nickel"),
        (75, "3 quarters"),
        (40, "1 quarter, 1 dime, and 1 nickel"),
        (55, "2 quarters and 1 nickel"),
        (20, "2 dimes"),
        (5, "1 nickel"),
        (45, "1 quarter and 2 dimes"),
    ]
    for cents, coins_desc in coin_problems:
        if idx > 35:
            break
        prompt = f"You have {coins_desc}. How many cents is that?"
        spoken = prompt
        templates.append(make_template(
            f"tm-{idx:03d}", "g2TimeMoney", "time_money", "timeMoney",
            2 if cents <= 50 else 3, prompt, cents, spoken,
            {"cents": cents},
            supports=["visual"]
        ))
        idx += 1
    return templates[:35]

def gen_g2DataIntro():
    templates = []
    idx = 1
    # Bar graph reading questions
    datasets = [
        (["Red", "Blue", "Green"], [5, 3, 7], "favorite colors"),
        (["Cat", "Dog", "Fish"], [8, 6, 2], "class pets"),
        (["Apple", "Banana", "Orange"], [4, 9, 3], "fruit picked"),
        (["Soccer", "Baseball", "Tennis"], [7, 5, 4], "sports played"),
        (["Spring", "Summer", "Fall"], [3, 8, 6], "favorite seasons"),
        (["Pizza", "Tacos", "Burgers"], [9, 4, 6], "lunch votes"),
        (["Math", "Reading", "Art"], [5, 7, 8], "subject votes"),
        (["Bike", "Scooter", "Skate"], [6, 3, 4], "ways to travel"),
        (["Lions", "Tigers", "Bears"], [2, 5, 3], "zoo animals seen"),
        (["Rain", "Sun", "Cloud"], [4, 7, 3], "weather days"),
    ]

    for labels, values, topic in datasets:
        # "Which has the most?"
        max_idx = values.index(max(values))
        prompt = f"The bar graph shows {topic}. Which bar is tallest?"
        spoken = prompt
        templates.append(make_template(
            f"data-{idx:03d}", "g2DataIntro", "data_intro", "dataPlot",
            1, prompt, labels[max_idx], spoken,
            {"barValues": values, "barLabels": labels, "target": max(values)},
            supports=["visual"]
        ))
        idx += 1

        # "How many for X?"
        q_idx = idx % len(labels)
        prompt = f"The bar graph shows {topic}. How many for {labels[q_idx % len(labels)]}?"
        spoken = prompt
        templates.append(make_template(
            f"data-{idx:03d}", "g2DataIntro", "data_intro", "dataPlot",
            1, prompt, values[q_idx % len(labels)], spoken,
            {"barValues": values, "barLabels": labels, "target": values[q_idx % len(labels)]},
            supports=["visual"]
        ))
        idx += 1

        # "How many more X than Y?"
        if len(labels) >= 2:
            a_i, b_i = 0, 1
            diff_val = abs(values[a_i] - values[b_i])
            prompt = f"The bar graph shows {topic}. How many more {labels[a_i]} than {labels[b_i]}?"
            spoken = prompt
            templates.append(make_template(
                f"data-{idx:03d}", "g2DataIntro", "data_intro", "dataPlot",
                2, prompt, diff_val, spoken,
                {"barValues": values, "barLabels": labels, "target": diff_val},
                supports=["visual"]
            ))
            idx += 1

    # Total questions
    for labels, values, topic in datasets[:5]:
        total = sum(values)
        prompt = f"The bar graph shows {topic}. What is the total?"
        spoken = prompt
        templates.append(make_template(
            f"data-{idx:03d}", "g2DataIntro", "data_intro", "dataPlot",
            2, prompt, total, spoken,
            {"barValues": values, "barLabels": labels, "target": total},
            supports=["visual"]
        ))
        idx += 1
    return templates[:35]

def gen_g3DivMeaning():
    templates = []
    idx = 1
    random.seed(54)
    contexts = list(ALL_CONTEXTS)

    # Division facts
    seen = set()
    for i in range(35):
        divisor = random.randint(2, 10)
        quotient = random.randint(1, 10)
        dividend = divisor * quotient
        while (dividend, divisor) in seen:
            divisor = random.randint(2, 10)
            quotient = random.randint(1, 10)
            dividend = divisor * quotient
        seen.add((dividend, divisor))
        diff = 1 if dividend <= 20 else 2 if dividend <= 50 else 3
        ctx_name, _ = contexts[i % len(contexts)]

        if i % 3 == 0:
            prompt = f"{dividend} ÷ {divisor} = ?"
            spoken = f"What is {dividend} divided by {divisor}?"
        elif i % 3 == 1:
            prompt = f"Share {dividend} {ctx_name} equally among {divisor} friends. How many each?"
            spoken = prompt
        else:
            prompt = f"{dividend} {ctx_name} in groups of {divisor}. How many groups?"
            spoken = prompt

        templates.append(make_template(
            f"div-{idx:03d}", "g3DivMeaning", "div_meaning", "divisionGroups",
            diff, prompt, quotient, spoken,
            {"dividend": dividend, "divisor": divisor, "target": quotient},
            supports=["arrayGrid"]
        ))
        idx += 1
    return templates

def gen_g3FractionUnit():
    templates = []
    idx = 1
    # Fraction of a whole number
    problems = []
    for denom in [2, 3, 4, 5, 6, 8, 10]:
        for numer in range(1, denom):
            for whole in range(denom, denom * 5 + 1, denom):
                result = (numer * whole) // denom
                if result == numer * whole / denom:  # clean division
                    problems.append((numer, denom, whole, result))

    random.seed(55)
    random.shuffle(problems)
    contexts = list(ALL_CONTEXTS)

    for i, (n, d, w, r) in enumerate(problems[:35]):
        diff = 1 if d <= 4 else 2 if d <= 6 else 3
        ctx_name, _ = contexts[i % len(contexts)]

        if i % 3 == 0:
            prompt = f"What is {n}/{d} of {w}?"
            num_word = {1: "one", 2: "two", 3: "three", 4: "four", 5: "five",
                       6: "six", 7: "seven", 8: "eight", 9: "nine"}
            denom_word = {2: "half", 3: "third", 4: "fourth", 5: "fifth",
                         6: "sixth", 8: "eighth", 10: "tenth"}
            nw = num_word.get(n, str(n))
            dw = denom_word.get(d, f"{d}th")
            if n > 1:
                dw += "s"
            spoken = f"What is {nw} {dw} of {w}?"
        elif i % 3 == 1:
            prompt = f"Find {n}/{d} of {w} {ctx_name}."
            spoken = prompt
        else:
            prompt = f"There are {w} {ctx_name}. What is {n}/{d} of them?"
            spoken = prompt

        templates.append(make_template(
            f"fru-{idx:03d}", "g3FractionUnit", "fraction_unit", "fractionOfWhole",
            diff, prompt, r, spoken,
            {"numeratorA": n, "denominatorA": d, "whole": w, "target": r},
            supports=["fractionStrip"]
        ))
        idx += 1
    return templates[:35]

def gen_g3FractionCompare():
    templates = []
    idx = 1
    pairs = []
    for d1 in [2, 3, 4, 5, 6, 8]:
        for n1 in range(1, d1):
            for d2 in [2, 3, 4, 5, 6, 8]:
                for n2 in range(1, d2):
                    if (n1, d1) != (n2, d2):
                        f1 = Fraction(n1, d1)
                        f2 = Fraction(n2, d2)
                        if f1 != f2:
                            pairs.append((n1, d1, n2, d2, "<" if f1 < f2 else ">"))

    random.seed(56)
    random.shuffle(pairs)
    seen = set()
    for n1, d1, n2, d2, ans in pairs:
        if len(templates) >= 35:
            break
        key = (n1, d1, n2, d2)
        if key in seen:
            continue
        seen.add(key)
        diff = 1 if d1 <= 4 and d2 <= 4 else 2 if d1 <= 6 and d2 <= 6 else 3

        if idx % 2 == 0:
            prompt = f"Compare {n1}/{d1} and {n2}/{d2}. Which is greater?"
            spoken = prompt
            answer = f"{n1}/{d1}" if ans == ">" else f"{n2}/{d2}"
        else:
            prompt = f"Which is larger: {n1}/{d1} or {n2}/{d2}?"
            spoken = prompt
            answer = f"{n1}/{d1}" if ans == ">" else f"{n2}/{d2}"

        templates.append(make_template(
            f"frcmp-{idx:03d}", "g3FractionCompare", "fraction_compare_unit", "fractionComparison",
            diff, prompt, answer, spoken,
            {"numeratorA": n1, "denominatorA": d1, "numeratorB": n2, "denominatorB": d2},
            supports=["fractionStrip"]
        ))
        idx += 1
    return templates[:35]

def gen_g3AreaConcept():
    templates = []
    idx = 1
    contexts_area = [
        "garden", "rug", "tile floor", "poster", "window",
        "table top", "wall", "flag", "book cover", "screen",
        "blanket", "mat", "card", "patch of grass", "sandbox",
    ]
    seen = set()
    for i in range(35):
        l = random.randint(2, 12)
        w = random.randint(2, 12)
        while (l, w) in seen:
            l = random.randint(2, 12)
            w = random.randint(2, 12)
        seen.add((l, w))
        area = l * w
        diff = 1 if area <= 20 else 2 if area <= 60 else 3
        ctx = contexts_area[i % len(contexts_area)]

        if i % 3 == 0:
            prompt = f"A {ctx} is {l} units by {w} units. What is its area?"
            spoken = prompt
        elif i % 3 == 1:
            prompt = f"Find the area: length = {l}, width = {w}."
            spoken = f"Find the area when length is {l} and width is {w}."
        else:
            prompt = f"A rectangle is {l} by {w}. What is the area in square units?"
            spoken = prompt

        templates.append(make_template(
            f"area-{idx:03d}", "g3AreaConcept", "area_concept", "areaTiling",
            diff, prompt, area, spoken,
            {"length": l, "width": w, "target": area},
            supports=["visual"]
        ))
        idx += 1
    return templates

def gen_g3MultiStep():
    templates = []
    idx = 1
    random.seed(57)
    contexts = list(ALL_CONTEXTS)

    multi_problems = []
    # Type 1: a + b - c
    for _ in range(12):
        a = random.randint(10, 50)
        b = random.randint(5, 30)
        c = random.randint(3, a + b - 1)
        if a + b - c > 0:
            multi_problems.append(("add_sub", a, b, c, a + b - c))
    # Type 2: a * b + c
    for _ in range(12):
        a = random.randint(2, 8)
        b = random.randint(2, 8)
        c = random.randint(1, 20)
        multi_problems.append(("mult_add", a, b, c, a * b + c))
    # Type 3: a * b - c
    for _ in range(11):
        a = random.randint(2, 8)
        b = random.randint(2, 8)
        c = random.randint(1, a * b - 1)
        multi_problems.append(("mult_sub", a, b, c, a * b - c))

    for i, (ptype, a, b, c, answer) in enumerate(multi_problems[:35]):
        ctx_name, _ = contexts[i % len(contexts)]
        diff = 2 if answer <= 30 else 3

        if ptype == "add_sub":
            prompt = f"You have {a} {ctx_name}. You find {b} more, then lose {c}. How many now?"
            spoken = prompt
            payload = {"left": a, "right": b, "target": answer}
        elif ptype == "mult_add":
            prompt = f"There are {a} boxes with {b} {ctx_name} each, plus {c} extra. How many total?"
            spoken = prompt
            payload = {"multiplicand": b, "multiplier": a, "target": answer}
        else:
            prompt = f"A baker makes {a} trays of {b} {ctx_name}, then sells {c}. How many left?"
            spoken = prompt
            payload = {"multiplicand": b, "multiplier": a, "target": answer}

        templates.append(make_template(
            f"mstep-{idx:03d}", "g3MultiStep", "multi_step", "additionStory",
            diff, prompt, answer, spoken,
            payload,
            supports=["visual"]
        ))
        idx += 1
    return templates[:35]

def gen_g4PlaceValueMillion():
    templates = []
    idx = 1
    random.seed(58)

    # Digit identification
    places = [
        ("ones", 1), ("tens", 10), ("hundreds", 100),
        ("thousands", 1000), ("ten-thousands", 10000),
        ("hundred-thousands", 100000),
    ]
    for i in range(12):
        n = random.randint(100000, 999999)
        place_name, place_val = places[i % len(places)]
        digit = (n // place_val) % 10
        prompt = f"What digit is in the {place_name} place of {n:,}?"
        spoken = prompt
        templates.append(make_template(
            f"pvM-{idx:03d}", "g4PlaceValueMillion", "place_value_million", "teenPlaceValue",
            2 if place_val <= 1000 else 3, prompt, digit, spoken,
            {"target": n},
            supports=["placeValueMat"]
        ))
        idx += 1

    # Value of digit
    for i in range(12):
        n = random.randint(100000, 999999)
        place_name, place_val = places[i % len(places)]
        digit = (n // place_val) % 10
        value = digit * place_val
        prompt = f"What is the value of the digit {digit} in the {place_name} place of {n:,}?"
        spoken = prompt
        templates.append(make_template(
            f"pvM-{idx:03d}", "g4PlaceValueMillion", "place_value_million", "teenPlaceValue",
            3, prompt, value, spoken,
            {"target": n},
            supports=["placeValueMat"]
        ))
        idx += 1

    # Expanded form
    for i in range(11):
        n = random.randint(10000, 999999)
        prompt = f"Write {n:,} in expanded form. What is the value of the highest digit?"
        h_digit = n // (10 ** (len(str(n)) - 1))
        h_value = h_digit * (10 ** (len(str(n)) - 1))
        spoken = prompt
        templates.append(make_template(
            f"pvM-{idx:03d}", "g4PlaceValueMillion", "place_value_million", "teenPlaceValue",
            3, prompt, h_value, spoken,
            {"target": n},
            supports=["placeValueMat"]
        ))
        idx += 1
    return templates[:35]

def gen_g4MultMultiDigit():
    templates = []
    idx = 1
    random.seed(59)
    contexts = list(ALL_CONTEXTS)
    seen = set()

    # 2-digit × 1-digit
    for i in range(20):
        a = random.randint(11, 50)
        b = random.randint(2, 9)
        while (a, b) in seen:
            a = random.randint(11, 50)
            b = random.randint(2, 9)
        seen.add((a, b))
        product = a * b
        diff = 1 if product <= 100 else 2 if product <= 200 else 3
        ctx_name, _ = contexts[i % len(contexts)]

        if i % 2 == 0:
            prompt = f"{a} × {b} = ?"
            spoken = f"What is {a} times {b}?"
        else:
            prompt = f"There are {b} boxes of {a} {ctx_name}. How many total?"
            spoken = prompt

        templates.append(make_template(
            f"mmult-{idx:03d}", "g4MultMultiDigit", "mult_multi_digit", "multiplicationArray",
            diff, prompt, product, spoken,
            {"multiplicand": a, "multiplier": b, "target": product},
            supports=["areaModel"]
        ))
        idx += 1

    # 2-digit × 2-digit
    for i in range(15):
        a = random.randint(11, 30)
        b = random.randint(11, 30)
        while (a, b) in seen:
            a = random.randint(11, 30)
            b = random.randint(11, 30)
        seen.add((a, b))
        product = a * b
        diff = 3

        if i % 2 == 0:
            prompt = f"{a} × {b} = ?"
            spoken = f"What is {a} times {b}?"
        else:
            ctx_name, _ = contexts[(i + 20) % len(contexts)]
            prompt = f"A garden has {a} rows of {b} {ctx_name}. How many in all?"
            spoken = prompt

        templates.append(make_template(
            f"mmult-{idx:03d}", "g4MultMultiDigit", "mult_multi_digit", "multiplicationArray",
            diff, prompt, product, spoken,
            {"multiplicand": a, "multiplier": b, "target": product},
            supports=["areaModel"]
        ))
        idx += 1
    return templates[:35]

def gen_g4DivPartialQuotients():
    templates = []
    idx = 1
    random.seed(60)
    contexts = list(ALL_CONTEXTS)
    seen = set()

    for i in range(35):
        divisor = random.randint(2, 9)
        quotient = random.randint(5, 30)
        dividend = divisor * quotient
        while (dividend, divisor) in seen:
            divisor = random.randint(2, 9)
            quotient = random.randint(5, 30)
            dividend = divisor * quotient
        seen.add((dividend, divisor))
        diff = 1 if dividend <= 50 else 2 if dividend <= 100 else 3
        ctx_name, _ = contexts[i % len(contexts)]

        if i % 3 == 0:
            prompt = f"{dividend} ÷ {divisor} = ?"
            spoken = f"What is {dividend} divided by {divisor}?"
        elif i % 3 == 1:
            prompt = f"Split {dividend} {ctx_name} into {divisor} equal groups. How many in each?"
            spoken = prompt
        else:
            prompt = f"How many groups of {divisor} fit into {dividend}?"
            spoken = prompt

        templates.append(make_template(
            f"dpq-{idx:03d}", "g4DivPartialQuotients", "div_partial_quot", "divisionGroups",
            diff, prompt, quotient, spoken,
            {"dividend": dividend, "divisor": divisor, "target": quotient},
            supports=["visual"]
        ))
        idx += 1
    return templates

def gen_g4FractionAddSub():
    templates = []
    idx = 1
    # Same denominator fraction addition and subtraction
    problems = []
    for d in [2, 3, 4, 5, 6, 8, 10, 12]:
        for n1 in range(1, d):
            for n2 in range(1, d):
                if n1 + n2 <= d:
                    problems.append(('+', n1, d, n2, d, n1 + n2, d))
                if n1 > n2:
                    problems.append(('-', n1, d, n2, d, n1 - n2, d))

    random.seed(61)
    random.shuffle(problems)
    for i, (op, n1, d1, n2, d2, rn, rd) in enumerate(problems[:35]):
        # Simplify result
        f = Fraction(rn, rd)
        if f.denominator == 1:
            answer = str(f.numerator)
        else:
            answer = f"{f.numerator}/{f.denominator}"

        diff = 1 if d1 <= 4 else 2 if d1 <= 8 else 3

        if op == '+':
            prompt = f"{n1}/{d1} + {n2}/{d2} = ?"
            spoken = f"What is {n1} over {d1} plus {n2} over {d2}?"
        else:
            prompt = f"{n1}/{d1} - {n2}/{d2} = ?"
            spoken = f"What is {n1} over {d1} minus {n2} over {d2}?"

        templates.append(make_template(
            f"fras-{idx:03d}", "g4FractionAddSub", "fraction_add_sub", "fractionAddSub",
            diff, prompt, answer, spoken,
            {"numeratorA": n1, "denominatorA": d1, "numeratorB": n2, "denominatorB": d2,
             "target": float(f)},
            supports=["fractionStrip"]
        ))
        idx += 1
    return templates[:35]

def gen_g4AngleMeasure():
    templates = []
    idx = 1

    # Angle identification and measurement
    angle_types = [
        (30, "acute"), (45, "acute"), (60, "acute"), (90, "right"),
        (120, "obtuse"), (135, "obtuse"), (150, "obtuse"),
        (10, "acute"), (20, "acute"), (40, "acute"), (50, "acute"),
        (70, "acute"), (80, "acute"), (100, "obtuse"), (110, "obtuse"),
        (140, "obtuse"), (160, "obtuse"), (170, "obtuse"),
    ]

    for deg, atype in angle_types:
        prompt = f"An angle measures {deg}°. Is it acute, right, or obtuse?"
        spoken = f"An angle measures {deg} degrees. Is it acute, right, or obtuse?"
        templates.append(make_template(
            f"ang-{idx:03d}", "g4AngleMeasure", "angle_measure", "angleMeasure",
            1 if deg in [90, 45, 60] else 2, prompt, atype, spoken,
            {"degrees": deg, "target": deg},
            supports=["visual"]
        ))
        idx += 1

    # Angle addition
    combos = [(30, 60), (45, 45), (90, 90), (30, 30), (60, 60),
              (45, 90), (30, 90), (60, 90), (40, 50), (20, 70),
              (35, 55), (25, 65), (15, 75), (10, 80), (50, 40)]
    for a, b in combos:
        total = a + b
        prompt = f"Two angles measure {a}° and {b}°. What is their sum?"
        spoken = f"Two angles measure {a} degrees and {b} degrees. What is their sum?"
        templates.append(make_template(
            f"ang-{idx:03d}", "g4AngleMeasure", "angle_measure", "angleMeasure",
            2 if total <= 180 else 3, prompt, total, spoken,
            {"degrees": total, "target": total},
            supports=["visual"]
        ))
        idx += 1
        if idx > 35:
            break
    return templates[:35]

def gen_g5FractionAddSubUnlike():
    templates = []
    idx = 1
    # Unlike denominator fraction add/sub
    problems = []
    denom_pairs = [(2,3),(2,4),(2,6),(3,4),(3,6),(4,6),(3,5),(2,5),(4,5),(5,6),(4,8),(3,9),(2,8),(5,10),(6,8)]
    for d1, d2 in denom_pairs:
        lcd = (d1 * d2) // math.gcd(d1, d2)
        for n1 in range(1, d1):
            for n2 in range(1, d2):
                f = Fraction(n1, d1) + Fraction(n2, d2)
                if f <= 1:
                    problems.append(('+', n1, d1, n2, d2, f))
                f2 = Fraction(n1, d1) - Fraction(n2, d2)
                if f2 > 0:
                    problems.append(('-', n1, d1, n2, d2, f2))

    random.seed(62)
    random.shuffle(problems)
    for i, (op, n1, d1, n2, d2, result) in enumerate(problems[:35]):
        if result.denominator == 1:
            answer = str(result.numerator)
        else:
            answer = f"{result.numerator}/{result.denominator}"

        diff = 2 if d1 <= 4 and d2 <= 4 else 3

        if op == '+':
            prompt = f"{n1}/{d1} + {n2}/{d2} = ?"
            spoken = f"What is {n1} over {d1} plus {n2} over {d2}?"
        else:
            prompt = f"{n1}/{d1} - {n2}/{d2} = ?"
            spoken = f"What is {n1} over {d1} minus {n2} over {d2}?"

        templates.append(make_template(
            f"frau-{idx:03d}", "g5FractionAddSubUnlike", "fraction_add_sub_unlike", "fractionAddSub",
            diff, prompt, answer, spoken,
            {"numeratorA": n1, "denominatorA": d1, "numeratorB": n2, "denominatorB": d2,
             "target": float(result)},
            supports=["fractionStrip"]
        ))
        idx += 1
    return templates[:35]

def gen_g5LinePlotsFractions():
    templates = []
    idx = 1
    # Line plot with fractional measurements
    datasets = [
        (["1/8", "1/4", "3/8", "1/2", "5/8", "3/4"], [2, 4, 1, 5, 3, 2], "inches of ribbon"),
        (["1/4", "1/2", "3/4", "1"], [3, 6, 4, 2], "cups of flour"),
        (["1/8", "1/4", "3/8", "1/2"], [5, 3, 2, 4], "miles walked"),
        (["1/4", "1/2", "3/4"], [7, 3, 5], "inches of rain"),
        (["1/2", "1", "3/2", "2"], [4, 6, 2, 3], "pounds of fruit"),
        (["1/3", "2/3", "1"], [3, 5, 4], "feet of string"),
        (["1/4", "1/2", "3/4", "1"], [2, 5, 3, 4], "liters of water"),
        (["1/8", "1/4", "3/8", "1/2", "5/8"], [1, 3, 4, 2, 5], "inches of wire"),
    ]

    for labels, values, measure in datasets:
        # Most common
        max_val = max(values)
        max_label = labels[values.index(max_val)]
        prompt = f"The line plot shows {measure}. Which length appears most often?"
        spoken = prompt
        templates.append(make_template(
            f"lp-{idx:03d}", "g5LinePlotsFractions", "line_plot_fractions", "dataPlot",
            2, prompt, max_label, spoken,
            {"barValues": values, "barLabels": labels, "target": max_val},
            supports=["visual"]
        ))
        idx += 1

        # How many at specific value
        q_i = idx % len(labels)
        prompt = f"The line plot shows {measure}. How many items measure {labels[q_i]}?"
        spoken = prompt
        templates.append(make_template(
            f"lp-{idx:03d}", "g5LinePlotsFractions", "line_plot_fractions", "dataPlot",
            2, prompt, values[q_i], spoken,
            {"barValues": values, "barLabels": labels, "target": values[q_i]},
            supports=["visual"]
        ))
        idx += 1

        # Total
        total = sum(values)
        prompt = f"The line plot shows {measure}. How many items were measured in total?"
        spoken = prompt
        templates.append(make_template(
            f"lp-{idx:03d}", "g5LinePlotsFractions", "line_plot_fractions", "dataPlot",
            2, prompt, total, spoken,
            {"barValues": values, "barLabels": labels, "target": total},
            supports=["visual"]
        ))
        idx += 1

        # Difference
        if len(labels) >= 2:
            a_i, b_i = 0, 1
            diff_val = abs(values[a_i] - values[b_i])
            prompt = f"The line plot shows {measure}. How many more items at {labels[a_i]} than {labels[b_i]}?"
            spoken = prompt
            templates.append(make_template(
                f"lp-{idx:03d}", "g5LinePlotsFractions", "line_plot_fractions", "dataPlot",
                3, prompt, diff_val, spoken,
                {"barValues": values, "barLabels": labels, "target": diff_val},
                supports=["visual"]
            ))
            idx += 1
    return templates[:35]

def gen_g5PreRatios():
    templates = []
    idx = 1
    random.seed(63)
    contexts_ratio = [
        ("apples", "dollars"), ("pencils", "cents"), ("cups", "servings"),
        ("miles", "hours"), ("pages", "minutes"), ("stickers", "packs"),
        ("cookies", "batches"), ("toys", "boxes"), ("wheels", "cars"),
        ("legs", "chairs"), ("wings", "birds"), ("petals", "flowers"),
        ("eggs", "cartons"), ("slices", "pizzas"), ("shoes", "pairs"),
    ]

    seen = set()
    for i in range(35):
        a = random.randint(2, 8)
        b = random.randint(2, 10)
        multiplier = random.randint(2, 6)
        while (a, b, multiplier) in seen:
            a = random.randint(2, 8)
            b = random.randint(2, 10)
            multiplier = random.randint(2, 6)
        seen.add((a, b, multiplier))

        new_a = a * multiplier
        new_b = b * multiplier
        ctx_a, ctx_b = contexts_ratio[i % len(contexts_ratio)]
        diff = 1 if multiplier <= 3 else 2 if multiplier <= 5 else 3

        if i % 3 == 0:
            prompt = f"If {a} {ctx_a} cost {b} {ctx_b}, how many {ctx_b} for {new_a} {ctx_a}?"
            spoken = prompt
            answer = new_b
        elif i % 3 == 1:
            prompt = f"The ratio is {a} {ctx_a} to {b} {ctx_b}. If you have {new_a} {ctx_a}, how many {ctx_b}?"
            spoken = prompt
            answer = new_b
        else:
            prompt = f"For every {a} {ctx_a}, there are {b} {ctx_b}. How many {ctx_a} for {new_b} {ctx_b}?"
            spoken = prompt
            answer = new_a

        templates.append(make_template(
            f"ratio-{idx:03d}", "g5PreRatios", "pre_ratios", "ratioTable",
            diff, prompt, answer, spoken,
            {"ratioLeft": a, "ratioRight": b, "target": answer},
            supports=["visual"]
        ))
        idx += 1
    return templates[:35]


# ──────────────────────────────────────────────
# New unit/lesson/hint definitions
# ──────────────────────────────────────────────

NEW_UNITS = [
    {"id": "kCompareGroups", "title": "Compare Groups", "order": 17},
    {"id": "kShapeAttributes", "title": "Shape Attributes", "order": 18},
    {"id": "g1AddSub100", "title": "Add & Subtract to 100", "order": 19},
    {"id": "g1MeasureLength", "title": "Measure Length", "order": 20},
    {"id": "g2PlaceValue1000", "title": "Place Value to 1,000", "order": 21},
    {"id": "g2AddSubRegroup", "title": "Add & Subtract with Regrouping", "order": 22},
    {"id": "g2EqualGroups", "title": "Equal Groups", "order": 23},
    {"id": "g2TimeMoney", "title": "Time & Money", "order": 24},
    {"id": "g2DataIntro", "title": "Data & Graphs", "order": 25},
    {"id": "g3DivMeaning", "title": "Division Meaning", "order": 26},
    {"id": "g3FractionUnit", "title": "Fraction of a Number", "order": 27},
    {"id": "g3FractionCompare", "title": "Compare Fractions", "order": 28},
    {"id": "g3AreaConcept", "title": "Area Concept", "order": 29},
    {"id": "g3MultiStep", "title": "Multi-Step Problems", "order": 30},
    {"id": "g4PlaceValueMillion", "title": "Place Value to Millions", "order": 31},
    {"id": "g4MultMultiDigit", "title": "Multi-Digit Multiplication", "order": 32},
    {"id": "g4DivPartialQuotients", "title": "Division with Partial Quotients", "order": 33},
    {"id": "g4FractionAddSub", "title": "Fraction Addition & Subtraction", "order": 34},
    {"id": "g4AngleMeasure", "title": "Angle Measurement", "order": 35},
    {"id": "g5FractionAddSubUnlike", "title": "Add & Subtract Unlike Fractions", "order": 36},
    {"id": "g5LinePlotsFractions", "title": "Line Plots with Fractions", "order": 37},
    {"id": "g5PreRatios", "title": "Pre-Ratio Thinking", "order": 38},
]

NEW_LESSONS = [
    {"id": "k-cmpg-01", "unit": "kCompareGroups", "title": "Compare Groups", "skill": "compare_groups"},
    {"id": "k-shp-01", "unit": "kShapeAttributes", "title": "Shape Attributes", "skill": "shape_classify"},
    {"id": "g1-as100-01", "unit": "g1AddSub100", "title": "Add & Subtract to 100", "skill": "add_sub_100"},
    {"id": "g1-mlen-01", "unit": "g1MeasureLength", "title": "Measure with Units", "skill": "measure_length"},
    {"id": "g2-pv1k-01", "unit": "g2PlaceValue1000", "title": "Place Value to 1,000", "skill": "place_value_1000"},
    {"id": "g2-asrg-01", "unit": "g2AddSubRegroup", "title": "Regroup to Add & Subtract", "skill": "add_sub_regroup"},
    {"id": "g2-eqgr-01", "unit": "g2EqualGroups", "title": "Equal Groups Introduction", "skill": "equal_groups"},
    {"id": "g2-tm-01", "unit": "g2TimeMoney", "title": "Tell Time & Count Money", "skill": "time_money"},
    {"id": "g2-data-01", "unit": "g2DataIntro", "title": "Read Bar Graphs", "skill": "data_intro"},
    {"id": "g3-div-01", "unit": "g3DivMeaning", "title": "Understand Division", "skill": "div_meaning"},
    {"id": "g3-fru-01", "unit": "g3FractionUnit", "title": "Fraction of a Number", "skill": "fraction_unit"},
    {"id": "g3-frcmp-01", "unit": "g3FractionCompare", "title": "Compare Fractions", "skill": "fraction_compare_unit"},
    {"id": "g3-area-01", "unit": "g3AreaConcept", "title": "Find Area", "skill": "area_concept"},
    {"id": "g3-mstep-01", "unit": "g3MultiStep", "title": "Multi-Step Word Problems", "skill": "multi_step"},
    {"id": "g4-pvM-01", "unit": "g4PlaceValueMillion", "title": "Place Value to Millions", "skill": "place_value_million"},
    {"id": "g4-mmult-01", "unit": "g4MultMultiDigit", "title": "Multiply Multi-Digit", "skill": "mult_multi_digit"},
    {"id": "g4-dpq-01", "unit": "g4DivPartialQuotients", "title": "Divide with Partial Quotients", "skill": "div_partial_quot"},
    {"id": "g4-fras-01", "unit": "g4FractionAddSub", "title": "Add & Subtract Fractions", "skill": "fraction_add_sub"},
    {"id": "g4-ang-01", "unit": "g4AngleMeasure", "title": "Measure Angles", "skill": "angle_measure"},
    {"id": "g5-frau-01", "unit": "g5FractionAddSubUnlike", "title": "Unlike Fraction Operations", "skill": "fraction_add_sub_unlike"},
    {"id": "g5-lp-01", "unit": "g5LinePlotsFractions", "title": "Line Plots with Fractions", "skill": "line_plot_fractions"},
    {"id": "g5-ratio-01", "unit": "g5PreRatios", "title": "Pre-Ratio Thinking", "skill": "pre_ratios"},
]

NEW_HINTS = [
    {"skill": "compare_groups", "concrete": "Line up objects side by side to compare.", "strategy": "Count each group, then see which number is bigger.", "worked": "5 stars vs 3 stars: 5 is more than 3, so the stars group has more."},
    {"skill": "shape_classify", "concrete": "Trace the shape with your finger. Count corners and sides.", "strategy": "Corners are where two sides meet. Count the straight sides.", "worked": "A square has 4 straight sides and 4 corners."},
    {"skill": "add_sub_100", "concrete": "Use a hundreds chart or base-ten blocks.", "strategy": "Add tens first, then ones. For subtraction, subtract tens first.", "worked": "34 + 22: add 20 to get 54, then add 2 to get 56."},
    {"skill": "measure_length", "concrete": "Line up objects end-to-end along the item.", "strategy": "Start at one end and count each unit to the other end.", "worked": "The pencil spans 7 paper clips, so it is 7 units long."},
    {"skill": "place_value_1000", "concrete": "Use hundreds flats, tens rods, and ones cubes.", "strategy": "The hundreds digit tells how many hundreds. Look at each place.", "worked": "In 452: 4 is in the hundreds place, 5 in tens, 2 in ones."},
    {"skill": "add_sub_regroup", "concrete": "Use base-ten blocks and trade 10 ones for 1 ten.", "strategy": "Add ones first. If sum is 10+, carry to tens column.", "worked": "48 + 35: 8+5=13, write 3 carry 1. 4+3+1=8. Answer: 83."},
    {"skill": "equal_groups", "concrete": "Draw circles for groups and dots inside each.", "strategy": "Equal groups means same number in each. Multiply groups × amount.", "worked": "3 groups of 4: 4+4+4=12, or 3×4=12."},
    {"skill": "time_money", "concrete": "Use a clock model with movable hands.", "strategy": "Short hand = hours. Long hand = minutes. Count by 5s.", "worked": "Short hand on 3, long hand on 6: that's 3:30."},
    {"skill": "data_intro", "concrete": "Look at the bars — taller means more.", "strategy": "Read the number at the top of each bar.", "worked": "If the Red bar reaches 5 and Blue reaches 3, Red has 2 more."},
    {"skill": "div_meaning", "concrete": "Deal objects into equal groups like dealing cards.", "strategy": "Think: what number times divisor equals dividend?", "worked": "12 ÷ 3: deal 12 into 3 groups — each gets 4."},
    {"skill": "fraction_unit", "concrete": "Split the whole into equal parts, then count.", "strategy": "Divide the whole by denominator, multiply by numerator.", "worked": "1/4 of 8: 8÷4=2. So 1/4 of 8 is 2."},
    {"skill": "fraction_compare_unit", "concrete": "Draw fraction strips with equal-sized wholes.", "strategy": "Find common denominators to compare directly.", "worked": "Compare 2/3 and 3/4: 8/12 vs 9/12. 3/4 is larger."},
    {"skill": "area_concept", "concrete": "Cover the rectangle with unit squares and count.", "strategy": "Area = length × width.", "worked": "A 4 by 3 rectangle has 4×3=12 square units of area."},
    {"skill": "multi_step", "concrete": "Break the problem into smaller steps.", "strategy": "Do one operation at a time. Check your work.", "worked": "20 + 15 - 8: first 20+15=35, then 35-8=27."},
    {"skill": "place_value_million", "concrete": "Use a place-value chart up to millions.", "strategy": "Each place is 10 times the one to its right.", "worked": "In 350,000 the 5 is in ten-thousands, so its value is 50,000."},
    {"skill": "mult_multi_digit", "concrete": "Use an area model to break numbers apart.", "strategy": "Multiply ones first, then tens, then add partial products.", "worked": "23×4: 20×4=80, 3×4=12, 80+12=92."},
    {"skill": "div_partial_quot", "concrete": "Subtract groups from the dividend step by step.", "strategy": "Start with the largest easy multiple you can subtract.", "worked": "96÷4: 4×20=80, subtract, 16 left. 4×4=16. Total: 24."},
    {"skill": "fraction_add_sub", "concrete": "Use fraction strips with matching parts.", "strategy": "Same denominators: just add or subtract the numerators.", "worked": "1/4 + 2/4 = 3/4. Keep the denominator, add numerators."},
    {"skill": "angle_measure", "concrete": "Use a protractor — line up the base line.", "strategy": "Acute < 90°, Right = 90°, Obtuse > 90°.", "worked": "A 120° angle is obtuse because it is greater than 90°."},
    {"skill": "fraction_add_sub_unlike", "concrete": "Find a common denominator using fraction strips.", "strategy": "Convert to equivalent fractions with the LCD, then add/subtract.", "worked": "1/3 + 1/6: LCD=6, so 2/6 + 1/6 = 3/6 = 1/2."},
    {"skill": "line_plot_fractions", "concrete": "Each X on the line plot represents one item.", "strategy": "Count the Xs above each fraction to read the data.", "worked": "If 3 Xs sit above 1/4, then 3 items measure 1/4 inch."},
    {"skill": "pre_ratios", "concrete": "Use a ratio table: write the pattern and extend it.", "strategy": "Find the multiplier between known and unknown.", "worked": "2 apples cost 6¢. 4 apples is 2×, so 6×2=12¢."},
]


def main():
    # Load existing data
    with open(CONTENT_PATH, "r") as f:
        data = json.load(f)

    existing_templates = data["itemTemplates"]
    existing_prompts = set(t["prompt"] for t in existing_templates)
    existing_ids = set(t["id"] for t in existing_templates)

    # ── Generate new templates for 8 existing units ──
    print("Generating templates for existing K-2 units...")
    new_for_existing = []
    generators_existing = [
        ("kCountObjects", gen_kCountObjects),
        ("kComposeDecompose", gen_kComposeDecompose),
        ("kAddWithin5", gen_kAddWithin5),
        ("kAddWithin10", gen_kAddWithin10),
        ("g1AddWithin20", gen_g1AddWithin20),
        ("g1FactFamilies", gen_g1FactFamilies),
        ("g2AddWithin100", gen_g2AddWithin100),
        ("g2SubWithin100", gen_g2SubWithin100),
    ]

    for unit_name, gen_func in generators_existing:
        templates = gen_func()
        # Filter out duplicates
        added = 0
        for t in templates:
            if t["prompt"] not in existing_prompts and t["id"] not in existing_ids:
                existing_prompts.add(t["prompt"])
                existing_ids.add(t["id"])
                new_for_existing.append(t)
                added += 1
        print(f"  {unit_name}: +{added} templates")

    # ── Generate templates for 22 new units ──
    print("\nGenerating templates for 22 new units...")
    new_unit_templates = []
    generators_new = [
        ("kCompareGroups", gen_kCompareGroups),
        ("kShapeAttributes", gen_kShapeAttributes),
        ("g1AddSub100", gen_g1AddSub100),
        ("g1MeasureLength", gen_g1MeasureLength),
        ("g2PlaceValue1000", gen_g2PlaceValue1000),
        ("g2AddSubRegroup", gen_g2AddSubRegroup),
        ("g2EqualGroups", gen_g2EqualGroups),
        ("g2TimeMoney", gen_g2TimeMoney),
        ("g2DataIntro", gen_g2DataIntro),
        ("g3DivMeaning", gen_g3DivMeaning),
        ("g3FractionUnit", gen_g3FractionUnit),
        ("g3FractionCompare", gen_g3FractionCompare),
        ("g3AreaConcept", gen_g3AreaConcept),
        ("g3MultiStep", gen_g3MultiStep),
        ("g4PlaceValueMillion", gen_g4PlaceValueMillion),
        ("g4MultMultiDigit", gen_g4MultMultiDigit),
        ("g4DivPartialQuotients", gen_g4DivPartialQuotients),
        ("g4FractionAddSub", gen_g4FractionAddSub),
        ("g4AngleMeasure", gen_g4AngleMeasure),
        ("g5FractionAddSubUnlike", gen_g5FractionAddSubUnlike),
        ("g5LinePlotsFractions", gen_g5LinePlotsFractions),
        ("g5PreRatios", gen_g5PreRatios),
    ]

    for unit_name, gen_func in generators_new:
        templates = gen_func()
        added = 0
        for t in templates:
            if t["prompt"] not in existing_prompts and t["id"] not in existing_ids:
                existing_prompts.add(t["prompt"])
                existing_ids.add(t["id"])
                new_unit_templates.append(t)
                added += 1
        print(f"  {unit_name}: +{added} templates")

    # ── Update data ──
    # Add units
    existing_unit_ids = {u["id"] for u in data["units"]}
    for u in NEW_UNITS:
        if u["id"] not in existing_unit_ids:
            data["units"].append(u)

    # Add lessons
    existing_lesson_ids = {l["id"] for l in data["lessons"]}
    for l in NEW_LESSONS:
        if l["id"] not in existing_lesson_ids:
            data["lessons"].append(l)

    # Add hints
    existing_hint_skills = {h["skill"] for h in data["hints"]}
    for h in NEW_HINTS:
        if h["skill"] not in existing_hint_skills:
            data["hints"].append(h)

    # Add templates
    data["itemTemplates"].extend(new_for_existing)
    data["itemTemplates"].extend(new_unit_templates)

    # ── Write output ──
    with open(CONTENT_PATH, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    # ── Summary ──
    print(f"\n{'='*60}")
    print(f"SUMMARY")
    print(f"{'='*60}")
    print(f"Total units: {len(data['units'])}")
    print(f"Total lessons: {len(data['lessons'])}")
    print(f"Total hints: {len(data['hints'])}")
    print(f"Total templates: {len(data['itemTemplates'])}")

    from collections import Counter
    c = Counter(t["unit"] for t in data["itemTemplates"])
    print(f"\nTemplates per unit:")
    for unit, count in sorted(c.items()):
        print(f"  {unit}: {count}")

    # Check for duplicate prompts
    all_prompts = [t["prompt"] for t in data["itemTemplates"]]
    dupes = [p for p in all_prompts if all_prompts.count(p) > 1]
    if dupes:
        print(f"\nWARNING: {len(set(dupes))} duplicate prompts found!")
        for d in sorted(set(dupes)):
            print(f"  - '{d}' (appears {all_prompts.count(d)} times)")
    else:
        print(f"\nNo duplicate prompts found!")

    # Check for duplicate IDs
    all_ids = [t["id"] for t in data["itemTemplates"]]
    dupe_ids = [i for i in all_ids if all_ids.count(i) > 1]
    if dupe_ids:
        print(f"\nWARNING: {len(set(dupe_ids))} duplicate IDs found!")
    else:
        print(f"No duplicate IDs found!")

    # Spot-check math correctness
    print(f"\nSpot-checking answer correctness...")
    errors = 0
    for t in data["itemTemplates"]:
        p = t["payload"]
        ans = t["answer"]
        # Check addition
        if p.get("left") is not None and p.get("right") is not None and p.get("target") is not None:
            if t["format"] in ["additionStory", "addTwoDigit"] and t.get("skill","") not in ["multi_step"]:
                if "+" in t["prompt"] or "more" in t["prompt"].lower() or "add" in t["prompt"].lower() or "find" in t["prompt"].lower() or "arrive" in t["prompt"].lower() or "gets" in t["prompt"].lower() or "come" in t["prompt"].lower() or "total" in t["prompt"].lower():
                    if "-" not in t["prompt"] and "give away" not in t["prompt"].lower() and "leave" not in t["prompt"].lower() and "lose" not in t["prompt"].lower() and "taken" not in t["prompt"].lower() and "sell" not in t["prompt"].lower():
                        expected = p["left"] + p["right"]
                        if str(expected) != ans:
                            print(f"  ERROR: {t['id']} {t['prompt']} expected={expected} got={ans}")
                            errors += 1
        # Check multiplication
        if p.get("multiplicand") is not None and p.get("multiplier") is not None and p.get("target") is not None:
            if t["format"] in ["multiplicationArray"] and t.get("skill","") not in ["multi_step"]:
                expected = p["multiplicand"] * p["multiplier"]
                if expected != p["target"]:
                    print(f"  ERROR: {t['id']} {t['prompt']} expected={expected} got target={p['target']}")
                    errors += 1
        # Check division
        if p.get("dividend") is not None and p.get("divisor") is not None and p.get("target") is not None:
            if t["format"] in ["divisionGroups"]:
                expected = p["dividend"] // p["divisor"]
                if str(expected) != ans:
                    print(f"  ERROR: {t['id']} {t['prompt']} expected={expected} got={ans}")
                    errors += 1
        # Check subtraction
        if p.get("minuend") is not None and p.get("subtrahend") is not None and p.get("target") is not None:
            if t["format"] in ["subTwoDigit", "subtractionStory"]:
                expected = p["minuend"] - p["subtrahend"]
                if str(expected) != ans:
                    print(f"  ERROR: {t['id']} {t['prompt']} expected={expected} got={ans}")
                    errors += 1

    if errors == 0:
        print(f"  All spot-checked answers are correct!")
    else:
        print(f"  {errors} errors found!")

    print(f"\nDone! Content pack written to {CONTENT_PATH}")


if __name__ == "__main__":
    main()
