#!/usr/bin/env python3
"""Print the UDID of the newest available iPad simulator (falls back to the newest iPhone)."""
import json
import subprocess
import sys

raw = subprocess.run(["xcrun", "simctl", "list", "devices", "available", "-j"],
                     capture_output=True, text=True, check=True).stdout
best = {"iPad": None, "iPhone": None}
for runtime, devices in json.loads(raw)["devices"].items():
    if "iOS" not in runtime:
        continue
    version = tuple(int(p) for p in runtime.split("iOS-")[-1].split("-") if p.isdigit())
    for dev in devices:
        if not dev.get("isAvailable"):
            continue
        for family in best:
            if dev["name"].startswith(family):
                key = (version, dev["name"])
                if best[family] is None or key > best[family][0]:
                    best[family] = (key, dev["udid"])
pick = best["iPad"] or best["iPhone"]
if not pick:
    sys.exit("no available iOS simulator")
print(pick[1])
