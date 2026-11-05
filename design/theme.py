#!/usr/bin/env python3
"""Writes the shared colour tokens (light + dark) into Shared/Theme.xcassets.

    python3 design/theme.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "Shared", "Theme.xcassets")

# name: (light, dark)
COLORS = {
    # Surfaces
    "Background": ("#FBF8F4", "#111113"),
    "Surface": ("#FFFFFF", "#1C1C1F"),
    "SurfaceMuted": ("#F3EFE9", "#252529"),
    "Hairline": ("#ECE6DE", "#2E2E33"),
    # Text
    "Ink": ("#1E1F24", "#F5F3EF"),
    "InkSecondary": ("#6B6A71", "#A4A3AA"),
    "InkTertiary": ("#A3A1A8", "#6F6E75"),
    "InkInverse": ("#FFFFFF", "#111113"),
    # Status
    "Success": ("#3E9B5F", "#6BCB8B"),
    "Warning": ("#E59A2F", "#F5B85C"),
    "Danger": ("#D9534F", "#F07A76"),
    "Flame": ("#F2762E", "#FF9550"),
    # Mascots: tint = circle behind the mascot, accent = strong UI colour, wash = page wash
    "OrbitTint": ("#C8D8EC", "#2C3B54"),
    "OrbitAccent": ("#3F74C9", "#7EA7F2"),
    "OrbitWash": ("#EEF3FA", "#161C27"),
    "SparkTint": ("#FBE0BF", "#4A3522"),
    "SparkAccent": ("#EC8327", "#FFAA5E"),
    "SparkWash": ("#FDF3E7", "#211912"),
    "LeafTint": ("#DCE7D0", "#2F3E2B"),
    "LeafAccent": ("#5A8F4C", "#8FC67F"),
    "LeafWash": ("#F2F6EE", "#161D15"),
    "PebbleTint": ("#D7DDE7", "#323946"),
    "PebbleAccent": ("#566377", "#A6B2C7"),
    "PebbleWash": ("#F1F3F7", "#181B21"),
    "BlobTint": ("#E2DCF3", "#3A3453"),
    "BlobAccent": ("#7562CC", "#B4A6F4"),
    "BlobWash": ("#F4F1FB", "#1C1826"),
}


def comp(hexstr):
    h = hexstr.lstrip("#")
    r, g, b = (int(h[i : i + 2], 16) for i in (0, 2, 4))
    return {"alpha": "1.000", "blue": f"0x{b:02X}", "green": f"0x{g:02X}", "red": f"0x{r:02X}"}


def colorset(light, dark):
    return {
        "colors": [
            {"color": {"color-space": "srgb", "components": comp(light)}, "idiom": "universal"},
            {
                "appearances": [{"appearance": "luminosity", "value": "dark"}],
                "color": {"color-space": "srgb", "components": comp(dark)},
                "idiom": "universal",
            },
        ],
        "info": {"author": "xcode", "version": 1},
    }


def main():
    os.makedirs(CATALOG, exist_ok=True)
    with open(os.path.join(CATALOG, "Contents.json"), "w") as fh:
        json.dump({"info": {"author": "xcode", "version": 1}}, fh, indent=2)
        fh.write("\n")
    for name, (light, dark) in COLORS.items():
        d = os.path.join(CATALOG, f"{name}.colorset")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "Contents.json"), "w") as fh:
            json.dump(colorset(light, dark), fh, indent=2)
            fh.write("\n")
    print(f"wrote {len(COLORS)} colours to {CATALOG}")

    # App-only assets: accent colour, launch background + launch logo
    app = os.path.join(ROOT, "App", "Assets.xcassets")
    os.makedirs(app, exist_ok=True)
    with open(os.path.join(app, "Contents.json"), "w") as fh:
        json.dump({"info": {"author": "xcode", "version": 1}}, fh, indent=2)
        fh.write("\n")
    for name, (light, dark) in {"AccentColor": ("#1E1F24", "#F5F3EF"), "LaunchBackground": ("#FBF8F4", "#111113")}.items():
        d = os.path.join(app, f"{name}.colorset")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "Contents.json"), "w") as fh:
            json.dump(colorset(light, dark), fh, indent=2)
            fh.write("\n")
    mac = os.path.join(ROOT, "Mac", "Assets.xcassets")
    os.makedirs(mac, exist_ok=True)
    with open(os.path.join(mac, "Contents.json"), "w") as fh:
        json.dump({"info": {"author": "xcode", "version": 1}}, fh, indent=2)
        fh.write("\n")
    d = os.path.join(mac, "AccentColor.colorset")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "Contents.json"), "w") as fh:
        json.dump(colorset("#1E1F24", "#F5F3EF"), fh, indent=2)
        fh.write("\n")


if __name__ == "__main__":
    main()
