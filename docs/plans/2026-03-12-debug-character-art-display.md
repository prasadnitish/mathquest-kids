# Debug Character Art Display — Investigation & Fix Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Diagnose and fix why character art images show as SF Symbol fallbacks instead of the actual PNG character artwork in the running app.

**Architecture:** The 12 character PNGs are committed to the worktree branch and compile into Assets.car correctly. The issue is a combination of (1) Xcode running from the main repo's scheme which may use stale DerivedData, (2) the worktree branch not yet merged to main, and (3) a potential `Image()` initializer pitfall where SwiftUI silently returns an empty image for missing assets rather than crashing.

**Tech Stack:** SwiftUI, Xcode Asset Catalogs (.xcassets), PBXFileSystemSynchronizedRootGroup (modern Xcode auto-discovery)

---

## Root Cause Analysis

Investigation confirmed the following:

| Check | Result |
|-------|--------|
| Source PNGs exist on disk | Yes — 12 files, 1.4–2.5 MB each, 1536x1536 RGBA |
| Imagesets in xcassets | Yes — 12 `.imageset` dirs with valid `Contents.json` |
| `imageName` values match imageset names | Yes — exact match (e.g., `"CandyBenny"` → `CandyBenny.imageset`) |
| Code uses `Image(companion.imageName)` | Yes — with `!companion.imageName.isEmpty` guard |
| Images committed to git (worktree branch) | Yes — commit `e3d6f00` |
| Images compiled into Assets.car | Yes — all 12 present in simulator build |
| Images committed to `main` branch | **NO** — untracked on main |
| `Contents.json` has image at correct scale | **Concern** — image only at `1x`, `2x`/`3x` slots empty |

### Most likely causes the user sees SF symbols:

1. **Xcode is running from the main repo**, not the worktree. Since the main branch doesn't have the imagesets committed (they're untracked working directory files that may or may not be present depending on DerivedData state), Xcode may use a stale asset catalog.

2. **The `Contents.json` only assigns the PNG to the `1x` scale slot.** On Retina devices (all modern iPhones/iPads are 2x or 3x), Xcode may not upscale a 1x-only image reliably — especially with `Image()` (not `Image(uiImage:)`). The 1536x1536 PNG should be in the **universal unscaled** slot or the `2x`/`3x` slots to display correctly on device.

3. **DerivedData caching** — if Xcode previously built without the images, the cached Assets.car won't include them until a clean build.

---

### Task 1: Fix Contents.json to use universal unscaled slot

The current `Contents.json` puts the image at `"scale": "1x"` with empty `2x`/`3x` slots. For a single high-res source image, the correct approach is to use a **single universal entry without a scale** — this tells Xcode "use this image at any scale."

**Files:**
- Modify: `MathQuestKids/Assets.xcassets/CandyBenny.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/CandySprinkle.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/CandyTaffy.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/ReefCoral.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/ReefFinn.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/ReefPearl.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/UnicornSparkle.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/UnicornClover.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/UnicornDizzy.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/SpaceCosmo.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/SpaceLuna.imageset/Contents.json`
- Modify: `MathQuestKids/Assets.xcassets/SpaceZip.imageset/Contents.json`

**Step 1: Replace all 12 Contents.json files**

Each file should change FROM the current format:
```json
{
  "images" : [
    { "filename" : "NAME.png", "idiom" : "universal", "scale" : "1x" },
    { "idiom" : "universal", "scale" : "2x" },
    { "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

TO the single-universal format:
```json
{
  "images" : [
    {
      "filename" : "NAME.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Write a shell loop that replaces all 12 files. The names are:
`CandyBenny CandySprinkle CandyTaffy ReefCoral ReefFinn ReefPearl UnicornSparkle UnicornClover UnicornDizzy SpaceCosmo SpaceLuna SpaceZip`

**Step 2: Verify Contents.json files are correct**

Run:
```bash
for name in CandyBenny CandySprinkle CandyTaffy ReefCoral ReefFinn ReefPearl UnicornSparkle UnicornClover UnicornDizzy SpaceCosmo SpaceLuna SpaceZip; do
  echo "=== $name ==="
  cat "MathQuestKids/Assets.xcassets/${name}.imageset/Contents.json"
  echo
done
```

Expected: Each file has a single `"idiom": "universal"` entry with `"filename"` and NO `"scale"` key.

---

### Task 2: Clean build and verify assets compile

**Step 1: Clean DerivedData for the project**

Run:
```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild clean -project MathQuestKids.xcodeproj -target MathQuestKids -sdk iphonesimulator -arch arm64 -configuration Debug -quiet
```

**Step 2: Build**

Run:
```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild build -project MathQuestKids.xcodeproj -target MathQuestKids -sdk iphonesimulator -arch arm64 -configuration Debug -quiet
```

Expected: BUILD SUCCEEDED with no output (quiet mode)

**Step 3: Verify all 12 characters are in the compiled Assets.car**

Run:
```bash
CAR_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Assets.car" -path "*MathQuestKids*" -path "*iphonesimulator*" -path "*assetcatalog_output*" | head -1)
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun --sdk iphonesimulator assetutil --info "$CAR_PATH" 2>&1 | python3 -c "
import sys,json
data=json.load(sys.stdin)
chars = ['CandyBenny','CandySprinkle','CandyTaffy','ReefCoral','ReefFinn','ReefPearl',
         'UnicornSparkle','UnicornClover','UnicornDizzy','SpaceCosmo','SpaceLuna','SpaceZip']
found = [e.get('Name','') for e in data if e.get('Name','') in chars]
missing = set(chars) - set(found)
print(f'Found: {len(found)}/12')
if missing: print(f'MISSING: {missing}')
else: print('All character assets compiled successfully')
for e in data:
    if e.get('Name','') in chars:
        print(f\"  {e['Name']}: scale={e.get('Scale','?')} rendition={e.get('RenditionName','?')}\")
"
```

Expected: `Found: 12/12` and `All character assets compiled successfully`

---

### Task 3: Commit and push

**Step 1: Stage and commit**

```bash
git add MathQuestKids/Assets.xcassets/*/Contents.json
git commit -m "fix: use universal unscaled slot for character art imagesets

1536x1536 PNGs were assigned to 1x scale slot with empty 2x/3x,
which could cause Retina devices to show empty/fallback images.
Changed to single universal entry (no scale) so Xcode uses the
image at all resolutions."
```

**Step 2: Push to Gitea**

```bash
git -c http.extraHeader="Authorization: token bac39b671c91556e93a87b7fc507091cdc9f55c9" push gitea claude/upbeat-varahamihira
```

Expected: Push succeeds.

---

### Task 4: Verify in Xcode and document next steps for user

**Step 1: Provide user instructions to test on device**

Tell the user:
1. Open `MathQuestKids.xcodeproj` in Xcode
2. Switch to branch `claude/upbeat-varahamihira` (or merge it to main)
3. Product → Clean Build Folder (Cmd+Shift+K)
4. Build and run on simulator or device
5. Check Home screen companion spotlight and character pack scroll — should show character art, not SF symbols

**Step 2: If characters still show as SF symbols on device**

The remaining diagnostic is to add a runtime check. Add a temporary debug print in `HomeView.swift` to verify:

```swift
// Temporary debug — remove after verification
let _ = print("companion.imageName: '\(companion.imageName)', UIImage exists: \(UIImage(named: companion.imageName) != nil)")
```

This will print to the Xcode console whether `UIImage(named:)` can find each asset at runtime. If it prints `false`, the asset catalog isn't being bundled. If `true` but still showing SF symbol, there's a SwiftUI `Image()` rendering issue.
