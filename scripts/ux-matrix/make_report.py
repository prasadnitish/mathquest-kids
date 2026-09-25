#!/usr/bin/env python3
"""Turn LayoutMatrixUITests results into a side-by-side device report.

  collect  (macOS)  Export one device's .xcresult attachments into
                    <out>/index.json plus downscaled JPEG screenshots.
  render   (any OS) Merge collected devices into <out>/index.html and a
                    Markdown summary (also appended to --summary, e.g.
                    $GITHUB_STEP_SUMMARY).
"""

import argparse
import html
import json
import os
import re
import shutil
import subprocess
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

NAME_RE = re.compile(r"LX__([A-Za-z0-9-]+)__(portrait|landscape)(__findings)?")
KIND_RE = re.compile(r"^\[([a-z-]+)\]\s*(.*)$")
DEVICE_ORDER = ["iphone-small", "iphone-standard", "iphone-large", "ipad-mini", "ipad-standard", "ipad-large"]
ORIENTATIONS = ["portrait", "landscape"]

# kind: (label, tone, explanation). Tone drives colour; "problem" kinds are
# the ones worth a human look.
KINDS = {
    "unreachable": ("Unreachable", "bad", "A control could not be brought on screen, even by scrolling."),
    "overlap": ("Overlap", "warn", "Two on-screen elements partly cover each other."),
    "clipped": ("Clipped", "warn", "Cut off at a screen edge. Expected for sideways-scrolling carousels."),
    "below-fold": ("Below the fold", "note", "A primary control needs scrolling to reach."),
    "small-target": ("Small target", "note", "Tap area is under Apple's 44×44 pt minimum."),
    "flow": ("Flow", "note", "The test could not reach the intended state for this screenshot."),
    "audit": ("Audit", "note", "The accessibility tree could not be read."),
    "more": ("More", "note", "Additional findings were truncated."),
}
PROBLEM_KINDS = ["unreachable", "overlap", "clipped", "below-fold"]
SUMMARY_KINDS = ["unreachable", "overlap", "clipped", "below-fold", "small-target"]


# ---------------------------------------------------------------- collect

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def xcresult_summary(xcresult):
    for extra in ([], ["--format", "json"]):
        proc = run(["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(xcresult), *extra])
        if proc.returncode == 0:
            try:
                return json.loads(proc.stdout)
            except json.JSONDecodeError:
                continue
    return None


def walk(node):
    if isinstance(node, dict):
        yield node
        for value in node.values():
            yield from walk(value)
    elif isinstance(node, list):
        for value in node:
            yield from walk(value)


def to_jpeg(src, dst):
    if shutil.which("sips"):
        proc = run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "60", "-Z", "900", str(src), "--out", str(dst)])
        if proc.returncode == 0 and dst.exists():
            return dst.name
    try:
        from PIL import Image

        with Image.open(src) as image:
            image.thumbnail((900, 900))
            image.convert("RGB").save(dst, "JPEG", quality=60)
        return dst.name
    except Exception:
        fallback = dst.with_suffix(src.suffix)
        shutil.copy(src, fallback)
        return fallback.name


def parse_findings(text):
    meta, findings, in_body = {}, [], False
    for line in text.splitlines():
        line = line.strip()
        if not in_body:
            if line == "---":
                in_body = True
            elif ":" in line:
                key, value = line.split(":", 1)
                meta[key.strip()] = value.strip()
            continue
        match = KIND_RE.match(line)
        if match:
            findings.append({"kind": match.group(1), "text": match.group(2)})
        elif line:
            findings.append({"kind": "other", "text": line})
    return meta, findings


def collect(args):
    out = Path(args.out)
    shutil.rmtree(out, ignore_errors=True)
    raw, img = out / "raw", out / "img"
    raw.mkdir(parents=True)
    img.mkdir()

    record = {"slug": args.slug, "device": args.device, "result": "No results", "counts": {}, "failures": [], "checkpoints": []}
    xcresult = Path(args.xcresult)
    if not xcresult.exists():
        record["failures"].append("No result bundle was produced, so the tests never started on this device.")
        (out / "index.json").write_text(json.dumps(record, indent=1))
        print(f"{args.slug}: no result bundle")
        return

    summary = xcresult_summary(xcresult)
    if summary:
        record["result"] = summary.get("result", "Unknown")
        record["counts"] = {k: summary.get(k) for k in ("totalTestCount", "passedTests", "failedTests", "skippedTests")}
        for failure in summary.get("testFailures") or []:
            text = f"{failure.get('testName', '')}: {failure.get('failureText', '')}".strip(": ")
            record["failures"].append(text)

    export = run(["xcrun", "xcresulttool", "export", "attachments", "--path", str(xcresult), "--output-path", str(raw)])
    if export.returncode != 0:
        record["failures"].append(f"Could not export screenshots: {export.stderr.strip()[:300]}")

    attachments = []
    manifest = raw / "manifest.json"
    if manifest.exists():
        attachments = [n for n in walk(json.loads(manifest.read_text())) if "exportedFileName" in n]
    attachments.sort(key=lambda a: a.get("timestamp") or 0)

    checkpoints, order = {}, []
    for attachment in attachments:
        label = attachment.get("suggestedHumanReadableName") or attachment.get("name") or attachment["exportedFileName"]
        match = NAME_RE.search(label)
        src = raw / attachment["exportedFileName"]
        if not match or not src.exists():
            continue
        screen, orientation, is_findings = match.group(1), match.group(2), bool(match.group(3))
        key = (screen, orientation)
        if key not in checkpoints:
            checkpoints[key] = {"screen": screen, "orientation": orientation, "image": None, "meta": {}, "findings": []}
            order.append(key)
        if is_findings:
            meta, findings = parse_findings(src.read_text(errors="replace"))
            checkpoints[key].update(meta=meta, findings=findings)
        else:
            checkpoints[key]["image"] = to_jpeg(src, img / f"{screen}__{orientation}.jpg")

    record["checkpoints"] = [checkpoints[k] for k in order]
    (out / "index.json").write_text(json.dumps(record, indent=1))
    shutil.rmtree(raw, ignore_errors=True)
    print(f"{args.slug}: {len(order)} screenshots, result: {record['result']}")


# ----------------------------------------------------------------- render

def screen_sort_key(screen):
    # Flow screens ("01-Home") first in flow order, then question formats ("Q-...").
    return (0 if screen[:1].isdigit() else 1, screen.lower())


def pretty_screen(screen):
    if screen.startswith("Q-"):
        words = re.sub(r"(?<!^)(?=[A-Z])", " ", screen[2:]).lower()
        return f"Question format: {words}"
    return re.sub(r"(?<!^)(?=[A-Z])", " ", screen.split("-", 1)[-1])


def load_devices(root):
    devices = []
    for index in sorted(Path(root).glob("*/index.json")):
        record = json.loads(index.read_text())
        record["_dir"] = index.parent
        devices.append(record)
    devices.sort(key=lambda d: (DEVICE_ORDER.index(d["slug"]) if d["slug"] in DEVICE_ORDER else 99, d["slug"]))
    return devices


def kind_counts(device):
    return Counter(f["kind"] for cp in device["checkpoints"] for f in cp["findings"])


def by_screen(device):
    table = {}
    for cp in device["checkpoints"]:
        table.setdefault(cp["screen"], {})[cp["orientation"]] = cp
    return table


def run_context():
    sha = os.environ.get("GITHUB_SHA", "")[:7]
    ref = os.environ.get("GITHUB_REF_NAME", "")
    server, repo, run_id = (os.environ.get(k, "") for k in ("GITHUB_SERVER_URL", "GITHUB_REPOSITORY", "GITHUB_RUN_ID"))
    run_url = f"{server}/{repo}/actions/runs/{run_id}" if server and repo and run_id else ""
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    return sha, ref, run_url, stamp


def render_markdown(devices, screens):
    sha, ref, run_url, stamp = run_context()
    lines = ["## Sprout Math UX matrix", ""]
    if sha:
        lines += [f"Commit `{sha}` on `{ref}` · {stamp}", ""]
    header = ["Device", "Result", "Tests"] + [KINDS[k][0] for k in SUMMARY_KINDS]
    lines += ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    for device in devices:
        counts = kind_counts(device)
        c = device.get("counts") or {}
        tests = f"{c.get('passedTests', '?')}/{c.get('totalTestCount', '?')} passed" if c else "—"
        row = [device["device"], device["result"], tests] + [str(counts.get(k, 0)) for k in SUMMARY_KINDS]
        lines.append("| " + " | ".join(row) + " |")

    failures = [(d["device"], f) for d in devices for f in d["failures"]]
    if failures:
        lines += ["", "### Hard failures"]
        lines += [f"- **{device}**: {text[:400]}" for device, text in failures[:40]]

    hotspots = []
    for screen in screens:
        for device in devices:
            for orientation, cp in sorted(by_screen(device).get(screen, {}).items()):
                counts = Counter(f["kind"] for f in cp["findings"] if f["kind"] in ("unreachable", "overlap", "clipped"))
                if counts:
                    detail = ", ".join(f"{KINDS[k][0].lower()} ×{n}" for k, n in counts.items())
                    hotspots.append(f"- {pretty_screen(screen)} — {device['device']}, {orientation}: {detail}")
    if hotspots:
        lines += ["", f"### Screens to look at ({len(hotspots)})"] + hotspots[:60]
        if len(hotspots) > 60:
            lines.append(f"- …and {len(hotspots) - 60} more in the full report")

    lines += ["", "Screenshots for every screen, device and orientation are in the `ux-matrix-report` artifact"
              + (f" of [this run]({run_url})" if run_url else "") + " (open `index.html`)."]
    return "\n".join(lines) + "\n"


CSS = """
:root{--bg:#f6f7f9;--panel:#fff;--ink:#16181d;--muted:#5d6470;--line:#e2e5ea;--bad:#c8372d;--warn:#b86b00;--note:#3b63c4;--ok:#2e7d4f}
@media (prefers-color-scheme:dark){:root{--bg:#111318;--panel:#1a1d24;--ink:#eceef2;--muted:#a3a9b5;--line:#2b303a;--bad:#ff6b5e;--warn:#f0a53a;--note:#86a8ff;--ok:#5fd08f}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
header{position:sticky;top:0;z-index:5;background:var(--bg);border-bottom:1px solid var(--line);padding:14px 20px}
h1{font-size:20px;margin:0 0 2px}.meta{color:var(--muted);margin:0 0 10px;font-size:13px}
.controls{display:flex;gap:12px;flex-wrap:wrap;align-items:center}select{font:inherit;padding:4px 8px;border-radius:8px;border:1px solid var(--line);background:var(--panel);color:var(--ink)}
main,.top{padding:16px 20px;max-width:100%}
table{border-collapse:collapse;background:var(--panel);border:1px solid var(--line);border-radius:10px;overflow:hidden;font-size:13px}
th,td{padding:7px 10px;border-bottom:1px solid var(--line);text-align:left;white-space:nowrap}th{color:var(--muted);font-weight:600}
.tablewrap{overflow-x:auto}
.legend{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0 0;font-size:13px;color:var(--muted)}
.chip{display:inline-block;border-radius:999px;padding:1px 8px;font-size:12px;font-weight:600;border:1px solid currentColor}
.bad{color:var(--bad)}.warn{color:var(--warn)}.note{color:var(--note)}.ok{color:var(--ok)}
.failures{margin:12px 0 0;padding-left:18px;color:var(--bad);font-size:13px}
section.screen{margin:0 0 26px}section.screen h2{font-size:16px;margin:0 0 8px}
.row{display:flex;gap:12px;overflow-x:auto;padding-bottom:6px}
figure{margin:0;background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:10px;flex:0 0 auto;max-width:640px}
figcaption{font-weight:600;font-size:13px;margin-bottom:6px}figcaption small{color:var(--muted);font-weight:400}
.pair{display:flex;gap:8px;align-items:flex-start}.shot{display:flex;flex-direction:column;gap:4px}
.shot img{display:block;height:260px;width:auto;border-radius:8px;border:1px solid var(--line);background:var(--bg)}
.shot .missing{height:260px;width:120px;display:grid;place-items:center;color:var(--muted);font-size:12px;border:1px dashed var(--line);border-radius:8px}
.shot span{font-size:11px;color:var(--muted)}
ul.findings{list-style:none;margin:6px 0 0;padding:0;font-size:12px;max-width:600px}ul.findings li{margin:2px 0}
.hidden{display:none}
"""

JS = """
const pick=document.getElementById('filter');
function apply(){const v=pick.value;document.querySelectorAll('section.screen').forEach(s=>{const k=(s.dataset.kinds||'').split(' ').filter(Boolean);
s.classList.toggle('hidden',!(v==='all'||(v==='problems'&&k.some(x=>PROBLEMS.includes(x)))||k.includes(v)));});}
pick.addEventListener('change',apply);apply();
"""


def render_html(devices, screens):
    sha, ref, run_url, stamp = run_context()
    esc = html.escape
    meta = f"{len(devices)} devices · {len(screens)} screens · portrait and landscape · {stamp}"
    if sha:
        meta = f"Commit {esc(sha)} on {esc(ref)} · " + meta
    if run_url:
        meta += f' · <a href="{esc(run_url)}">workflow run</a>'

    options = ['<option value="all">All screens</option>', '<option value="problems">Screens with problems</option>']
    options += [f'<option value="{k}">Only: {esc(v[0])}</option>' for k, v in KINDS.items() if k not in ("more", "audit")]

    rows = []
    for device in devices:
        counts = kind_counts(device)
        c = device.get("counts") or {}
        tone = "ok" if device["result"] == "Passed" else "bad"
        tests = f"{c.get('passedTests', '?')}/{c.get('totalTestCount', '?')}" if c else "—"
        cells = "".join(f"<td>{counts.get(k, 0) or ''}</td>" for k in SUMMARY_KINDS)
        rows.append(f'<tr><td>{esc(device["device"])}</td><td class="{tone}">{esc(device["result"])}</td><td>{tests}</td>{cells}</tr>')
    head = "".join(f"<th>{esc(KINDS[k][0])}</th>" for k in SUMMARY_KINDS)
    legend = "".join(f'<span><span class="chip {v[1]}">{esc(v[0])}</span> {esc(v[2])}</span>' for k, v in KINDS.items() if k in SUMMARY_KINDS)
    failures = "".join(f"<li><b>{esc(d['device'])}</b>: {esc(f[:500])}</li>" for d in devices for f in d["failures"])

    sections = []
    for screen in screens:
        kinds, figures = set(), []
        for device in devices:
            entries = by_screen(device).get(screen)
            if not entries:
                continue
            shots, notes = [], []
            size_class = ""
            for orientation in ORIENTATIONS:
                cp = entries.get(orientation)
                if cp and cp.get("image"):
                    src = f"img/{device['slug']}/{cp['image']}"
                    shots.append(f'<div class="shot"><a href="{esc(src)}" target="_blank"><img loading="lazy" src="{esc(src)}" alt="{esc(device["device"])} {orientation}"></a><span>{orientation}</span></div>')
                else:
                    shots.append(f'<div class="shot"><div class="missing">no {orientation} shot</div><span>{orientation}</span></div>')
                if cp:
                    size_class = size_class or cp["meta"].get("size-class", "")
                    for finding in cp["findings"]:
                        kinds.add(finding["kind"])
                        label, tone, _ = KINDS.get(finding["kind"], (finding["kind"], "note", ""))
                        notes.append(f'<li><span class="chip {tone}">{esc(label)}</span> <small>{orientation}</small> {esc(finding["text"])}</li>')
            caption = f'{esc(device["device"])} <small>{esc(size_class)}</small>'
            findings = f'<ul class="findings">{"".join(notes)}</ul>' if notes else '<ul class="findings"><li class="ok">No findings</li></ul>'
            figures.append(f'<figure><figcaption>{caption}</figcaption><div class="pair">{"".join(shots)}</div>{findings}</figure>')
        sections.append(f'<section class="screen" data-kinds="{" ".join(sorted(kinds))}"><h2>{esc(pretty_screen(screen))} <small class="meta">{esc(screen)}</small></h2><div class="row">{"".join(figures)}</div></section>')

    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Sprout Math UX matrix</title><style>{CSS}</style></head>
<body>
<header><h1>Sprout Math UX matrix</h1><p class="meta">{meta}</p>
<div class="controls"><label>Show <select id="filter">{"".join(options)}</select></label></div></header>
<div class="top"><div class="tablewrap"><table><tr><th>Device</th><th>Result</th><th>Tests passed</th>{head}</tr>{"".join(rows)}</table></div>
<div class="legend">{legend}</div>
{f'<ul class="failures">{failures}</ul>' if failures else ''}</div>
<main>{"".join(sections)}</main>
<script>const PROBLEMS={json.dumps(PROBLEM_KINDS)};{JS}</script>
</body></html>
"""


def render(args):
    devices = load_devices(args.devices)
    out = Path(args.out)
    shutil.rmtree(out, ignore_errors=True)
    (out / "img").mkdir(parents=True)
    for device in devices:
        source = device["_dir"] / "img"
        if source.exists():
            shutil.copytree(source, out / "img" / device["slug"])
    screens = sorted({cp["screen"] for d in devices for cp in d["checkpoints"]}, key=screen_sort_key)
    for device in devices:
        device.pop("_dir")

    (out / "index.html").write_text(render_html(devices, screens))
    (out / "report.json").write_text(json.dumps(devices, indent=1))
    markdown = render_markdown(devices, screens)
    (out / "SUMMARY.md").write_text(markdown)
    if args.summary:
        with open(args.summary, "a") as handle:
            handle.write(markdown)
    print(f"Wrote {out / 'index.html'} ({len(devices)} devices, {len(screens)} screens)")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    c = commands.add_parser("collect", help="export one device's results (macOS)")
    c.add_argument("--xcresult", required=True)
    c.add_argument("--slug", required=True)
    c.add_argument("--device", required=True)
    c.add_argument("--out", required=True)
    r = commands.add_parser("render", help="merge collected devices into a report")
    r.add_argument("--devices", required=True, help="directory containing <slug>/index.json folders")
    r.add_argument("--out", required=True)
    r.add_argument("--summary", help="also append the Markdown summary to this file")
    args = parser.parse_args()
    collect(args) if args.command == "collect" else render(args)


if __name__ == "__main__":
    main()
