#!/usr/bin/env python3
"""
Add spokenForm to every itemTemplate in content-pack-v1.json.
The spokenForm is what TTS should read aloud — natural English, no symbols.
"""

import json
import re
import sys

# ── Fraction-to-English mapping ──────────────────────────────────────────────

ORDINALS = {
    2: "half", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth",
    7: "seventh", 8: "eighth", 9: "ninth", 10: "tenth",
    11: "eleventh", 12: "twelfth"
}

ORDINALS_PLURAL = {
    2: "halves", 3: "thirds", 4: "fourths", 5: "fifths", 6: "sixths",
    7: "sevenths", 8: "eighths", 9: "ninths", 10: "tenths",
    11: "elevenths", 12: "twelfths"
}

def fraction_to_words(num, den):
    """Convert a fraction like 3/8 to 'three eighths'."""
    num, den = int(num), int(den)
    NUMS = {
        0: "zero", 1: "one", 2: "two", 3: "three", 4: "four",
        5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine",
        10: "ten", 11: "eleven", 12: "twelve"
    }
    num_word = NUMS.get(num, str(num))

    if den in ORDINALS:
        if num == 1:
            return f"{num_word} {ORDINALS[den]}"
        else:
            return f"{num_word} {ORDINALS_PLURAL[den]}"
    else:
        return f"{num_word} over {den}"


def replace_fractions(text):
    """Replace all N/M patterns with spoken form."""
    def _repl(m):
        return fraction_to_words(m.group(1), m.group(2))
    return re.sub(r'(\d+)/(\d+)', _repl, text)


# ── Decimal-to-English ───────────────────────────────────────────────────────

DIGIT_WORDS = {
    '0': 'zero', '1': 'one', '2': 'two', '3': 'three', '4': 'four',
    '5': 'five', '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine'
}

def decimal_to_words(d):
    """Convert '0.105' to 'zero point one zero five'."""
    parts = d.split('.')
    integer_part = parts[0]
    if len(parts) == 1:
        return integer_part  # no decimal
    decimal_digits = ' '.join(DIGIT_WORDS.get(c, c) for c in parts[1])
    return f"{integer_part} point {decimal_digits}"


def replace_decimals(text):
    """Replace decimal numbers with spoken form."""
    def _repl(m):
        return decimal_to_words(m.group(0))
    return re.sub(r'\b\d+\.\d+\b', _repl, text)


# ── Per-unit transformation rules ────────────────────────────────────────────

def transform_compare_2digit(prompt, item):
    """'Compare 97 and 18' → 'Which is bigger, 97 or 18?'"""
    m = re.match(r'Compare (\d+) and (\d+)', prompt)
    if m:
        return f"Which is bigger, {m.group(1)} or {m.group(2)}?"
    return prompt

def transform_compare_3digit(prompt, item):
    """'Compare 120 and 507' → 'Which is bigger, 120 or 507?'"""
    m = re.match(r'Compare (\d+) and (\d+)', prompt)
    if m:
        return f"Which is bigger, {m.group(1)} or {m.group(2)}?"
    return prompt

def transform_compare_fractions(prompt, item):
    """'Compare 1/2 and 1/3' → 'Which is bigger, one half or one third?'"""
    m = re.match(r'Compare (\d+/\d+) and (\d+/\d+)', prompt)
    if m:
        f1 = replace_fractions(m.group(1))
        f2 = replace_fractions(m.group(2))
        return f"Which is bigger, {f1} or {f2}?"
    return prompt

def transform_compare_decimals(prompt, item):
    """'Compare 0.105 and 0.648' → 'Which is bigger, zero point one zero five or zero point six four eight?'"""
    m = re.match(r'Compare ([\d.]+) and ([\d.]+)', prompt)
    if m:
        d1 = decimal_to_words(m.group(1))
        d2 = decimal_to_words(m.group(2))
        return f"Which is bigger, {d1} or {d2}?"
    # Also handle prism questions in volumeAndDecimals
    return prompt

def transform_volume_prism(prompt, item):
    """'A prism is 2 by 2 by 2. What is its volume?' → already good, just ensure ? ending"""
    return prompt if prompt.endswith('?') else prompt + '?'

def transform_fraction_of_whole(prompt, item):
    """'What is 1/2 of 4?' → 'What is one half of 4?'"""
    return replace_fractions(prompt)

def transform_subtraction_stories(prompt, item):
    """Already good natural language. Just ensure question mark."""
    # Fix 'How many now?' → 'How many do you have now?'
    prompt = prompt.replace('How many now?', 'How many do you have now?')
    return prompt

def transform_multiplication_arrays(prompt, item):
    """'2 rows of 2. How many in all?' → 'There are 2 rows with 2 in each row. How many in all?'"""
    m = re.match(r'(\d+) rows of (\d+)\. How many in all\?', prompt)
    if m:
        return f"There are {m.group(1)} rows with {m.group(2)} in each row. How many in all?"
    return prompt

def transform_teen_place_value(prompt, item):
    """
    'Show 11 as tens and ones.' → 'How many tens and ones make 11?'
    'Use blocks to make 12.' → 'How many tens and ones do you need to make 12?'
    'Build 13 with tens and ones.' → 'How many tens and ones make 13?'
    """
    m = re.match(r'Show (\d+) as tens and ones\.', prompt)
    if m:
        return f"How many tens and ones make {m.group(1)}?"

    m = re.match(r'Use blocks to make (\d+)\.', prompt)
    if m:
        return f"How many tens and ones do you need to make {m.group(1)}?"

    m = re.match(r'Build (\d+) with tens and ones\.', prompt)
    if m:
        return f"How many tens and ones make {m.group(1)}?"

    return prompt

def transform_count_objects(prompt, item):
    """'How many dots? Tap the number.' → already good"""
    return prompt

def transform_compose_decompose(prompt, item):
    """
    '? and 7 make 10. What is ?' → 'What number and 7 make 10?'
    '4 and ? make 10. What is ?' → '4 and what number make 10?'
    """
    m = re.match(r'\? and (\d+) make (\d+)\. What is \?', prompt)
    if m:
        return f"What number and {m.group(1)} make {m.group(2)}?"

    m = re.match(r'(\d+) and \? make (\d+)\. What is \?', prompt)
    if m:
        return f"{m.group(1)} and what number make {m.group(2)}?"

    return prompt

def transform_equation(prompt, item):
    """
    '2 + 1 = ?' → 'What is 2 plus 1?'
    '45 - 21 = ?' → 'What is 45 minus 21?'
    '6 + ? = 9' → '6 plus what number equals 9?'
    '? + 4 = 7' → 'What number plus 4 equals 7?'
    """
    # Pattern: N + N = ?
    m = re.match(r'(\d+)\s*\+\s*(\d+)\s*=\s*\?', prompt)
    if m:
        return f"What is {m.group(1)} plus {m.group(2)}?"

    # Pattern: N - N = ?
    m = re.match(r'(\d+)\s*-\s*(\d+)\s*=\s*\?', prompt)
    if m:
        return f"What is {m.group(1)} minus {m.group(2)}?"

    # Pattern: N × N = ? or N * N = ?
    m = re.match(r'(\d+)\s*[×\*]\s*(\d+)\s*=\s*\?', prompt)
    if m:
        return f"What is {m.group(1)} times {m.group(2)}?"

    # Pattern: N ÷ N = ? or N / N = ?
    m = re.match(r'(\d+)\s*[÷/]\s*(\d+)\s*=\s*\?', prompt)
    if m:
        return f"What is {m.group(1)} divided by {m.group(2)}?"

    # Pattern: N + ? = N
    m = re.match(r'(\d+)\s*\+\s*\?\s*=\s*(\d+)', prompt)
    if m:
        return f"{m.group(1)} plus what number equals {m.group(2)}?"

    # Pattern: ? + N = N
    m = re.match(r'\?\s*\+\s*(\d+)\s*=\s*(\d+)', prompt)
    if m:
        return f"What number plus {m.group(1)} equals {m.group(2)}?"

    # Pattern: ? - N = N
    m = re.match(r'\?\s*-\s*(\d+)\s*=\s*(\d+)', prompt)
    if m:
        return f"What number minus {m.group(1)} equals {m.group(2)}?"

    return prompt


# ── Master dispatcher ─────────────────────────────────────────────────────────

UNIT_TRANSFORMERS = {
    'twoDigitComparison': transform_compare_2digit,
    'threeDigitComparison': transform_compare_3digit,
    'fractionComparison': transform_compare_fractions,
    'fractionOfWhole': transform_fraction_of_whole,
    'subtractionStories': transform_subtraction_stories,
    'multiplicationArrays': transform_multiplication_arrays,
    'teenPlaceValue': transform_teen_place_value,
    'kCountObjects': transform_count_objects,
    'kComposeDecompose': transform_compose_decompose,
    'kAddWithin5': transform_equation,
    'kAddWithin10': transform_equation,
    'g1AddWithin20': transform_equation,
    'g1FactFamilies': transform_equation,
    'g2AddWithin100': transform_equation,
    'g2SubWithin100': transform_equation,
}

def generate_spoken_form(item):
    """Generate the spokenForm for a single item."""
    prompt = item['prompt']
    unit = item.get('unit', '')

    # volumeAndDecimals has two sub-patterns
    if unit == 'volumeAndDecimals':
        if prompt.startswith('Compare'):
            spoken = transform_compare_decimals(prompt, item)
        else:
            spoken = transform_volume_prism(prompt, item)
    elif unit in UNIT_TRANSFORMERS:
        spoken = UNIT_TRANSFORMERS[unit](prompt, item)
    else:
        spoken = prompt  # fallback: use prompt as-is

    # ── Global post-processing ──
    # Replace any remaining fraction slash notation
    spoken = replace_fractions(spoken)

    # Replace degree symbol
    spoken = spoken.replace('°', ' degrees')

    # Replace × and ÷ in any remaining contexts
    spoken = spoken.replace('×', 'times')
    spoken = spoken.replace('÷', 'divided by')

    # Replace ___ blanks
    spoken = spoken.replace('___', 'what')

    # Replace ratio colon notation (e.g., "3:2" → "3 to 2")
    spoken = re.sub(r'(\d+):(\d+)', r'\1 to \2', spoken)

    # Replace "lb" abbreviation
    spoken = re.sub(r'(\d+)\s*lb\b', r'\1 pounds', spoken)
    spoken = re.sub(r'lb\b', 'pounds', spoken)

    # Replace "= ?" at end of any remaining equations
    spoken = re.sub(r'\s*=\s*\?\s*$', '?', spoken)

    # Clean up double spaces
    spoken = re.sub(r'\s+', ' ', spoken).strip()

    # Ensure ends with punctuation
    if not spoken.endswith(('?', '.', '!')):
        spoken = spoken + '?'

    return spoken


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    input_path = 'MathQuestKids/Content/content-pack-v1.json'

    with open(input_path) as f:
        data = json.load(f)

    changed = 0
    unchanged = 0

    for item in data['itemTemplates']:
        spoken = generate_spoken_form(item)
        item['spokenForm'] = spoken
        if spoken != item['prompt']:
            changed += 1
        else:
            unchanged += 1

    with open(input_path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Done! {changed} items transformed, {unchanged} unchanged.")
    print(f"Total: {changed + unchanged} items now have spokenForm.")

    # Show samples of transformed items
    print("\n── Sample transformations ──")
    for item in data['itemTemplates']:
        if item['prompt'] != item['spokenForm']:
            print(f"  [{item['unit']}]")
            print(f"    prompt:     {item['prompt']}")
            print(f"    spokenForm: {item['spokenForm']}")
            print()
            changed -= 1
            if changed <= 1465:  # show ~20 samples
                break

    # Show all units with first transformed example
    print("\n── One example per unit ──")
    seen_units = set()
    for item in data['itemTemplates']:
        u = item['unit']
        if u not in seen_units:
            seen_units.add(u)
            print(f"  {u}:")
            print(f"    prompt:     {item['prompt']}")
            print(f"    spokenForm: {item['spokenForm']}")
            print()


if __name__ == '__main__':
    main()
