# Corrected Questions

Generated from the diff of `content-pack-v1.json` before and after `scripts/fix_question_bank.py`. **331 questions changed.** `answer` and `spokenForm` are unchanged for every item (so no narration text changed and no audio was touched); only `payload`, `choices` and 20 on-screen `prompt` lines were edited. `spatial-question-bank-v2.json` was synced to match.

| Format | Questions changed | What changed |
|---|---:|---|
| buildShape | 10 | distractor 'two triangles' (which can build a rectangle) replaced by 'two pentagons' |
| dataPlot | 7 | 3 ties for 'most' broken by raising the keyed bar by 1; 4 'how many more X than Y' items had X < Y, so the two bar values were swapped (key 1 is now right) |
| gridPath | 80 | 10 paths that left the 6x6 grid had their start cell shifted; all 80 gained an object layout (`payload.objects`) so the map can be drawn; 20 prompts now state their moves on screen |
| netPreview | 40 | options rebuilt so exactly one net folds into a cube (verified by a cube-rolling simulation); each option carries drawable `cells` |
| positionWords | 32 | objects sharing a cell moved to free cells so exactly one choice is above/below/beside the anchor |
| rotateToMatch | 47 | mirrored copies of mirror-symmetric shapes became plain rotations; options that looked identical were given distinct rotations |
| shapeHunt | 55 | shapes stacked in one cell moved to free cells, so no target can be hidden |
| symmetryMirror | 60 | each item gained a drawable half-picture (`halfCells`) and each option drawable `cells`; exactly one option is the true mirror image |

## Before and after for the answer-key fixes

| Id | Prompt | Answer | Before | After |
|---|---|---|---|---|
| data-023 | Which has the most? | Apples | bars [8, 3, 8, 8] | bars [9, 3, 8, 8] |
| data-025 | Which has the most? | Spring | bars [8, 4, 5, 8] | bars [9, 4, 5, 8] |
| data-026 | How many more Fish than Birds? | 1 | bars [5, 4, 5, 6] | bars [5, 4, 6, 5] |
| data-027 | How many more Dogs than Fish? | 1 | bars [3, 3, 4, 7] | bars [3, 4, 3, 7] |
| data-028 | How many more Yellow than Blue? | 1 | bars [2, 7, 7, 6] | bars [2, 6, 7, 7] |
| data-029 | How many more Cats than Fish? | 3 | bars [4, 7, 7, 10] | bars [7, 7, 4, 10] |
| lpf-017 | Which fraction has the most data points? | 1/3 | bars [6, 6] | bars [7, 6] |
| sp-build-shape-001 | On the star map, which pieces can build a rectangle? | two squares | choices ['two squares', 'two triangles', 'two circles', 'one triangle and one circle'] | choices ['two squares', 'two pentagons', 'two circles', 'one triangle and one circle'] |
| sp-build-shape-007 | On the rainbow mat, which set of shapes composes a rectangle? | two squares | choices ['two squares', 'two triangles', 'two circles', 'one triangle and one circle'] | choices ['two squares', 'two pentagons', 'two circles', 'one triangle and one circle'] |
| sp-build-shape-013 | On the mountain path, which pieces can build a rectangle? | two squares | choices ['two squares', 'two triangles', 'two circles', 'one triangle and one circle'] | choices ['two squares', 'two pentagons', 'two circles', 'one triangle and one circle'] |
| sp-build-shape-019 | On the garden board, which set of shapes composes a rectangle? | two squares | choices ['two squares', 'two triangles', 'two circles', 'one triangle and one circle'] | choices ['two squares', 'two pentagons', 'two circles', 'one triangle and one circle'] |
| sp-build-shape-025 | On the puzzle shelf, which pieces can build a rectangle? | two squares | choices ['two squares', 'two triangles', 'two circles', 'one triangle and one circle'] | choices ['two squares', 'two pentagons', 'two circles', 'one triangle and one circle'] |
| sp-build-shape-031 | On the beach board, which set of shapes composes a rectangle? | two squares | choices ['two squares', 'two triangles', 'two circles', 'one triangle and one circle'] | choices ['two squares', 'two pentagons', 'two circles', 'one triangle and one circle'] |
| sp-build-shape-037 | On the treasure path, which pieces can build a rectangle? | two squares | choices ['two squares', 'two triangles', 'two circles', 'one triangle and one circle'] | choices ['two squares', 'two pentagons', 'two circles', 'one triangle and one circle'] |
| sp-build-shape-043 | On the number meadow, which set of shapes composes a rectangle? | two squares | choices ['two squares', 'two triangles', 'two circles', 'one triangle and one circle'] | choices ['two squares', 'two pentagons', 'two circles', 'one triangle and one circle'] |
| sp-build-shape-049 | On the forest map, which pieces can build a rectangle? | two squares | choices ['two squares', 'two triangles', 'two circles', 'one triangle and one circle'] | choices ['two squares', 'two pentagons', 'two circles', 'one triangle and one circle'] |
| sp-build-shape-055 | On the reef picture, which set of shapes composes a rectangle? | two squares | choices ['two squares', 'two triangles', 'two circles', 'one triangle and one circle'] | choices ['two squares', 'two pentagons', 'two circles', 'one triangle and one circle'] |

## gridPath: the 10 paths that left the grid ("10 grid-path fixes")

| Id | Moves | Start before | Start after | End before | End after | Answer |
|---|---|---|---|---|---|---|
| sp-grid-path-006 | 2 left and 1 up | (1,2) | (2,2) | (-1,1) | (0,1) | kite |
| sp-grid-path-014 | 2 left and 1 up | (1,2) | (2,2) | (-1,1) | (0,1) | moon |
| sp-grid-path-022 | 2 left and 1 up | (1,3) | (2,3) | (-1,2) | (0,2) | gem |
| sp-grid-path-030 | 2 left and 1 up | (1,2) | (2,2) | (-1,1) | (0,1) | kite |
| sp-grid-path-038 | 2 left and 1 up | (1,2) | (2,2) | (-1,1) | (0,1) | moon |
| sp-grid-path-046 | 2 left and 1 up | (1,3) | (2,3) | (-1,2) | (0,2) | gem |
| sp-grid-path-054 | 2 left and 1 up | (1,2) | (2,2) | (-1,1) | (0,1) | kite |
| sp-grid-path-062 | 2 left and 1 up | (1,2) | (2,2) | (-1,1) | (0,1) | moon |
| sp-grid-path-070 | 2 left and 1 up | (1,3) | (2,3) | (-1,2) | (0,2) | gem |
| sp-grid-path-078 | 2 left and 1 up | (1,2) | (2,2) | (-1,1) | (0,1) | kite |

## gridPath: prompts that now state their moves

| Id | Before | After |
|---|---|---|
| sp-grid-path-004 | On the reef picture, trace the moves from gem. What do you reach? | On the reef picture, trace the moves from gem: 2 up and 1 left. What do you reach? |
| sp-grid-path-008 | On the puzzle shelf, trace the moves from moon. What do you reach? | On the puzzle shelf, trace the moves from moon: 2 up. What do you reach? |
| sp-grid-path-012 | On the playroom grid, trace the moves from kite. What do you reach? | On the playroom grid, trace the moves from kite: 2 up and 1 left. What do you reach? |
| sp-grid-path-016 | On the classroom chart, trace the moves from gem. What do you reach? | On the classroom chart, trace the moves from gem: 2 up. What do you reach? |
| sp-grid-path-020 | On the treasure path, trace the moves from moon. What do you reach? | On the treasure path, trace the moves from moon: 2 up and 1 left. What do you reach? |
| sp-grid-path-024 | On the rainbow mat, trace the moves from kite. What do you reach? | On the rainbow mat, trace the moves from kite: 2 up. What do you reach? |
| sp-grid-path-028 | On the sticker scene, trace the moves from gem. What do you reach? | On the sticker scene, trace the moves from gem: 2 up and 1 left. What do you reach? |
| sp-grid-path-032 | On the forest map, trace the moves from moon. What do you reach? | On the forest map, trace the moves from moon: 2 up. What do you reach? |
| sp-grid-path-036 | On the garden board, trace the moves from kite. What do you reach? | On the garden board, trace the moves from kite: 2 up and 1 left. What do you reach? |
| sp-grid-path-040 | On the rocket panel, trace the moves from gem. What do you reach? | On the rocket panel, trace the moves from gem: 2 up. What do you reach? |
| sp-grid-path-044 | On the shape station, trace the moves from moon. What do you reach? | On the shape station, trace the moves from moon: 2 up and 1 left. What do you reach? |
| sp-grid-path-048 | On the beach board, trace the moves from kite. What do you reach? | On the beach board, trace the moves from kite: 2 up. What do you reach? |
| sp-grid-path-052 | On the star map, trace the moves from gem. What do you reach? | On the star map, trace the moves from gem: 2 up and 1 left. What do you reach? |
| sp-grid-path-056 | On the candy trail, trace the moves from moon. What do you reach? | On the candy trail, trace the moves from moon: 2 up. What do you reach? |
| sp-grid-path-060 | On the number meadow, trace the moves from kite. What do you reach? | On the number meadow, trace the moves from kite: 2 up and 1 left. What do you reach? |
| sp-grid-path-064 | On the mountain path, trace the moves from gem. What do you reach? | On the mountain path, trace the moves from gem: 2 up. What do you reach? |
| sp-grid-path-068 | On the festival board, trace the moves from moon. What do you reach? | On the festival board, trace the moves from moon: 2 up and 1 left. What do you reach? |
| sp-grid-path-072 | On the reef picture, trace the moves from kite. What do you reach? | On the reef picture, trace the moves from kite: 2 up. What do you reach? |
| sp-grid-path-076 | On the puzzle shelf, trace the moves from gem. What do you reach? | On the puzzle shelf, trace the moves from gem: 2 up and 1 left. What do you reach? |
| sp-grid-path-080 | On the playroom grid, trace the moves from moon. What do you reach? | On the playroom grid, trace the moves from moon: 2 up. What do you reach? |

The full list of changed ids per format:

- **buildShape** (10): sp-build-shape-001, sp-build-shape-007, sp-build-shape-013, sp-build-shape-019, sp-build-shape-025, sp-build-shape-031, sp-build-shape-037, sp-build-shape-043, sp-build-shape-049, sp-build-shape-055
- **dataPlot** (7): data-023, data-025, data-026, data-027, data-028, data-029, lpf-017
- **gridPath** (80): sp-grid-path-001, sp-grid-path-002, sp-grid-path-003, sp-grid-path-004, sp-grid-path-005, sp-grid-path-006, sp-grid-path-007, sp-grid-path-008, sp-grid-path-009, sp-grid-path-010, sp-grid-path-011, sp-grid-path-012, sp-grid-path-013, sp-grid-path-014, sp-grid-path-015, sp-grid-path-016, sp-grid-path-017, sp-grid-path-018, sp-grid-path-019, sp-grid-path-020, sp-grid-path-021, sp-grid-path-022, sp-grid-path-023, sp-grid-path-024, sp-grid-path-025, sp-grid-path-026, sp-grid-path-027, sp-grid-path-028, sp-grid-path-029, sp-grid-path-030, sp-grid-path-031, sp-grid-path-032, sp-grid-path-033, sp-grid-path-034, sp-grid-path-035, sp-grid-path-036, sp-grid-path-037, sp-grid-path-038, sp-grid-path-039, sp-grid-path-040, sp-grid-path-041, sp-grid-path-042, sp-grid-path-043, sp-grid-path-044, sp-grid-path-045, sp-grid-path-046, sp-grid-path-047, sp-grid-path-048, sp-grid-path-049, sp-grid-path-050, sp-grid-path-051, sp-grid-path-052, sp-grid-path-053, sp-grid-path-054, sp-grid-path-055, sp-grid-path-056, sp-grid-path-057, sp-grid-path-058, sp-grid-path-059, sp-grid-path-060, sp-grid-path-061, sp-grid-path-062, sp-grid-path-063, sp-grid-path-064, sp-grid-path-065, sp-grid-path-066, sp-grid-path-067, sp-grid-path-068, sp-grid-path-069, sp-grid-path-070, sp-grid-path-071, sp-grid-path-072, sp-grid-path-073, sp-grid-path-074, sp-grid-path-075, sp-grid-path-076, sp-grid-path-077, sp-grid-path-078, sp-grid-path-079, sp-grid-path-080
- **netPreview** (40): sp-net-001, sp-net-002, sp-net-003, sp-net-004, sp-net-005, sp-net-006, sp-net-007, sp-net-008, sp-net-009, sp-net-010, sp-net-011, sp-net-012, sp-net-013, sp-net-014, sp-net-015, sp-net-016, sp-net-017, sp-net-018, sp-net-019, sp-net-020, sp-net-021, sp-net-022, sp-net-023, sp-net-024, sp-net-025, sp-net-026, sp-net-027, sp-net-028, sp-net-029, sp-net-030, sp-net-031, sp-net-032, sp-net-033, sp-net-034, sp-net-035, sp-net-036, sp-net-037, sp-net-038, sp-net-039, sp-net-040
- **positionWords** (32): sp-position-002, sp-position-003, sp-position-005, sp-position-010, sp-position-011, sp-position-017, sp-position-018, sp-position-019, sp-position-022, sp-position-023, sp-position-025, sp-position-030, sp-position-031, sp-position-037, sp-position-038, sp-position-039, sp-position-042, sp-position-043, sp-position-045, sp-position-050, sp-position-051, sp-position-057, sp-position-058, sp-position-059, sp-position-062, sp-position-063, sp-position-065, sp-position-070, sp-position-071, sp-position-077, sp-position-078, sp-position-079
- **rotateToMatch** (47): sp-rotate-002, sp-rotate-003, sp-rotate-004, sp-rotate-006, sp-rotate-008, sp-rotate-010, sp-rotate-011, sp-rotate-012, sp-rotate-016, sp-rotate-018, sp-rotate-019, sp-rotate-020, sp-rotate-022, sp-rotate-024, sp-rotate-026, sp-rotate-027, sp-rotate-028, sp-rotate-030, sp-rotate-032, sp-rotate-034, sp-rotate-035, sp-rotate-036, sp-rotate-040, sp-rotate-042, sp-rotate-043, sp-rotate-044, sp-rotate-046, sp-rotate-048, sp-rotate-050, sp-rotate-051, sp-rotate-052, sp-rotate-054, sp-rotate-056, sp-rotate-058, sp-rotate-059, sp-rotate-060, sp-rotate-064, sp-rotate-066, sp-rotate-067, sp-rotate-068, sp-rotate-070, sp-rotate-072, sp-rotate-074, sp-rotate-075, sp-rotate-076, sp-rotate-078, sp-rotate-080
- **shapeHunt** (55): sp-shape-hunt-001, sp-shape-hunt-002, sp-shape-hunt-003, sp-shape-hunt-004, sp-shape-hunt-005, sp-shape-hunt-006, sp-shape-hunt-007, sp-shape-hunt-008, sp-shape-hunt-009, sp-shape-hunt-012, sp-shape-hunt-013, sp-shape-hunt-014, sp-shape-hunt-018, sp-shape-hunt-019, sp-shape-hunt-024, sp-shape-hunt-027, sp-shape-hunt-028, sp-shape-hunt-029, sp-shape-hunt-030, sp-shape-hunt-031, sp-shape-hunt-032, sp-shape-hunt-033, sp-shape-hunt-034, sp-shape-hunt-035, sp-shape-hunt-036, sp-shape-hunt-037, sp-shape-hunt-038, sp-shape-hunt-039, sp-shape-hunt-042, sp-shape-hunt-043, sp-shape-hunt-046, sp-shape-hunt-047, sp-shape-hunt-048, sp-shape-hunt-049, sp-shape-hunt-050, sp-shape-hunt-051, sp-shape-hunt-054, sp-shape-hunt-057, sp-shape-hunt-058, sp-shape-hunt-059, sp-shape-hunt-060, sp-shape-hunt-061, sp-shape-hunt-062, sp-shape-hunt-063, sp-shape-hunt-064, sp-shape-hunt-065, sp-shape-hunt-066, sp-shape-hunt-067, sp-shape-hunt-068, sp-shape-hunt-069, sp-shape-hunt-072, sp-shape-hunt-073, sp-shape-hunt-074, sp-shape-hunt-078, sp-shape-hunt-079
- **symmetryMirror** (60): sp-symmetry-001, sp-symmetry-002, sp-symmetry-003, sp-symmetry-004, sp-symmetry-005, sp-symmetry-006, sp-symmetry-007, sp-symmetry-008, sp-symmetry-009, sp-symmetry-010, sp-symmetry-011, sp-symmetry-012, sp-symmetry-013, sp-symmetry-014, sp-symmetry-015, sp-symmetry-016, sp-symmetry-017, sp-symmetry-018, sp-symmetry-019, sp-symmetry-020, sp-symmetry-021, sp-symmetry-022, sp-symmetry-023, sp-symmetry-024, sp-symmetry-025, sp-symmetry-026, sp-symmetry-027, sp-symmetry-028, sp-symmetry-029, sp-symmetry-030, sp-symmetry-031, sp-symmetry-032, sp-symmetry-033, sp-symmetry-034, sp-symmetry-035, sp-symmetry-036, sp-symmetry-037, sp-symmetry-038, sp-symmetry-039, sp-symmetry-040, sp-symmetry-041, sp-symmetry-042, sp-symmetry-043, sp-symmetry-044, sp-symmetry-045, sp-symmetry-046, sp-symmetry-047, sp-symmetry-048, sp-symmetry-049, sp-symmetry-050, sp-symmetry-051, sp-symmetry-052, sp-symmetry-053, sp-symmetry-054, sp-symmetry-055, sp-symmetry-056, sp-symmetry-057, sp-symmetry-058, sp-symmetry-059, sp-symmetry-060
