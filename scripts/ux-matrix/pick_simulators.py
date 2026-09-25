#!/usr/bin/env python3
"""Pick one simulator per device class on the newest installed iOS runtime.

Creates dedicated "UX <model>" simulators so the matrix can erase them freely
without touching simulators you use day to day.

Usage: pick_simulators.py [all | <class> ...]
Prints one tab-separated line per device: <class> <udid> <model name>
"""

import json
import subprocess
import sys

# Smallest to largest. The first model the runtime supports wins, so the list
# keeps working as Xcode adds and drops device types.
DEVICE_CLASSES = {
    "iphone-small": ["iPhone SE (3rd generation)", "iPhone 17e", "iPhone 16e"],
    "iphone-standard": ["iPhone 17", "iPhone 17 Pro", "iPhone 16"],
    "iphone-large": ["iPhone 17 Pro Max", "iPhone Air", "iPhone 16 Pro Max"],
    "ipad-mini": ["iPad mini (A17 Pro)", "iPad mini (6th generation)"],
    "ipad-standard": ["iPad (A16)", "iPad Air 11-inch (M4)", "iPad Air 11-inch (M3)", "iPad (10th generation)"],
    "ipad-large": ["iPad Pro 13-inch (M5)", "iPad Pro 13-inch (M4)", "iPad Air 13-inch (M4)"],
}

SIM_PREFIX = "UX "


def simctl(*args):
    return subprocess.run(["xcrun", "simctl", *args], check=True, capture_output=True, text=True).stdout


def version_key(runtime):
    return tuple(int(part) for part in runtime["version"].split(".") if part.isdigit())


def main(argv):
    wanted = argv or ["all"]
    classes = list(DEVICE_CLASSES) if "all" in wanted else wanted
    unknown = [c for c in classes if c not in DEVICE_CLASSES]
    if unknown:
        sys.exit(f"Unknown device class(es): {', '.join(unknown)}. Known: {', '.join(DEVICE_CLASSES)}")

    runtimes = [
        r for r in json.loads(simctl("list", "runtimes", "-j"))["runtimes"]
        if r.get("isAvailable") and (r.get("platform") == "iOS" or r.get("name", "").startswith("iOS"))
    ]
    if not runtimes:
        sys.exit("No available iOS simulator runtime. Install one from Xcode > Settings > Components.")
    runtime = max(runtimes, key=version_key)
    supported = {t["name"]: t["identifier"] for t in runtime.get("supportedDeviceTypes", [])}
    existing = json.loads(simctl("list", "devices", "-j"))["devices"].get(runtime["identifier"], [])

    for cls in classes:
        model = next((name for name in DEVICE_CLASSES[cls] if name in supported), None)
        if model is None:
            print(f"warning: {runtime['name']} supports none of {DEVICE_CLASSES[cls]}; skipping {cls}", file=sys.stderr)
            continue
        sim_name = SIM_PREFIX + model
        match = next((d for d in existing if d["name"] == sim_name and d.get("isAvailable", True)), None)
        udid = match["udid"] if match else simctl("create", sim_name, supported[model], runtime["identifier"]).strip()
        print(f"{cls}: {model} on {runtime['name']} ({udid})", file=sys.stderr)
        print(f"{cls}\t{udid}\t{model}")


if __name__ == "__main__":
    main(sys.argv[1:])
