#!/usr/bin/env python3
"""
Generate the future spatial question bank and the expanded audio recording set.

This intentionally writes a draft content pack instead of mutating
content-pack-v1.json. The live app needs new Swift ItemFormat, payload, hint,
and interaction support before these spatial formats should be mixed into
production sessions.

Outputs:
  - MathQuestKids/Content/spatial-question-bank-v2.json
  - scripts/audio_recording_set_2026_04_26.json
  - scripts/audio_recording_set_2026_04_26.csv
"""

from __future__ import annotations

import csv
import json
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
CONTENT_DIR = PROJECT_ROOT / "MathQuestKids" / "Content"

SPATIAL_BANK_PATH = CONTENT_DIR / "spatial-question-bank-v2.json"
AUDIO_JSON_PATH = SCRIPT_DIR / "audio_recording_set_2026_04_26.json"
AUDIO_CSV_PATH = SCRIPT_DIR / "audio_recording_set_2026_04_26.csv"

RANDOM_SEED = 4262026


@dataclass(frozen=True)
class Shape:
    name: str
    sides: int | None
    corners: int | None


SHAPES_2D = [
    Shape("circle", 0, 0),
    Shape("triangle", 3, 3),
    Shape("square", 4, 4),
    Shape("rectangle", 4, 4),
    Shape("oval", 0, 0),
    Shape("diamond", 4, 4),
    Shape("rhombus", 4, 4),
    Shape("trapezoid", 4, 4),
    Shape("pentagon", 5, 5),
    Shape("hexagon", 6, 6),
    Shape("octagon", 8, 8),
]

SOLIDS = [
    {
        "name": "cube",
        "faces": 6,
        "edges": 12,
        "vertices": 8,
        "attributes": ["6 equal square faces", "only square faces", "looks like a dice"],
        "objects": ["dice", "block", "gift box"],
    },
    {
        "name": "rectangular prism",
        "faces": 6,
        "edges": 12,
        "vertices": 8,
        "attributes": ["rectangle faces like a cereal box", "6 flat faces that are not all squares", "a box shape with longer rectangle faces"],
        "objects": ["cereal box", "brick", "book"],
    },
    {
        "name": "sphere",
        "faces": 0,
        "edges": 0,
        "vertices": 0,
        "attributes": ["round all over", "no flat faces", "can roll in every direction"],
        "objects": ["ball", "orange", "marble"],
    },
    {
        "name": "cylinder",
        "faces": 2,
        "edges": 2,
        "vertices": 0,
        "attributes": ["2 circle faces", "one curved side and 2 flat circles", "looks like a can"],
        "objects": ["can", "paper towel roll", "drum"],
    },
    {
        "name": "cone",
        "faces": 1,
        "edges": 1,
        "vertices": 1,
        "attributes": ["1 point and 1 circle face", "looks like a party hat", "1 flat circle and 1 curved side"],
        "objects": ["party hat", "ice cream cone", "traffic cone"],
    },
    {
        "name": "pyramid",
        "faces": 5,
        "edges": 8,
        "vertices": 5,
        "attributes": ["triangular faces and 1 square base", "1 top point above a square base", "looks like an Egyptian pyramid"],
        "objects": ["pyramid", "tent top", "roof model"],
    },
]

COLORS = [
    "red", "blue", "green", "yellow", "purple", "orange", "pink", "teal",
]

POSITION_RELATIONS = [
    ("above", (0, -1)),
    ("below", (0, 1)),
    ("left of", (-1, 0)),
    ("right of", (1, 0)),
    ("beside", (1, 0)),
]

GRID_OBJECTS = [
    "star", "rocket", "shell", "gem", "key", "flag", "heart", "moon",
    "flower", "book", "coin", "kite",
]

SCENE_CONTEXTS = [
    "star map",
    "garden board",
    "treasure path",
    "reef picture",
    "candy trail",
    "rocket panel",
    "rainbow mat",
    "puzzle shelf",
    "number meadow",
    "shape station",
    "sticker scene",
    "playroom grid",
    "mountain path",
    "beach board",
    "forest map",
    "classroom chart",
    "festival board",
]


def context_for(idx: int) -> str:
    return SCENE_CONTEXTS[(idx - 1) % len(SCENE_CONTEXTS)]


def choices_with_answer(answer: str, distractors: list[str], total: int = 4) -> list[str]:
    values = [answer]
    for item in distractors:
        if item != answer and item not in values:
            values.append(item)
        if len(values) == total:
            break
    return values


def numeric_choices(answer: int, low: int = 0, high: int = 20) -> list[str]:
    offsets = [-3, -2, -1, 1, 2, 3, 4]
    values = [answer]
    for offset in offsets:
        candidate = max(low, min(high, answer + offset))
        if candidate != answer and candidate not in values:
            values.append(candidate)
        if len(values) == 4:
            break
    return [str(v) for v in values]


def make_item(
    *,
    id_: str,
    unit: str,
    title: str,
    grade_band: str,
    skill: str,
    fmt: str,
    difficulty: int,
    prompt: str,
    answer: str,
    choices: list[str],
    payload: dict[str, Any],
    supports: list[str],
    hint: dict[str, str],
    standards: list[str],
) -> dict[str, Any]:
    return {
        "id": id_,
        "unit": unit,
        "unitTitle": title,
        "gradeBand": grade_band,
        "skill": skill,
        "format": fmt,
        "difficulty": difficulty,
        "prompt": prompt,
        "spokenForm": prompt,
        "answer": answer,
        "choices": choices,
        "supports": supports,
        "payload": payload,
        "hint": hint,
        "standards": standards,
    }


def generate_shape_hunt(rng: random.Random) -> list[dict[str, Any]]:
    items = []
    prompt_variants = [
        "Tap every {shape} in the scene. How many should you find?",
        "Find all the {shape}s. How many are hiding?",
        "Look across the scene and count each {shape}.",
        "Which count matches all the {shape}s in the picture?",
        "Search the scene. How many {shape}s are there?",
    ]
    target_shapes = [s.name for s in SHAPES_2D[:10]]
    for idx in range(1, 81):
        context = context_for(idx)
        target = target_shapes[(idx - 1) % len(target_shapes)]
        target_count = 2 + (idx % 5)
        distractor_count = 4 + (idx % 4)
        scene = []
        for n in range(target_count):
            scene.append({
                "shape": target,
                "color": COLORS[(idx + n) % len(COLORS)],
                "x": (idx * 2 + n * 3) % 6,
                "y": (idx + n * 2) % 5,
                "rotation": [0, 30, 45, 90][(idx + n) % 4],
                "target": True,
            })
        distractors = [s.name for s in SHAPES_2D if s.name != target]
        for n in range(distractor_count):
            scene.append({
                "shape": distractors[(idx + n) % len(distractors)],
                "color": COLORS[(idx + n + 3) % len(COLORS)],
                "x": (idx + n * 4) % 6,
                "y": (idx * 2 + n) % 5,
                "rotation": [0, 45, 90, 135][(idx + n) % 4],
                "target": False,
            })
        base_prompt = prompt_variants[(idx - 1) % len(prompt_variants)].format(shape=target)
        prompt = f"On the {context}, {base_prompt[0].lower() + base_prompt[1:]}"
        items.append(make_item(
            id_=f"sp-shape-hunt-{idx:03d}",
            unit="kSpatialShapeHunt",
            title="Shape Hunt",
            grade_band="K-1",
            skill="shape_hunt",
            fmt="shapeHunt",
            difficulty=1 if idx <= 30 else 2 if idx <= 60 else 3,
            prompt=prompt,
            answer=str(target_count),
            choices=numeric_choices(target_count, low=1, high=10),
            payload={
                "targetShape": target,
                "targetCount": target_count,
                "context": context,
                "scene": scene,
                "gridSize": {"columns": 6, "rows": 5},
            },
            supports=["visual", "shapeCards"],
            hint={
                "concrete": f"Look for one {target} at a time. Touch it, then count one.",
                "strategy": f"Scan left to right so you do not miss a {target}.",
                "worked": f"Every object shaped like a {target} counts. The total is {target_count}.",
            },
            standards=["K.G.A.2", "K.CC.B.4"],
        ))
    return items


def generate_position_words(rng: random.Random) -> list[dict[str, Any]]:
    items = []
    prompt_variants = [
        "Which object is {relation} the {anchor}?",
        "Find the object {relation} the {anchor}.",
        "Look at the grid. What is {relation} the {anchor}?",
        "Use position words. Which one is {relation} the {anchor}?",
    ]
    for idx in range(1, 81):
        context = context_for(idx)
        relation, delta = POSITION_RELATIONS[(idx - 1) % len(POSITION_RELATIONS)]
        anchor = GRID_OBJECTS[idx % len(GRID_OBJECTS)]
        answer = GRID_OBJECTS[(idx + 3) % len(GRID_OBJECTS)]
        anchor_pos = (2 + (idx % 2), 2 + ((idx // 2) % 2))
        answer_pos = (anchor_pos[0] + delta[0], anchor_pos[1] + delta[1])
        if relation == "beside":
            answer_pos = (anchor_pos[0] + (1 if idx % 2 else -1), anchor_pos[1])
        distractors = [
            obj for obj in GRID_OBJECTS
            if obj not in {anchor, answer}
        ]
        objects = [
            {"name": anchor, "x": anchor_pos[0], "y": anchor_pos[1]},
            {"name": answer, "x": answer_pos[0], "y": answer_pos[1]},
        ]
        for n in range(4):
            objects.append({
                "name": distractors[(idx + n) % len(distractors)],
                "x": (idx + n * 2) % 5,
                "y": (idx * 2 + n) % 5,
            })
        base_prompt = prompt_variants[(idx - 1) % len(prompt_variants)].format(
            relation=relation,
            anchor=anchor,
        )
        prompt = f"On the {context}, {base_prompt[0].lower() + base_prompt[1:]}"
        items.append(make_item(
            id_=f"sp-position-{idx:03d}",
            unit="kSpatialPositionWords",
            title="Position Words",
            grade_band="K-1",
            skill="position_words",
            fmt="positionWords",
            difficulty=1 if relation in {"above", "below"} else 2,
            prompt=prompt,
            answer=answer,
            choices=choices_with_answer(answer, distractors),
            payload={
                "relation": relation,
                "anchor": anchor,
                "context": context,
                "objects": objects,
                "gridSize": {"columns": 5, "rows": 5},
            },
            supports=["visual", "grid"],
            hint={
                "concrete": f"Put your finger on the {anchor}.",
                "strategy": f"From the {anchor}, move to the space {relation} it.",
                "worked": f"The {answer} is {relation} the {anchor}.",
            },
            standards=["K.G.A.1"],
        ))
    return items


def generate_rotate_to_match(rng: random.Random) -> list[dict[str, Any]]:
    items = []
    rotations = [45, 90, 135, 180, 225, 270, 315]
    prompt_variants = [
        "Which choice matches the {shape} after it turns {degrees} degrees?",
        "Turn the {shape} in your mind. Which one matches?",
        "The {shape} rotates {degrees} degrees. Choose the matching shape.",
        "Which picture is the same {shape}, just turned?",
    ]
    rotatable_shapes = ["triangle", "rectangle", "diamond", "pentagon", "trapezoid", "arrow", "L shape", "T shape"]
    for idx in range(1, 81):
        context = context_for(idx)
        shape = rotatable_shapes[(idx - 1) % len(rotatable_shapes)]
        color = COLORS[(idx - 1) % len(COLORS)]
        degrees = rotations[(idx + 1) % len(rotations)]
        answer = ["A", "B", "C", "D"][idx % 4]
        choices = ["A", "B", "C", "D"]
        options = []
        for label in choices:
            offset = {"A": 0, "B": 45, "C": 90, "D": 135}[label]
            options.append({
                "label": label,
                "shape": shape,
                "rotation": degrees if label == answer else (degrees + offset + 45) % 360,
                "mirrored": label != answer and (idx + ord(label)) % 3 == 0,
            })
        base_prompt = prompt_variants[(idx - 1) % len(prompt_variants)].format(
            shape=f"{color} {shape}",
            degrees=degrees,
        )
        prompt = f"On the {context}, {base_prompt[0].lower() + base_prompt[1:]}"
        items.append(make_item(
            id_=f"sp-rotate-{idx:03d}",
            unit="k2SpatialRotateMatch",
            title="Rotate to Match",
            grade_band="K-2",
            skill="mental_rotation",
            fmt="rotateToMatch",
            difficulty=1 if degrees in {90, 180, 270} else 3,
            prompt=prompt,
            answer=answer,
            choices=choices,
            payload={
                "shape": shape,
                "color": color,
                "context": context,
                "rotationDegrees": degrees,
                "options": options,
                "allowMirrorDistractors": True,
            },
            supports=["visual", "shapeCards"],
            hint={
                "concrete": f"Trace the {shape}, then turn your finger the same way.",
                "strategy": "A matching shape can be turned, but it should not be flipped.",
                "worked": f"Choice {answer} is the same {shape} after the turn.",
            },
            standards=["1.G.A.1", "2.G.A.1"],
        ))
    return items


def generate_build_shape(rng: random.Random) -> list[dict[str, Any]]:
    items = []
    builds = [
        ("rectangle", "two squares", ["two triangles", "two circles", "one triangle and one circle"]),
        ("square", "two equal right triangles", ["two circles", "one rectangle and one circle", "three pentagons"]),
        ("hexagon", "six triangles", ["two squares", "three circles", "one rectangle"]),
        ("larger triangle", "four small triangles", ["two rectangles", "three circles", "one square and one circle"]),
        ("trapezoid", "one triangle and one rectangle", ["two circles", "one hexagon", "four squares"]),
        ("diamond", "two equal triangles", ["two circles", "one rectangle", "three squares"]),
    ]
    prompt_variants = [
        "Which pieces can build a {target}?",
        "Choose the pieces that make a {target}.",
        "Which set of shapes composes a {target}?",
        "Build the {target}. Which pieces fit?",
    ]
    for idx in range(1, 61):
        context = context_for(idx)
        target, answer, distractors = builds[(idx - 1) % len(builds)]
        base_prompt = prompt_variants[(idx - 1) % len(prompt_variants)].format(target=target)
        prompt = f"On the {context}, {base_prompt[0].lower() + base_prompt[1:]}"
        items.append(make_item(
            id_=f"sp-build-shape-{idx:03d}",
            unit="g1SpatialBuildShapes",
            title="Build Shapes",
            grade_band="1-3",
            skill="compose_decompose_shapes",
            fmt="buildShape",
            difficulty=1 if idx <= 20 else 2 if idx <= 45 else 3,
            prompt=prompt,
            answer=answer,
            choices=choices_with_answer(answer, distractors),
            payload={
                "targetShape": target,
                "context": context,
                "correctPieces": answer,
                "distractorPieces": distractors,
                "rotationAllowed": idx > 20,
            },
            supports=["visual", "shapeCards"],
            hint={
                "concrete": f"Look at the outline of the {target}.",
                "strategy": "Try matching long sides to long sides and corners to corners.",
                "worked": f"The {answer} can compose the {target}.",
            },
            standards=["1.G.A.2", "2.G.A.1"],
        ))
    return items


def generate_symmetry_mirror(rng: random.Random) -> list[dict[str, Any]]:
    items = []
    axes = ["vertical", "horizontal"]
    objects = ["heart", "butterfly", "star", "square pattern", "leaf", "rocket badge"]
    prompt_variants = [
        "Which choice completes the mirror picture?",
        "Pick the missing half across the {axis} mirror line.",
        "Which side makes the picture symmetrical?",
        "Choose the half that matches like a mirror.",
    ]
    for idx in range(1, 61):
        context = context_for(idx)
        axis = axes[idx % len(axes)]
        obj = objects[(idx - 1) % len(objects)]
        answer = ["A", "B", "C", "D"][(idx + 1) % 4]
        base_prompt = prompt_variants[(idx - 1) % len(prompt_variants)].format(axis=axis)
        prompt = f"On the {context}, {base_prompt[0].lower() + base_prompt[1:]}"
        items.append(make_item(
            id_=f"sp-symmetry-{idx:03d}",
            unit="g1SpatialSymmetryMirror",
            title="Symmetry Mirror",
            grade_band="1-4",
            skill="line_symmetry",
            fmt="symmetryMirror",
            difficulty=1 if idx <= 20 else 2 if idx <= 45 else 3,
            prompt=f"{prompt} The picture is a {obj}.",
            answer=answer,
            choices=["A", "B", "C", "D"],
            payload={
                "object": obj,
                "context": context,
                "axis": axis,
                "answerChoice": answer,
                "options": [
                    {"label": "A", "mirrorsCorrectly": answer == "A"},
                    {"label": "B", "mirrorsCorrectly": answer == "B"},
                    {"label": "C", "mirrorsCorrectly": answer == "C"},
                    {"label": "D", "mirrorsCorrectly": answer == "D"},
                ],
            },
            supports=["visual", "grid"],
            hint={
                "concrete": "Fold the picture on the mirror line in your mind.",
                "strategy": "Each part should land on the matching part on the other side.",
                "worked": f"Choice {answer} makes two matching mirror halves.",
            },
            standards=["4.G.A.3"],
        ))
    return items


def generate_grid_paths(rng: random.Random) -> list[dict[str, Any]]:
    items = []
    prompt_variants = [
        "Start at {start}. Move {steps}. Where do you land?",
        "Follow the path from {start}: {steps}. Which object is there?",
        "Use the grid directions. From {start}, go {steps}.",
        "Trace the moves from {start}. What do you reach?",
    ]
    directions = [
        ("2 right and 1 up", (2, -1)),
        ("1 left and 2 down", (-1, 2)),
        ("3 right", (3, 0)),
        ("2 up and 1 left", (-1, -2)),
        ("1 right and 2 down", (1, 2)),
        ("2 left and 1 up", (-2, -1)),
        ("1 down and 3 right", (3, 1)),
        ("2 up", (0, -2)),
    ]
    for idx in range(1, 81):
        context = context_for(idx)
        start = GRID_OBJECTS[(idx - 1) % len(GRID_OBJECTS)]
        steps, delta = directions[(idx - 1) % len(directions)]
        answer = GRID_OBJECTS[(idx + 5) % len(GRID_OBJECTS)]
        distractors = [obj for obj in GRID_OBJECTS if obj not in {start, answer}]
        start_pos = (1 + (idx % 2), 2 + ((idx // 3) % 2))
        target_pos = (start_pos[0] + delta[0], start_pos[1] + delta[1])
        base_prompt = prompt_variants[(idx - 1) % len(prompt_variants)].format(start=start, steps=steps)
        prompt = f"On the {context}, {base_prompt[0].lower() + base_prompt[1:]}"
        items.append(make_item(
            id_=f"sp-grid-path-{idx:03d}",
            unit="g2SpatialGridPaths",
            title="Grid Paths",
            grade_band="1-4",
            skill="grid_navigation",
            fmt="gridPath",
            difficulty=1 if "and" not in steps else 2 if idx <= 50 else 3,
            prompt=prompt,
            answer=answer,
            choices=choices_with_answer(answer, distractors),
            payload={
                "start": start,
                "context": context,
                "startPosition": {"x": start_pos[0], "y": start_pos[1]},
                "moves": steps,
                "delta": {"x": delta[0], "y": delta[1]},
                "targetPosition": {"x": target_pos[0], "y": target_pos[1]},
                "targetObject": answer,
                "gridSize": {"columns": 6, "rows": 6},
            },
            supports=["visual", "grid"],
            hint={
                "concrete": f"Put your finger on {start}.",
                "strategy": f"Move one direction at a time: {steps}.",
                "worked": f"After you move {steps}, you land on the {answer}.",
            },
            standards=["2.G.A.1", "5.G.A.1"],
        ))
    return items


def generate_solid_attributes(rng: random.Random) -> list[dict[str, Any]]:
    items = []
    prompt_variants = [
        "Which solid matches this clue: {attribute}?",
        "Pick the 3D shape with this clue: {attribute}.",
        "Which solid has this attribute: {attribute}?",
        "Find the solid described by this clue: {attribute}.",
    ]
    for idx in range(1, 81):
        context = context_for(idx)
        solid = SOLIDS[(idx - 1) % len(SOLIDS)]
        attribute = solid["attributes"][(idx // len(SOLIDS)) % len(solid["attributes"])]
        base_prompt = prompt_variants[(idx - 1) % len(prompt_variants)].format(attribute=attribute)
        prompt = f"On the {context}, {base_prompt[0].lower() + base_prompt[1:]}"
        distractors = [s["name"] for s in SOLIDS if s["name"] != solid["name"]]
        items.append(make_item(
            id_=f"sp-solid-{idx:03d}",
            unit="g2SpatialSolidAttributes",
            title="3D Solid Attributes",
            grade_band="2-5",
            skill="solid_attributes",
            fmt="solidAttributes",
            difficulty=1 if idx <= 25 else 2 if idx <= 60 else 3,
            prompt=prompt,
            answer=solid["name"],
            choices=choices_with_answer(solid["name"], distractors),
            payload={
                "solidName": solid["name"],
                "context": context,
                "faces": solid["faces"],
                "edges": solid["edges"],
                "vertices": solid["vertices"],
                "attribute": attribute,
                "realWorldObjects": solid["objects"],
            },
            supports=["visual", "shapeCards"],
            hint={
                "concrete": "Look for flat faces, curved surfaces, edges, and points.",
                "strategy": "Match the clue to the solid's attributes.",
                "worked": f"A {solid['name']} has {attribute}.",
            },
            standards=["K.G.B.4", "2.G.A.1"],
        ))
    return items


def generate_net_preview(rng: random.Random) -> list[dict[str, Any]]:
    items = []
    net_patterns = [
        ("cross net", "six squares connected in a cross shape"),
        ("T net", "four squares in a row with one above and one below"),
        ("zigzag net", "six squares connected in a zigzag that can fold"),
        ("strip net", "six squares in one long strip"),
        ("missing-face net", "only five squares"),
        ("overlap net", "six squares that overlap when folded"),
    ]
    prompt_variants = [
        "Which net can fold into a cube?",
        "Pick the flat pattern that makes a cube.",
        "Which set of squares folds into a cube?",
        "Find the cube net.",
    ]
    valid = {"cross net", "T net", "zigzag net"}
    for idx in range(1, 41):
        context = context_for(idx)
        answer = ["A", "B", "C", "D"][idx % 4]
        correct_pattern = net_patterns[(idx - 1) % 3]
        distractor_patterns = [p for p in net_patterns if p[0] not in valid or p[0] != correct_pattern[0]]
        options = []
        for label in ["A", "B", "C", "D"]:
            if label == answer:
                name, description = correct_pattern
                folds = True
            else:
                name, description = distractor_patterns[(idx + ord(label)) % len(distractor_patterns)]
                folds = False
            options.append({"label": label, "pattern": name, "description": description, "foldsToCube": folds})
        base_prompt = prompt_variants[(idx - 1) % len(prompt_variants)]
        prompt = f"On the {context}, {base_prompt[0].lower() + base_prompt[1:]}"
        items.append(make_item(
            id_=f"sp-net-{idx:03d}",
            unit="g4SpatialNetsPreview",
            title="Cube Nets Preview",
            grade_band="4-5",
            skill="cube_nets",
            fmt="netPreview",
            difficulty=3,
            prompt=prompt,
            answer=answer,
            choices=["A", "B", "C", "D"],
            payload={
                "targetSolid": "cube",
                "context": context,
                "answerChoice": answer,
                "options": options,
            },
            supports=["visual", "grid"],
            hint={
                "concrete": "A cube needs exactly six square faces.",
                "strategy": "Imagine folding each square up around the center square.",
                "worked": f"Choice {answer} folds into a cube without missing or overlapping faces.",
            },
            standards=["5.G.B.3"],
        ))
    return items


def generate_spatial_bank() -> dict[str, Any]:
    rng = random.Random(RANDOM_SEED)
    sections = [
        generate_shape_hunt(rng),
        generate_position_words(rng),
        generate_rotate_to_match(rng),
        generate_build_shape(rng),
        generate_symmetry_mirror(rng),
        generate_grid_paths(rng),
        generate_solid_attributes(rng),
        generate_net_preview(rng),
    ]
    items = [item for section in sections for item in section]
    counts_by_format: dict[str, int] = {}
    counts_by_unit: dict[str, int] = {}
    for item in items:
        counts_by_format[item["format"]] = counts_by_format.get(item["format"], 0) + 1
        counts_by_unit[item["unit"]] = counts_by_unit.get(item["unit"], 0) + 1

    return {
        "metadata": {
            "id": "spatial-question-bank-v2",
            "generatedBy": "scripts/generate_future_question_audio_sets.py",
            "date": "2026-04-26",
            "status": "draft_not_loaded_by_app",
            "reason": "New spatial formats require Swift ItemFormat, payload, hint, and interaction support before production use.",
            "itemCount": len(items),
            "countsByFormat": counts_by_format,
            "countsByUnit": counts_by_unit,
        },
        "items": items,
    }


def add_clip(
    clips: list[dict[str, Any]],
    seen_ids: set[str],
    *,
    id_: str,
    category: str,
    text: str,
    priority: str,
    tone: str = "warm",
    state: str | None = None,
    domain: str = "any",
    fmt: str | None = None,
    tags: list[str] | None = None,
) -> None:
    if id_ in seen_ids:
        raise ValueError(f"Duplicate audio id: {id_}")
    seen_ids.add(id_)
    safe_category = category.replace(".", "/")
    clips.append({
        "id": id_,
        "category": category,
        "text": text,
        "priority": priority,
        "tone": tone,
        "state": state,
        "domain": domain,
        "format": fmt,
        "tags": tags or [],
        "filename": f"{id_}.mp3",
        "file": f"future/{safe_category}/{id_}.mp3",
        "voiceSettings": {
            "stability": 0.65,
            "similarityBoost": 0.80,
            "style": 0.35,
            "speakerBoost": True,
        },
    })


def add_numbered_lines(
    clips: list[dict[str, Any]],
    seen_ids: set[str],
    *,
    prefix: str,
    category: str,
    lines: list[str],
    priority: str,
    tone: str = "warm",
    state: str | None = None,
    domain: str = "any",
    fmt: str | None = None,
    tags: list[str] | None = None,
) -> None:
    for idx, line in enumerate(lines, 1):
        add_clip(
            clips,
            seen_ids,
            id_=f"{prefix}-{idx:03d}",
            category=category,
            text=line,
            priority=priority,
            tone=tone,
            state=state,
            domain=domain,
            fmt=fmt,
            tags=tags,
        )


def generate_feedback_audio(clips: list[dict[str, Any]], seen_ids: set[str]) -> None:
    correct_states = {
        "first_try": [
            "Yes, first try. You saw it quickly.",
            "That clicked right away. Nice thinking.",
            "You matched the answer on the first try.",
            "Clean solve. You knew what to look for.",
            "That was careful and quick.",
            "You found the important clue.",
            "Nice work. Your strategy was ready.",
            "That answer fits perfectly.",
            "You solved it without needing a hint.",
            "Great start. Keep that focus.",
            "You noticed the answer right away.",
            "That was a confident first choice.",
            "Sharp thinking on the first pass.",
            "You read the problem and solved it.",
            "Your first idea was the right one.",
            "That was a strong first try.",
            "You checked the helper and chose well.",
            "Excellent first-step thinking.",
        ],
        "after_retry": [
            "Nice fix. You changed your thinking and got it.",
            "That is how learning works. Try, adjust, solve.",
            "You checked it again and found the answer.",
            "Good comeback. You stayed with the problem.",
            "You used the mistake to find the right path.",
            "That second look helped.",
            "You corrected the tricky part.",
            "You kept going and solved it.",
            "Strong persistence. That answer is right.",
            "You made a smart adjustment.",
            "Nice recovery. You did not stop at the first try.",
            "That revision worked.",
            "You listened to the clue and fixed it.",
            "Great job checking your answer again.",
            "That was flexible math thinking.",
            "You learned from the first attempt.",
            "You found the better strategy.",
            "That answer is right after careful work.",
        ],
        "after_hint": [
            "That hint helped you spot the clue.",
            "Nice use of the hint. You did the thinking.",
            "You followed the strategy and got it.",
            "Good job turning the hint into an answer.",
            "The helper gave you a start, and you finished it.",
            "That is a strong way to use support.",
            "You checked the visual and chose well.",
            "Nice. The hint pointed the way, and you solved it.",
            "You used the step carefully.",
            "Great learning moment.",
            "You used the clue without guessing.",
            "That hint unlocked the problem.",
            "You made the helper work for you.",
            "Nice job connecting the hint to the answer.",
            "You saw what the hint was showing.",
            "Good strategy use.",
            "That support helped you finish strong.",
            "You turned a clue into a solution.",
        ],
        "streak": [
            "That is a streak of strong thinking.",
            "You are building momentum.",
            "Another careful solve.",
            "Your focus is adding up.",
            "You are on a roll with smart choices.",
            "That is steady math power.",
            "You keep finding the important clue.",
            "Nice streak. Stay careful.",
            "You are solving with rhythm.",
            "That is another one done well.",
            "Your strategy is working again.",
            "Keep that thoughtful pace.",
            "You are making this look smooth.",
            "Great run of answers.",
            "You are stacking good thinking.",
            "That streak came from focus.",
            "You are moving through these with care.",
            "Another correct answer for the trail.",
        ],
        "review_correct": [
            "Nice review. Your brain remembered this.",
            "That old skill is still strong.",
            "Good retrieval. You brought the strategy back.",
            "Review win. You kept that idea fresh.",
            "You remembered what to do.",
            "That skill is staying with you.",
            "Nice job on the review question.",
            "You pulled that from memory.",
            "That review answer is correct.",
            "You kept the earlier skill alive.",
        ],
    }
    for state, lines in correct_states.items():
        add_numbered_lines(
            clips,
            seen_ids,
            prefix=f"fb-correct-{state.replace('_', '-')}",
            category="feedback.correct",
            lines=lines,
            priority="must_have",
            state=state,
            tags=["correct", state],
        )

    retry_states = {
        "first_miss": [
            "Not quite yet. Take another look.",
            "Close thinking. Check one part again.",
            "Good try. There is one clue to revisit.",
            "Almost. Slow down and test it.",
            "You are near it. Try one more time.",
            "That answer does not fit yet.",
            "Pause and compare before you tap.",
            "Look back at the picture.",
            "Check the numbers one more time.",
            "Try a different strategy.",
            "Good effort. The next look matters.",
            "Not yet. Search for the clue.",
            "You can adjust one part.",
            "Take a breath and check again.",
            "This is a good time to slow down.",
            "The answer is close, but not that one.",
            "Look at the visual before choosing again.",
            "Try naming what you see first.",
        ],
        "repeated_miss": [
            "Let's use a hint before the next try.",
            "This one is being tricky. We can break it into steps.",
            "Pause with me. What do we know first?",
            "Let's find the first clue together.",
            "You do not have to guess. Use the visual helper.",
            "Let's slow this one down.",
            "Try naming the parts before choosing.",
            "A smaller step will help here.",
            "Let's check the picture and the answer choices.",
            "We can solve this one piece at a time.",
            "This problem needs a helper step.",
            "Let's switch strategies.",
            "The visual can show the answer.",
            "Try the hint, then choose again.",
            "Let's look for what changed.",
            "This is a learning moment, not a stopping point.",
            "We can make this easier to see.",
            "Let's solve the first part together.",
        ],
        "idk": [
            "Good choice asking for help.",
            "It is smart to use a hint when you need one.",
            "Let's make the problem easier.",
            "You asked for support. That is learning.",
            "We can start with one small clue.",
            "Let's look at the visual together.",
            "No guessing needed. We can use a strategy.",
            "A hint can help you see the first step.",
            "Let's find what the problem is asking.",
            "Good pause. Now let's choose a helper.",
        ],
    }
    for state, lines in retry_states.items():
        add_numbered_lines(
            clips,
            seen_ids,
            prefix=f"fb-retry-{state.replace('_', '-')}",
            category="feedback.retry",
            lines=lines,
            priority="must_have",
            state=state,
            tags=["retry", state],
        )

    hint_groups = {
        "intro": [
            "Here is a small clue.",
            "Let's make the problem easier to see.",
            "Try this helper.",
            "Look at it this way.",
            "I will show one step.",
            "Let's use the picture.",
            "Here comes a strategy clue.",
            "This hint can help you check.",
            "Try the visual first.",
            "Let's find the important part.",
            "Here is the first clue.",
            "Use this to get started.",
        ],
        "strategy": [
            "Think about the strategy, then choose.",
            "Start with what you know.",
            "Break the problem into smaller parts.",
            "Compare before you calculate.",
            "Name the parts first.",
            "Use the model to test your answer.",
            "Try the step slowly.",
            "Look for the biggest clue.",
            "One careful step can unlock it.",
            "Use the answer choices to check.",
        ],
        "worked": [
            "Let's solve one step together.",
            "Watch the first step, then you finish.",
            "Here is how the helper starts.",
            "This is the part that matters.",
            "Let's connect the picture to the answer.",
            "The model shows the first move.",
            "I will show the starting step.",
            "Now use that step to choose.",
            "This example can guide your next try.",
            "Let's reason it out together.",
        ],
    }
    for state, lines in hint_groups.items():
        add_numbered_lines(
            clips,
            seen_ids,
            prefix=f"fb-hint-{state}",
            category="feedback.hint",
            lines=lines,
            priority="must_have",
            state=state,
            tags=["hint", state],
        )

    session_lines = [
        "First question. Let's warm up.",
        "You are moving through the quest.",
        "Halfway there. Keep your thinking steady.",
        "Last question. Finish strong.",
        "You got through a tricky stretch.",
        "Nice focus this round.",
        "You solved a lot of math today.",
        "That session is complete.",
        "You earned progress for showing up.",
        "Let's do one more careful solve.",
        "New session. Start with a calm brain.",
        "You are ready for the next math step.",
        "One problem at a time.",
        "Keep your eyes on the clue.",
        "You have already made progress today.",
        "This is a review moment.",
        "This question builds on what you know.",
        "Your next challenge is ready.",
        "You stayed with the session.",
        "That was steady work.",
    ]
    add_numbered_lines(
        clips,
        seen_ids,
        prefix="fb-session",
        category="feedback.session",
        lines=session_lines,
        priority="must_have",
        tags=["session"],
    )

    reward_lines = [
        "New sticker earned.",
        "That sticker is for your persistence.",
        "Your sticker book just grew.",
        "A new reward is ready.",
        "You unlocked something fun.",
        "That was earned by real thinking.",
        "You completed the step and earned a prize.",
        "The collection has a new piece.",
        "You made progress and got a reward.",
        "Nice work. Your reward is ready.",
        "That reward celebrates your effort.",
        "You added another win to your collection.",
        "A fresh sticker just opened.",
        "Your careful math unlocked this.",
        "This reward marks today's progress.",
        "A new badge is ready to view.",
        "You earned this by solving and trying.",
        "That sticker belongs in your book.",
        "Another piece of the collection is yours.",
        "You finished the quest step and earned a reward.",
    ]
    add_numbered_lines(
        clips,
        seen_ids,
        prefix="fb-reward",
        category="feedback.reward",
        lines=reward_lines,
        priority="must_have",
        tags=["reward"],
    )


def generate_domain_audio(clips: list[dict[str, Any]], seen_ids: set[str]) -> None:
    domain_lines = {
        "countAndMatch": [
            "Touch each dot once, then say the last number.",
            "The last number you count tells the total.",
            "Try moving left to right so you do not count twice.",
            "You matched the group to the number.",
            "Good counting. Each object got one number.",
            "Count slowly and point to each object.",
            "Check that every object was counted.",
            "Start at one and stop when the group is done.",
        ],
        "additionStory": [
            "Put the groups together to find the total.",
            "Count on from the bigger number.",
            "Both groups are part of the answer.",
            "The story is asking how many there are now.",
            "Add the new group to the starting group.",
            "Use fingers or counters to join the groups.",
            "The answer should be bigger than each part.",
            "You can count all to check.",
        ],
        "subtractionStory": [
            "Take away the removed group, then count what is left.",
            "Start with the whole group.",
            "Cross out the part that leaves.",
            "The answer is what remains.",
            "Subtraction asks what is left after taking away.",
            "Count back one step at a time.",
            "Make sure you remove the right amount.",
            "The answer should be smaller than the starting number.",
        ],
        "numberBond": [
            "The missing part plus the known part makes the whole.",
            "Use the ten frame to see empty spaces.",
            "Think about what number completes ten.",
            "The whole is ten, so find the other part.",
            "Count from the known part up to ten.",
            "Both parts together should make ten.",
            "The missing number fills the rest.",
            "Check by adding the two parts.",
        ],
        "shapeClassification": [
            "Trace the sides with your finger.",
            "Corners are where two sides meet.",
            "A circle has no corners and no straight sides.",
            "A triangle has three sides and three corners.",
            "A rectangle has four sides and four corners.",
            "Count sides before naming the shape.",
            "Look for equal sides if it might be a square.",
            "Use attributes, not color, to name the shape.",
        ],
        "measureLength": [
            "Start measuring at zero.",
            "Count the spaces, not just the marks.",
            "Line up the object with the ruler.",
            "The length is where the object ends.",
            "Each equal space is one unit.",
            "Do not start counting at one on the ruler.",
            "Check the start and end points.",
            "Use the unit marks to measure carefully.",
        ],
        "areaTiling": [
            "Rows times columns gives the area.",
            "Count each unit square.",
            "One row times the number of rows gives the total.",
            "The area is how many squares cover the rectangle.",
            "You can skip-count by the row length.",
            "Every square inside the rectangle counts.",
            "Find rows first, then columns.",
            "Multiply the two side lengths.",
        ],
        "angleMeasure": [
            "A 90-degree angle is a square corner.",
            "Compare the angle to a square corner.",
            "A wider opening means more degrees.",
            "An acute angle is smaller than 90 degrees.",
            "An obtuse angle is bigger than 90 degrees.",
            "Look at how far the ray opens.",
            "Use the protractor marks to check.",
            "The angle measure tells how wide it opens.",
        ],
        "dataPlot": [
            "Read the label first, then the bar height.",
            "The tallest bar shows the most.",
            "Count the marks above the category.",
            "Use the graph to compare values.",
            "Check the axis before choosing.",
            "Each picture or X counts as one data point.",
            "Find the category the question asks about.",
            "Compare the heights carefully.",
        ],
        "fractionComparison": [
            "Equal parts matter first.",
            "The denominator tells how many equal pieces.",
            "The numerator tells how many pieces are shaded.",
            "When denominators match, compare the numerators.",
            "When numerators match, fewer pieces means bigger pieces.",
            "Use one half as a benchmark.",
            "Compare the size of the shaded parts.",
            "Make sure the wholes are the same size.",
        ],
        "volumePrism": [
            "Build one layer first.",
            "Length times width gives one layer.",
            "Then multiply by the height.",
            "Volume counts the cubes that fill the prism.",
            "Every equal layer has the same number of cubes.",
            "Stack the layers to find the total.",
            "Use three dimensions: length, width, and height.",
            "The answer is in cubic units.",
        ],
        "ratioTable": [
            "Look at how both numbers grow.",
            "Find the same multiplier in each row.",
            "A ratio pattern changes both sides together.",
            "Use the completed row to find the missing row.",
            "Compare left to right before choosing.",
            "Each row should keep the same relationship.",
            "Scale both numbers by the same amount.",
            "Check that the pattern is consistent.",
        ],
    }
    for fmt, lines in domain_lines.items():
        add_numbered_lines(
            clips,
            seen_ids,
            prefix=f"coach-{fmt.lower()}",
            category="coaching.domain",
            lines=lines,
            priority="must_have",
            state="domain_strategy",
            domain="math",
            fmt=fmt,
            tags=["domain", fmt],
        )


def generate_correction_audio(clips: list[dict[str, Any]], seen_ids: set[str]) -> None:
    general_lines = [
        "The answer is correct when it matches the visual model.",
        "Let's solve this one together before the next question.",
        "The important clue was hiding in the picture.",
        "This is the step that changes the answer.",
        "Watch how the first step points to the answer.",
        "The answer choice works because it fits every clue.",
        "Let's name what we know first.",
        "The model shows why that answer fits.",
        "This problem gets easier when we slow it down.",
        "The first clue tells us what to compare.",
        "A careful check shows which answer belongs.",
        "Now you can use the same strategy on the next one.",
        "The mistake was only one step away from the answer.",
        "Let's connect the words to the picture.",
        "The visual helper proves the answer.",
        "This is a good example to remember.",
        "The answer makes sense because it matches the structure.",
        "Let's use the choices to check our thinking.",
        "The correct answer is the one that satisfies the whole question.",
        "You can try this same move next time.",
    ]
    add_numbered_lines(
        clips,
        seen_ids,
        prefix="fb-correction-general",
        category="feedback.correction",
        lines=general_lines,
        priority="must_have",
        state="correction_overlay",
        tags=["correction", "worked_step"],
    )

    domain_corrections = {
        "countAndMatch": [
            "Count each object once. The last number you say is the answer.",
            "If an object was skipped, the count is too small.",
            "If an object was counted twice, the count is too big.",
            "Touch, count, move on. That keeps the total accurate.",
            "The picture shows the total when every object gets one count.",
            "The matching number is the final count.",
        ],
        "numberBond": [
            "The two parts must make the whole.",
            "Count from the known part up to ten to find the missing part.",
            "The empty spaces on the ten frame show the missing number.",
            "Check by adding both parts together.",
            "If the parts make more than ten, the missing part is too big.",
            "If the parts make less than ten, the missing part is too small.",
        ],
        "additionStory": [
            "Addition joins the groups.",
            "The answer should include the starting group and the new group.",
            "Count on from the bigger number to find the total.",
            "The story asks how many there are altogether.",
            "If one group is missing, the total will be too small.",
            "The sum is the amount after both groups are together.",
        ],
        "subtractionStory": [
            "Subtraction starts with the whole and takes part away.",
            "The answer is the group that remains.",
            "Cross out the removed amount before counting leftovers.",
            "If you forgot to take away, the answer is too big.",
            "Count back by the amount that leaves.",
            "The leftover group proves the answer.",
        ],
        "shapeClassification": [
            "Shape names come from attributes, not color or size.",
            "Trace every side before naming the shape.",
            "Corners are the points where sides meet.",
            "A square is a special rectangle with equal sides.",
            "A circle has no straight sides and no corners.",
            "The side count is the clue that names the polygon.",
        ],
        "measureLength": [
            "Measurement starts at zero.",
            "The length is the number of equal spaces the object covers.",
            "Counting marks instead of spaces can change the answer.",
            "Line up the start of the object with zero.",
            "The endpoint shows the length.",
            "Each unit space counts once.",
        ],
        "areaTiling": [
            "Area counts all the square units inside.",
            "Rows and columns make an array.",
            "Multiply rows by columns to find the total squares.",
            "If a row is skipped, the area is too small.",
            "The rectangle is covered by equal square units.",
            "The grid proves the multiplication answer.",
        ],
        "angleMeasure": [
            "A right angle is 90 degrees.",
            "Smaller than a right angle means less than 90 degrees.",
            "Bigger than a right angle means more than 90 degrees.",
            "The measure tells how wide the angle opens.",
            "Compare the angle to the benchmark before choosing.",
            "The protractor arc points to the degree measure.",
        ],
        "fractionComparison": [
            "Fractions compare shaded parts of equal wholes.",
            "When denominators match, compare numerators.",
            "When numerators match, the smaller denominator makes bigger pieces.",
            "A benchmark like one half can help.",
            "The bigger shaded amount is the bigger fraction.",
            "Equal parts must be the same size before comparing.",
        ],
        "solidAttributes": [
            "A solid is three-dimensional.",
            "Faces are flat surfaces.",
            "Edges are where faces meet.",
            "Vertices are corner points.",
            "Curved surfaces help identify cylinders, cones, and spheres.",
            "Match the clue to faces, edges, vertices, or curved parts.",
        ],
        "gridPath": [
            "Follow one direction at a time.",
            "Right and left move across the row.",
            "Up and down move between rows.",
            "The landing space is the answer.",
            "Restart at the starting object if the path gets confusing.",
            "Count each grid step carefully.",
        ],
        "symmetryMirror": [
            "A mirror line makes two matching halves.",
            "Each part should have a matching part across the line.",
            "If one side is flipped the wrong way, it will not match.",
            "Imagine folding on the mirror line.",
            "The matching half completes the picture.",
            "Symmetry means both sides line up.",
        ],
    }
    for fmt, lines in domain_corrections.items():
        add_numbered_lines(
            clips,
            seen_ids,
            prefix=f"fb-correction-{fmt.lower()}",
            category="feedback.correction",
            lines=lines,
            priority="must_have",
            state="correction_overlay",
            fmt=fmt,
            tags=["correction", "worked_step", fmt],
        )


def generate_companion_personality_audio(clips: list[dict[str, Any]], seen_ids: set[str]) -> None:
    theme_lines = {
        "space": [
            "Mission step complete.",
            "Your math rocket is steady.",
            "That answer is cleared for launch.",
            "Nice orbit around that tricky clue.",
            "You found the signal in the stars.",
            "Mission control saw that smart move.",
            "That solve has star power.",
            "You navigated the number path.",
            "Another bright mission win.",
            "Your focus is in orbit.",
            "That was a smooth landing.",
            "Next stop, another careful solve.",
        ],
        "candy": [
            "Sweet solve.",
            "That answer is a treat.",
            "You sprinkled careful thinking on that one.",
            "Nice job following the candy trail.",
            "That was a tasty bit of math.",
            "You found the sweet spot.",
            "A little focus made that one pop.",
            "That clue was wrapped up nicely.",
            "You solved it with extra care.",
            "Another sweet win.",
            "That answer sticks.",
            "Keep rolling through the trail.",
        ],
        "ocean": [
            "Nice wave of thinking.",
            "You found the answer below the surface.",
            "That was a smooth swim through the problem.",
            "You followed the current of clues.",
            "Great catch.",
            "You kept your thinking afloat.",
            "That answer sailed in.",
            "Careful counting kept you on course.",
            "You spotted the hidden clue.",
            "Another splash of progress.",
            "You steered through the challenge.",
            "That solve was clear as water.",
        ],
        "superhero": [
            "Heroic thinking.",
            "You used your strategy power.",
            "That was a brave check.",
            "You saved the answer with careful work.",
            "Your focus shield held strong.",
            "Math hero move.",
            "You spotted the clue in time.",
            "That answer is mission-ready.",
            "You used your problem-solving strength.",
            "Strong brain power.",
            "You handled that challenge.",
            "Another hero point earned.",
        ],
        "rainbow": [
            "Bright thinking.",
            "That answer shines.",
            "You found the colorful clue.",
            "Nice sparkle of strategy.",
            "That solve is glowing.",
            "You followed the bright path.",
            "A careful choice made the answer shine.",
            "You added color to your progress.",
            "That was a cheerful bit of math.",
            "Your focus is bright today.",
            "Another rainbow step complete.",
            "You made the tricky part clearer.",
        ],
        "turbo": [
            "Smooth drive.",
            "You shifted into smart thinking.",
            "That answer crossed the finish line.",
            "Nice control on that turn.",
            "You checked the road before choosing.",
            "That solve had good traction.",
            "You kept the math engine steady.",
            "Careful speed wins.",
            "You drove right to the clue.",
            "Another lap complete.",
            "That was a clean pass.",
            "Ready for the next turn.",
        ],
    }
    for theme, lines in theme_lines.items():
        add_numbered_lines(
            clips,
            seen_ids,
            prefix=f"companion-{theme}",
            category="companion.theme",
            lines=lines,
            priority="strong_pack",
            tone="playful",
            state="theme_reaction",
            tags=["companion", theme],
        )


def generate_k1_prompt_audio(clips: list[dict[str, Any]], seen_ids: set[str]) -> None:
    lines_by_group = {
        "counting": [
            "Count the objects and tap the number.",
            "How many objects are in the group?",
            "Point to each object as you count.",
            "Which number matches the group?",
            "Count the pictures from left to right.",
            "What is the total number of objects?",
            "Say each number as you count.",
            "Tap the answer that shows how many.",
        ],
        "compare_groups": [
            "Which group has more?",
            "Which group has fewer?",
            "Do the groups have the same amount?",
            "Count both groups before you choose.",
            "Compare the two groups.",
            "Which side has the bigger group?",
            "Which group has the smaller count?",
            "Look at both groups carefully.",
        ],
        "number_bonds": [
            "What number makes ten?",
            "Find the missing part.",
            "Which part completes the whole?",
            "What goes with this number to make ten?",
            "Use the ten frame to find the missing number.",
            "Which answer fills the empty spaces?",
            "Find the partner number.",
            "Two parts make ten. What is missing?",
        ],
        "addition": [
            "Put the groups together. How many in all?",
            "Count on to find the total.",
            "What is the sum?",
            "How many are there after more are added?",
            "Add the two groups.",
            "Which answer shows the total?",
            "Start with the bigger number and count on.",
            "Join the parts and choose the answer.",
        ],
        "subtraction": [
            "Take some away. How many are left?",
            "What remains after some leave?",
            "Count back to find the answer.",
            "Which answer shows what is left?",
            "Start with the whole group, then remove some.",
            "How many are still there?",
            "Cross out the take-away part.",
            "Find the leftover amount.",
        ],
        "shapes": [
            "Which shape do you see?",
            "How many sides does the shape have?",
            "How many corners does the shape have?",
            "Find the shape with these attributes.",
            "Trace the sides, then choose.",
            "Which shape has no corners?",
            "Which shape has four corners?",
            "Name the shape in the picture.",
        ],
        "measurement": [
            "How long is the object?",
            "Measure the object in units.",
            "Start at zero and count the spaces.",
            "Which answer matches the object's length?",
            "Where does the object end on the ruler?",
            "Count the unit spaces carefully.",
            "Use the ruler to choose.",
            "Find the length.",
        ],
        "spatial": [
            "Which object is above?",
            "Which object is below?",
            "Which object is beside it?",
            "Which object is inside?",
            "Which object is outside?",
            "Move right on the grid.",
            "Move left on the grid.",
            "Follow the direction words.",
        ],
    }
    for group, lines in lines_by_group.items():
        add_numbered_lines(
            clips,
            seen_ids,
            prefix=f"prompt-k1-{group.replace('_', '-')}",
            category="prompt.k1",
            lines=lines,
            priority="strong_pack",
            state="prompt_variant",
            domain="early_math",
            tags=["prompt", "k1", group],
        )


def generate_prompt_variant_audio(clips: list[dict[str, Any]], seen_ids: set[str]) -> None:
    variants = {
        "countAndMatch": [
            "Count the dots. Which number matches?",
            "How many dots do you see?",
            "Touch each dot as you count. What is the total?",
            "Find the number that matches the dots.",
            "Count every dot one time.",
            "Which answer shows the dot total?",
            "Say the numbers as you count the dots.",
            "Look carefully. How many dots are there?",
            "Count the group and tap the total.",
            "What number belongs with this group?",
        ],
        "measureLength": [
            "Start at zero. How long is the object?",
            "Count the unit spaces. What is the length?",
            "How many ruler units does it cover?",
            "Measure from the start to the end.",
            "What number does the object reach?",
            "Count the spaces along the ruler.",
            "Find the length in units.",
            "Which length matches the object?",
            "Use the ruler to measure the object.",
            "How many equal units long is it?",
        ],
        "angleMeasure": [
            "How wide is this angle?",
            "Choose the angle measure.",
            "Is it smaller or bigger than 90 degrees?",
            "What degree measure matches the opening?",
            "Read the angle and choose the degrees.",
            "How many degrees does this angle show?",
            "Find the measure of the angle.",
            "Compare it to a right angle, then choose.",
            "What number belongs on the angle?",
            "Which degree answer fits?",
        ],
        "shapeClassification": [
            "Trace the sides. Which shape is this?",
            "Count the corners. What shape do you see?",
            "This shape has three sides. What is its name?",
            "Which shape matches these attributes?",
            "Look at the sides and corners. Name the shape.",
            "Find the shape with four sides.",
            "Which answer names this shape?",
            "What shape has these sides and corners?",
            "Use the attributes to choose the shape.",
            "Look closely. What is this shape called?",
        ],
        "timeMoney": [
            "Look at the clock hands. What time is it?",
            "The short hand shows the hour. What time is shown?",
            "Count by fives around the clock.",
            "How many cents are the coins worth?",
            "Count the biggest coins first.",
            "Which money value matches the coins?",
            "Read the hour, then the minutes.",
            "Find the value of the coin group.",
        ],
        "dataPlot": [
            "Read the graph. Which value matches?",
            "Which bar shows the most?",
            "How many data points are in this category?",
            "Use the chart labels to answer.",
            "Compare the bar heights.",
            "Which category has fewer?",
            "Count the marks on the line plot.",
            "Find the data point the question asks about.",
        ],
        "areaTiling": [
            "Count the rows and columns.",
            "How many square units cover the rectangle?",
            "Find the area of the tiled rectangle.",
            "Multiply the side lengths to find the area.",
            "How many tiles are inside?",
            "Use the grid to find the total squares.",
            "Each square is one unit. What is the area?",
            "Which answer matches the tiled area?",
        ],
    }
    for fmt, lines in variants.items():
        add_numbered_lines(
            clips,
            seen_ids,
            prefix=f"prompt-{fmt.lower()}",
            category="prompt.variant",
            lines=lines,
            priority="strong_pack",
            state="prompt_variant",
            fmt=fmt,
            tags=["prompt_variant", fmt],
        )


def generate_spatial_vocab_audio(clips: list[dict[str, Any]], seen_ids: set[str]) -> None:
    words = [
        "circle", "triangle", "square", "rectangle", "oval", "diamond",
        "rhombus", "trapezoid", "pentagon", "hexagon", "octagon", "cube",
        "cone", "cylinder", "sphere", "pyramid", "rectangular prism",
        "side", "sides", "corner", "corners", "angle", "angles", "face",
        "faces", "edge", "edges", "vertex", "vertices", "flat", "curved",
        "round", "point", "points", "equal sides", "parallel sides",
        "above", "below", "left", "right", "beside", "between", "inside",
        "outside", "next to", "under", "over", "near", "far", "same",
        "different", "match", "turn", "rotate", "flip", "slide", "mirror",
        "symmetry", "half", "whole", "row", "column", "grid", "path",
        "clockwise", "counterclockwise", "fold", "net", "opposite",
        "adjacent", "top", "bottom", "front", "back",
    ]
    for idx, word in enumerate(words, 1):
        add_clip(
            clips,
            seen_ids,
            id_=f"vocab-spatial-{idx:03d}",
            category="vocabulary.spatial",
            text=word,
            priority="must_have",
            tone="clear",
            state="vocabulary",
            domain="geometry",
            tags=["vocabulary", "spatial"],
        )


def generate_spatial_question_audio(
    clips: list[dict[str, Any]],
    seen_ids: set[str],
    spatial_items: list[dict[str, Any]],
) -> None:
    for item in spatial_items:
        add_clip(
            clips,
            seen_ids,
            id_=f"audio-{item['id']}",
            category="question.spatial",
            text=item["spokenForm"],
            priority="strong_pack",
            tone="playful",
            state="question",
            domain="geometry",
            fmt=item["format"],
            tags=["question", "spatial", item["unit"], item["format"]],
        )


def generate_system_audio(clips: list[dict[str, Any]], seen_ids: set[str]) -> None:
    lines = [
        "Audio is ready.",
        "Voice is muted.",
        "Voice is back on.",
        "I can read the next question.",
        "Tap the speaker to hear it again.",
        "The recording is not available yet, so I will use the device voice.",
        "Let's try the playful voice.",
        "Let's try the calm voice.",
        "Let's try the energetic voice.",
        "Let's try the storyteller voice.",
        "Your helper voice is set.",
        "Narration is on.",
        "Narration is off.",
        "This question has a visual helper.",
        "This question has a strategy hint.",
        "This question has a worked step.",
        "Ready for the next one.",
        "Take your time.",
        "You can hear the question again.",
        "Settings saved.",
    ]
    add_numbered_lines(
        clips,
        seen_ids,
        prefix="system-audio",
        category="system",
        lines=lines,
        priority="must_have",
        tone="clear",
        state="system",
        tags=["system"],
    )


def generate_audio_manifest(spatial_bank: dict[str, Any]) -> dict[str, Any]:
    clips: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    generate_feedback_audio(clips, seen_ids)
    generate_domain_audio(clips, seen_ids)
    generate_correction_audio(clips, seen_ids)
    generate_companion_personality_audio(clips, seen_ids)
    generate_k1_prompt_audio(clips, seen_ids)
    generate_prompt_variant_audio(clips, seen_ids)
    generate_spatial_vocab_audio(clips, seen_ids)
    generate_spatial_question_audio(clips, seen_ids, spatial_bank["items"])
    generate_system_audio(clips, seen_ids)

    counts_by_category: dict[str, int] = {}
    counts_by_priority: dict[str, int] = {}
    for clip in clips:
        counts_by_category[clip["category"]] = counts_by_category.get(clip["category"], 0) + 1
        counts_by_priority[clip["priority"]] = counts_by_priority.get(clip["priority"], 0) + 1

    return {
        "metadata": {
            "id": "audio-recording-set-2026-04-26",
            "generatedBy": "scripts/generate_future_question_audio_sets.py",
            "date": "2026-04-26",
            "purpose": "Expanded ElevenLabs recording backlog for richer feedback, prompt variety, and future spatial exercises.",
            "clipCount": len(clips),
            "estimatedCharacters": sum(len(clip["text"]) for clip in clips),
            "countsByCategory": counts_by_category,
            "countsByPriority": counts_by_priority,
            "notes": [
                "This manifest is recording input, not an app runtime audio_index replacement.",
                "Use priority=must_have first if the ElevenLabs subscription window is short.",
                "question.spatial clips correspond to MathQuestKids/Content/spatial-question-bank-v2.json.",
            ],
        },
        "clips": clips,
    }


def validate_spatial_bank(spatial_bank: dict[str, Any]) -> None:
    items = spatial_bank["items"]
    ids = [item["id"] for item in items]
    if len(ids) != len(set(ids)):
        raise ValueError("Duplicate spatial question IDs")
    if len(items) != 560:
        raise ValueError(f"Expected 560 spatial items, got {len(items)}")
    for item in items:
        if not item["prompt"].strip():
            raise ValueError(f"Missing prompt for {item['id']}")
        if item["answer"] not in item["choices"]:
            raise ValueError(f"Answer not in choices for {item['id']}: {item['answer']}")
        for key in ("concrete", "strategy", "worked"):
            if not item["hint"].get(key):
                raise ValueError(f"Missing {key} hint for {item['id']}")


def validate_audio_manifest(audio_manifest: dict[str, Any]) -> None:
    clips = audio_manifest["clips"]
    ids = [clip["id"] for clip in clips]
    if len(ids) != len(set(ids)):
        raise ValueError("Duplicate audio clip IDs")
    for clip in clips:
        if not clip["text"].strip():
            raise ValueError(f"Missing audio text for {clip['id']}")
        if not clip["file"].endswith(".mp3"):
            raise ValueError(f"Invalid output file path for {clip['id']}")


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def write_audio_csv(path: Path, audio_manifest: dict[str, Any]) -> None:
    fields = [
        "id", "category", "priority", "tone", "state", "domain", "format",
        "text", "filename", "file", "tags",
    ]
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for clip in audio_manifest["clips"]:
            writer.writerow({
                "id": clip["id"],
                "category": clip["category"],
                "priority": clip["priority"],
                "tone": clip["tone"],
                "state": clip["state"] or "",
                "domain": clip["domain"],
                "format": clip["format"] or "",
                "text": clip["text"],
                "filename": clip["filename"],
                "file": clip["file"],
                "tags": "|".join(clip["tags"]),
            })


def main() -> None:
    spatial_bank = generate_spatial_bank()
    validate_spatial_bank(spatial_bank)

    audio_manifest = generate_audio_manifest(spatial_bank)
    validate_audio_manifest(audio_manifest)

    write_json(SPATIAL_BANK_PATH, spatial_bank)
    write_json(AUDIO_JSON_PATH, audio_manifest)
    write_audio_csv(AUDIO_CSV_PATH, audio_manifest)

    print("Generated future MathQuest Kids content/audio sets")
    print(f"  Spatial question bank: {SPATIAL_BANK_PATH.relative_to(PROJECT_ROOT)}")
    print(f"    Items: {spatial_bank['metadata']['itemCount']}")
    for fmt, count in sorted(spatial_bank["metadata"]["countsByFormat"].items()):
        print(f"    {fmt}: {count}")
    print(f"  Audio recording JSON: {AUDIO_JSON_PATH.relative_to(PROJECT_ROOT)}")
    print(f"    Clips: {audio_manifest['metadata']['clipCount']}")
    print(f"    Estimated chars: {audio_manifest['metadata']['estimatedCharacters']:,}")
    for category, count in sorted(audio_manifest["metadata"]["countsByCategory"].items()):
        print(f"    {category}: {count}")
    print(f"  Audio recording CSV: {AUDIO_CSV_PATH.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
