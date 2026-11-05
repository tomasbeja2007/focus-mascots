#!/usr/bin/env python3
"""
Vector source for the five Focus Crew mascots.

Every mascot is drawn on a 512x512 canvas. The tinted background circle that
appears behind each mascot in the app is centred at (256, 236) with r=200 and
is drawn by the app itself (so it can be tinted / animated), not baked in here.

    python3 design/mascots/generate.py        # writes SVGs to design/mascots/svg
    node design/mascots/render.mjs            # renders PNGs into the asset catalog

Expressions: idle, blink, happy, focused, sleepy, sad, excited
"""
import math
import os

INK = "#1F2129"
SW = 13  # main outline width

EXPRESSIONS = ["idle", "blink", "happy", "focused", "sleepy", "sad", "excited"]
MASCOTS = ["orbit", "spark", "leaf", "pebble", "blob"]

CIRCLE = (256, 236, 200)
TINTS = {
    "orbit": "#C8D8EC",
    "spark": "#FBE0BF",
    "leaf": "#DCE7D0",
    "pebble": "#D7DDE7",
    "blob": "#E2DCF3",
}


# ---------------------------------------------------------------- helpers
def f(v):
    return f"{v:.1f}".rstrip("0").rstrip(".")


def squircle(cx, cy, rx, ry, k=0.72):
    """Closed superellipse-ish path through the 4 extremes."""
    kx, ky = rx * k, ry * k
    return (
        f"M {f(cx)} {f(cy-ry)} "
        f"C {f(cx+kx)} {f(cy-ry)} {f(cx+rx)} {f(cy-ky)} {f(cx+rx)} {f(cy)} "
        f"C {f(cx+rx)} {f(cy+ky)} {f(cx+kx)} {f(cy+ry)} {f(cx)} {f(cy+ry)} "
        f"C {f(cx-kx)} {f(cy+ry)} {f(cx-rx)} {f(cy+ky)} {f(cx-rx)} {f(cy)} "
        f"C {f(cx-rx)} {f(cy-ky)} {f(cx-kx)} {f(cy-ry)} {f(cx)} {f(cy-ry)} Z"
    )


def path(d, fill="none", stroke=INK, sw=SW, extra=""):
    s = f'<path d="{d}" fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{f(sw)}" stroke-linecap="round" stroke-linejoin="round"'
    return s + f" {extra}/>"


def ellipse(cx, cy, rx, ry, fill, stroke=INK, sw=SW, extra=""):
    s = f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(rx)}" ry="{f(ry)}" fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{f(sw)}"'
    return s + f" {extra}/>"


def limb(d, fill, width, outline=INK, sw=SW):
    """Outlined capsule-like limb along a path (stroke trick)."""
    return (
        f'<path d="{d}" fill="none" stroke="{outline}" stroke-width="{f(width + 2*sw)}" stroke-linecap="round" stroke-linejoin="round"/>'
        f'<path d="{d}" fill="none" stroke="{fill}" stroke-width="{f(width)}" stroke-linecap="round" stroke-linejoin="round"/>'
    )


# ---------------------------------------------------------------- faces
def face(expr, le, re, mouth, e=16, color=INK, sw=8.5, glint=True, blush=None, open_eye_fill=None, mouth_w=13, mouthless=False):
    """Generic kawaii face.

    le/re: eye centres, e: eye half-width, mouth: mouth centre.
    """
    out = []
    lx, ly = le
    rx_, ry_ = re
    mx, my = mouth
    eye_fill = open_eye_fill or color

    def arc_up(x, y):  # ^  happy closed eye
        return path(f"M {f(x-e)} {f(y+e*0.35)} Q {f(x)} {f(y-e*0.95)} {f(x+e)} {f(y+e*0.35)}", stroke=color, sw=sw)

    def arc_down(x, y):  # u  sleeping eye
        return path(f"M {f(x-e)} {f(y-e*0.2)} Q {f(x)} {f(y+e*0.8)} {f(x+e)} {f(y-e*0.2)}", stroke=color, sw=sw)

    def line_eye(x, y):  # -  blink
        return path(f"M {f(x-e*0.85)} {f(y+e*0.1)} Q {f(x)} {f(y+e*0.32)} {f(x+e*0.85)} {f(y+e*0.1)}", stroke=color, sw=sw)

    def open_eye(x, y, squash=1.0):
        s = ellipse(x, y + e * 0.05, e * 0.52, e * 0.68 * squash, eye_fill, stroke=None)
        if glint:
            gl = "#FFFFFF" if eye_fill != "#FFFFFF" else INK
            s += ellipse(x + e * 0.18, y - e * 0.22 * squash, e * 0.17, e * 0.19, gl, stroke=None)
        return s

    def smile(w=mouth_w, depth=0.55):
        return path(f"M {f(mx-w)} {f(my-w*0.15)} Q {f(mx)} {f(my+w*depth*1.6)} {f(mx+w)} {f(my-w*0.15)}", stroke=color, sw=sw)

    if expr == "happy":
        out += [arc_up(lx, ly), arc_up(rx_, ry_)] + ([] if mouthless else [smile()])
    elif expr == "idle":
        out += [open_eye(lx, ly), open_eye(rx_, ry_)] + ([] if mouthless else [smile(w=mouth_w * 0.85)])
    elif expr == "blink":
        out += [line_eye(lx, ly), line_eye(rx_, ry_)] + ([] if mouthless else [smile(w=mouth_w * 0.85)])
    elif expr == "focused":
        out += [open_eye(lx, ly + e * 0.15, squash=0.85), open_eye(rx_, ry_ + e * 0.15, squash=0.85)]
        # determined brows: inner ends lower
        out.append(path(f"M {f(lx-e*1.05)} {f(ly-e*1.05)} L {f(lx+e*0.9)} {f(ly-e*0.55)}", stroke=color, sw=sw))
        out.append(path(f"M {f(rx_+e*1.05)} {f(ry_-e*1.05)} L {f(rx_-e*0.9)} {f(ry_-e*0.55)}", stroke=color, sw=sw))
        out.append(path(f"M {f(mx-mouth_w*0.7)} {f(my+2)} L {f(mx+mouth_w*0.7)} {f(my+2)}", stroke=color, sw=sw))
    elif expr == "sleepy":
        out += [arc_down(lx, ly), arc_down(rx_, ry_)]
        if not mouthless:
            out.append(path(f"M {f(mx-mouth_w*0.6)} {f(my)} Q {f(mx)} {f(my+mouth_w*0.6)} {f(mx+mouth_w*0.6)} {f(my)}", stroke=color, sw=sw))
    elif expr == "sad":
        out += [open_eye(lx, ly + e * 0.1), open_eye(rx_, ry_ + e * 0.1)]
        # worried brows: inner ends higher
        out.append(path(f"M {f(lx-e*1.0)} {f(ly-e*0.6)} Q {f(lx)} {f(ly-e*0.95)} {f(lx+e*0.95)} {f(ly-e*1.2)}", stroke=color, sw=sw * 0.9))
        out.append(path(f"M {f(rx_+e*1.0)} {f(ry_-e*0.6)} Q {f(rx_)} {f(ry_-e*0.95)} {f(rx_-e*0.95)} {f(ry_-e*1.2)}", stroke=color, sw=sw * 0.9))
        w = mouth_w * 0.8
        out.append(path(f"M {f(mx-w)} {f(my+w*0.55)} Q {f(mx)} {f(my-w*0.45)} {f(mx+w)} {f(my+w*0.55)}", stroke=color, sw=sw))
    elif expr == "excited":
        out += [arc_up(lx, ly), arc_up(rx_, ry_)]
        w = mouth_w * 1.15
        mouth_fill = "#FFFFFF" if color == "#FFFFFF" else INK
        tongue = "#F27E7E"
        d = f"M {f(mx-w)} {f(my-w*0.25)} Q {f(mx)} {f(my-w*0.05)} {f(mx+w)} {f(my-w*0.25)} Q {f(mx+w*0.9)} {f(my+w*1.25)} {f(mx)} {f(my+w*1.25)} Q {f(mx-w*0.9)} {f(my+w*1.25)} {f(mx-w)} {f(my-w*0.25)} Z"
        out.append(f'<clipPath id="mclip"><path d="{d}"/></clipPath>')
        out.append(path(d, fill=mouth_fill, stroke=color, sw=sw * 0.75))
        if color != "#FFFFFF":
            out.append(f'<g clip-path="url(#mclip)">' + ellipse(mx, my + w * 1.25, w * 0.62, w * 0.5, tongue, stroke=None) + "</g>")
    if blush and expr == "excited":
        bx, by, bdx, brx = blush
        op = "0.5"
        out.append(ellipse(bx - bdx, by, brx, brx * 0.6, "#F59A9A", stroke=None, extra=f'opacity="{op}"'))
        out.append(ellipse(bx + bdx, by, brx, brx * 0.6, "#F59A9A", stroke=None, extra=f'opacity="{op}"'))
    return "".join(out)


# ---------------------------------------------------------------- Orbit
def orbit(expr):
    body_fill = "#FFFFFF"
    shade = "#DCE6F4"
    blue = "#3F74C9"
    visor = "#232B37"
    g = []
    # torso (behind helmet)
    torso = squircle(262, 372, 64, 58, 0.82)
    g.append(f'<clipPath id="torso"><path d="{torso}"/></clipPath>')
    g.append(path(torso, fill=body_fill, stroke=None))
    g.append(f'<g clip-path="url(#torso)">{ellipse(318, 400, 36, 70, shade, stroke=None)}</g>')
    g.append(path(torso))
    # right leg / boot, bent forward
    leg = squircle(330, 414, 58, 30, 0.86)
    g.append(f'<clipPath id="leg"><path d="{leg}"/></clipPath>')
    g.append(path(leg, fill=body_fill, stroke=None))
    g.append(f'<g clip-path="url(#leg)">{ellipse(380, 414, 22, 40, shade, stroke=None)}</g>')
    g.append(path(leg))
    g.append(path("M 364 392 Q 356 414 364 436", stroke=INK, sw=7))
    # left foot + arm crease
    g.append(ellipse(212, 420, 34, 25, body_fill))
    g.append(path("M 238 356 Q 244 384 236 404", stroke=INK, sw=8))
    # right ear (peeking behind helmet)
    g.append(ellipse(408, 214, 18, 34, body_fill))
    # helmet
    helmet = squircle(270, 208, 142, 122, 0.64)
    g.append(f'<clipPath id="helm"><path d="{helmet}"/></clipPath>')
    g.append(path(helmet, fill=body_fill, stroke=None))
    g.append(f'<g clip-path="url(#helm)">{ellipse(300, 332, 170, 46, shade, stroke=None)}</g>')
    g.append(path(helmet))
    # visor
    g.append(path(squircle(284, 212, 112, 88, 0.62), fill=visor, sw=SW * 0.9))
    g.append(path("M 210 166 Q 220 142 246 134", stroke="#FFFFFF", sw=7, extra='opacity="0.16"'))
    # left headphone / ear
    g.append(ellipse(130, 246, 38, 50, blue))
    g.append(ellipse(144, 246, 25, 38, "#FFFFFF", sw=9))
    g.append(face(expr, (244, 226), (324, 226), (284, 258), e=20, color="#FFFFFF", sw=9, open_eye_fill="#FFFFFF", mouth_w=11, mouthless=True))
    return "".join(g)


def orbit_deco():
    # 4-point sparkle
    cx, cy, r = 410, 108, 34
    d = (
        f"M {cx} {cy-r} Q {cx+5} {cy-5} {cx+r*0.85} {cy} Q {cx+5} {cy+5} {cx} {cy+r} "
        f"Q {cx-5} {cy+5} {cx-r*0.85} {cy} Q {cx-5} {cy-5} {cx} {cy-r} Z"
    )
    return path(d, fill="#F8C64A", sw=9)


# ---------------------------------------------------------------- Spark
def spark(expr):
    outline = "#8C3A17"
    outer = "#F59A3C"
    inner = "#FFC768"
    limbc = "#FDBB55"
    g = []
    # back arm, back leg, torso, front leg (behind the flame head)
    g.append(path("M 222 330 C 200 336 178 342 160 354 C 146 364 152 382 168 380 C 186 376 206 364 228 354 Z", fill=limbc))
    g.append(path("M 250 360 C 214 362 184 370 160 378 C 128 388 116 410 126 428 C 136 446 166 444 188 432 C 212 420 238 418 264 416 Z", fill=limbc))
    g.append(ellipse(274, 374, 60, 46, limbc))
    g.append(path("M 268 394 C 288 420 312 440 336 450 C 364 462 396 458 402 438 C 408 420 392 408 372 410 C 354 412 338 400 324 376 Z", fill=limbc))
    flame = (
        "M 286 352 "
        "C 205 354 148 318 140 264 "
        "C 135 238 129 220 124 196 "
        "C 148 204 166 214 180 230 "
        "C 180 192 188 160 205 128 "
        "C 214 154 224 172 236 186 "
        "C 230 146 234 108 252 78 "
        "C 288 110 316 148 326 186 "
        "C 336 168 346 152 360 138 "
        "C 398 176 420 222 414 268 "
        "C 408 322 362 352 286 352 Z"
    )
    g.append(path(flame, fill=outer, stroke=None))
    # inner glow
    innerd = (
        "M 292 338 C 236 338 204 306 208 268 "
        "C 212 232 240 214 258 176 "
        "C 270 206 296 206 322 202 "
        "C 362 214 396 240 396 276 "
        "C 396 312 350 338 292 338 Z"
    )
    g.append(path(innerd, fill=inner, stroke=None))
    g.append(path(flame, stroke=outline, sw=SW))
    # front arm (in front of flame)
    g.append(path("M 310 328 C 334 342 352 344 366 334 C 372 316 394 308 408 320 C 422 334 414 358 394 366 C 368 378 334 376 308 362 Z", fill=limbc))
    g.append(face(expr, (276, 238), (352, 238), (314, 270), e=16, color=INK, sw=8.5, blush=(314, 262, 58, 13), mouth_w=13))
    return "".join(g)


def spark_deco():
    c = "#F2A03E"
    return (
        path("M 393 86 L 414 46", stroke=c, sw=12)
        + path("M 420 110 L 462 82", stroke=c, sw=12)
        + path("M 434 138 L 476 130", stroke=c, sw=12)
    )


# ---------------------------------------------------------------- Leaf
def leaf(expr):
    fur = "#B98F68"
    head = "#A87E57"
    face_c = "#F4DFBA"
    mask = "#7E5F45"
    g = []
    body = (
        "M 92 438 C 50 440 40 404 56 368 "
        "C 80 290 150 222 250 218 "
        "C 300 216 340 236 360 262 "
        "L 300 438 Z"
    )
    g.append(path(body, fill=fur))
    # little claw / arm line
    g.append(path("M 152 386 C 168 398 168 418 152 430", stroke=INK, sw=10))
    # back foot bump
    g.append(path("M 70 438 C 70 418 100 414 112 438", fill=fur, sw=SW))
    # head
    g.append(ellipse(308, 342, 124, 98, head))
    g.append(f'<clipPath id="lhead"><ellipse cx="308" cy="342" rx="124" ry="98"/></clipPath>')
    face_g = ellipse(314, 364, 104, 78, face_c, stroke=None)
    # eye masks
    face_g += f'<ellipse cx="254" cy="352" rx="44" ry="24" fill="{mask}" transform="rotate(-16 254 352)"/>'
    face_g += f'<ellipse cx="370" cy="352" rx="44" ry="24" fill="{mask}" transform="rotate(16 370 352)"/>'
    g.append(f'<g clip-path="url(#lhead)">{face_g}</g>')
    g.append(ellipse(308, 342, 124, 98, "none"))
    # tiny paw at the front
    g.append(path("M 206 440 C 204 420 226 414 236 436", fill=face_c, sw=10))
    # nose
    g.append(ellipse(312, 374, 10, 7, INK, stroke=None))
    # face (no nose/mouth duplication; mouth is below nose)
    g.append(face(expr, (258, 358), (366, 358), (312, 392), e=16, color=INK, sw=8, glint=True, blush=(312, 386, 74, 12), mouth_w=11))
    return "".join(g)


def leaf_deco():
    return path("M 336 176 L 358 176 L 336 204 L 358 204", stroke=INK, sw=8) + path(
        "M 374 138 L 410 138 L 374 178 L 410 178", stroke=INK, sw=9
    )


# ---------------------------------------------------------------- Pebble
def pebble(expr):
    rock = "#AEAEB3"
    rock_light = "#C4C4C8"
    rock_dark = "#7D7D83"
    g = []
    mountain = (
        "M 124 440 L 408 440 "
        "Q 456 440 436 398 "
        "C 410 340 380 280 352 230 "
        "Q 344 214 330 210 "
        "Q 316 206 306 192 "
        "C 296 176 284 162 266 160 "
        "C 250 158 238 168 226 184 "
        "C 180 250 120 330 82 398 "
        "Q 62 440 124 440 Z"
    )
    g.append(f'<clipPath id="mtn"><path d="{mountain}"/></clipPath>')
    g.append(path(mountain, fill=rock, stroke=None))
    inner = []
    # light peak
    inner.append(path("M 180 250 L 262 160 L 340 220 L 340 260 L 180 260 Z", fill=rock_light, stroke=None))
    # dark rocks at the base
    dark = (
        "M 40 380 L 112 346 Q 124 340 134 350 L 184 398 L 212 374 Q 222 366 230 376 "
        "L 262 450 L 40 450 Z"
    )
    dark2 = "M 318 450 L 360 384 Q 368 372 378 380 L 392 392 L 420 352 Q 430 340 440 352 L 480 400 L 480 450 Z"
    inner.append(path(dark, fill=rock_dark, stroke=INK, sw=8))
    inner.append(path(dark2, fill=rock_dark, stroke=INK, sw=8))
    # headband
    inner.append(f'<rect x="40" y="224" width="440" height="48" fill="#FFFFFF" stroke="{INK}" stroke-width="10"/>')
    g.append(f'<g clip-path="url(#mtn)">{"".join(inner)}</g>')
    g.append(path(mountain, stroke=INK, sw=SW))
    # headband tails (left)
    g.append(path("M 166 238 L 104 206 Q 88 202 86 218 L 88 228 Q 90 238 104 244 L 150 262 Z", fill="#FFFFFF", sw=10))
    g.append(path("M 156 260 L 96 290 Q 84 298 92 310 L 98 316 Q 106 322 118 314 L 166 280 Z", fill="#FFFFFF", sw=10))
    g.append(path("M 106 222 Q 118 230 132 232", stroke="#E3E5EA", sw=5))
    # face
    g.append(face(expr, (250, 320), (318, 320), (284, 354), e=16, color=INK, sw=9.5, mouth_w=13))
    return "".join(g)


def pebble_deco():
    return (
        path("M 340 136 L 348 164", stroke="#2F3440", sw=10)
        + path("M 368 180 L 392 156", stroke="#2F3440", sw=10)
        + path("M 382 208 L 408 200", stroke="#868C9A", sw=10)
    )


# ---------------------------------------------------------------- Blob
def blob(expr):
    fill = "#E3DDF4"
    shade = "#D2CAEC"
    g = []
    d = (
        "M 74 420 "
        "C 42 400 46 342 94 318 "
        "C 106 232 150 164 240 162 "
        "C 322 160 356 224 362 290 "
        "C 386 280 420 292 426 320 "
        "C 452 332 464 372 442 402 "
        "C 450 430 422 446 396 438 "
        "C 376 454 342 454 320 440 "
        "C 300 454 264 454 244 440 "
        "C 224 454 188 454 168 440 "
        "C 148 454 112 452 100 438 "
        "C 86 440 76 432 74 420 Z"
    )
    g.append(f'<clipPath id="blobc"><path d="{d}"/></clipPath>')
    g.append(path(d, fill=fill, stroke=None))
    g.append(f'<g clip-path="url(#blobc)">{ellipse(300, 470, 220, 60, shade, stroke=None)}</g>')
    g.append(path("M 128 262 Q 136 220 168 196", stroke="#FFFFFF", sw=9, extra='opacity="0.6"'))
    g.append(path(d, stroke=INK, sw=SW))
    g.append(face(expr, (212, 252), (278, 252), (245, 280), e=15, color=INK, sw=8.5, blush=(245, 274, 56, 12), mouth_w=13))
    return "".join(g)


def blob_deco():
    c = "#3A4054"
    return (
        f'<rect x="350" y="218" width="20" height="28" rx="5" fill="{c}"/>'
        f'<rect x="382" y="196" width="20" height="50" rx="5" fill="{c}"/>'
        f'<rect x="414" y="170" width="21" height="76" rx="5" fill="{c}"/>'
    )


DRAW = {"orbit": orbit, "spark": spark, "leaf": leaf, "pebble": pebble, "blob": blob}
DECO = {"orbit": orbit_deco, "spark": spark_deco, "leaf": leaf_deco, "pebble": pebble_deco, "blob": blob_deco}

# Square crop (x, y, size) around the head, for tiny avatars (Dynamic Island, menu bar, notch)
AVATAR_CROP = {
    "orbit": (96, 40, 350),
    "spark": (110, 56, 316),
    "leaf": (178, 236, 252),
    "pebble": (110, 150, 320),
    "blob": (100, 112, 290),
}


def svg(content, view="0 0 512 512", size=512, bg=None):
    bgs = f'<rect x="-1000" y="-1000" width="3000" height="3000" fill="{bg}"/>' if bg else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}" width="{size}" height="{size}">{bgs}{content}</svg>'


def circle_bg(m):
    cx, cy, r = CIRCLE
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{TINTS[m]}"/>'


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, "svg")
    os.makedirs(out, exist_ok=True)
    for m in MASCOTS:
        for e in EXPRESSIONS:
            with open(os.path.join(out, f"{m}_{e}.svg"), "w") as fh:
                fh.write(svg(DRAW[m](e)))
        with open(os.path.join(out, f"{m}_deco.svg"), "w") as fh:
            fh.write(svg(DECO[m]()))
        # Dark-appearance decoration: light strokes so they read on dark circles.
        dark = DECO[m]()
        for a, b in (("#1F2129", "#ECEAF4"), ("#2F3440", "#DADDE7"), ("#3A4054", "#D8D3F0"), ("#868C9A", "#9EA5B4")):
            if m != "orbit":
                dark = dark.replace(a, b)
        with open(os.path.join(out, f"{m}_deco_dark.svg"), "w") as fh:
            fh.write(svg(dark))
        # avatars: head crop on the tint circle, one per expression (plain name = happy)
        x, y, s = AVATAR_CROP[m]
        cx, cy = x + s / 2, y + s / 2
        for e in EXPRESSIONS:
            content = (
                f'<circle cx="{cx}" cy="{cy}" r="{s/2}" fill="{TINTS[m]}"/>'
                f'<clipPath id="av"><circle cx="{cx}" cy="{cy}" r="{s/2}"/></clipPath>'
                f'<g clip-path="url(#av)">{DRAW[m](e)}</g>'
            )
            name = f"{m}_avatar" if e == "happy" else f"{m}_avatar_{e}"
            with open(os.path.join(out, f"{name}.svg"), "w") as fh:
                fh.write(svg(content, view=f"{x} {y} {s} {s}"))
        # full preview with circle (for comparison sheets)
        with open(os.path.join(out, f"{m}_preview.svg"), "w") as fh:
            fh.write(svg(circle_bg(m) + DECO[m]() + DRAW[m]("happy" if m not in ("leaf", "pebble") else {"leaf": "sleepy", "pebble": "focused"}[m])))
    print("wrote", len(os.listdir(out)), "svgs to", out)


if __name__ == "__main__":
    main()


# ---------------------------------------------------------------- app icons
def icon_svg(dark=False, mac=False):
    """1024x1024 app icon: Orbit's happy helmet on a soft blue field."""
    top, bottom = ("#DCE8F6", "#AFC7E8") if not dark else ("#26324A", "#121826")
    s = 2.12
    tx, ty = 512 - s * 262, 500 - s * 220
    art = f'<g transform="translate({f(tx)} {f(ty)}) scale({s})">{orbit("happy")}</g>'
    sparkle = f'<g transform="translate({f(tx)} {f(ty)}) scale({s})">{orbit_deco()}</g>'
    glow = '<circle cx="512" cy="470" r="380" fill="#FFFFFF" opacity="0.28"/>' if not dark else '<circle cx="512" cy="470" r="380" fill="#4A6AA8" opacity="0.25"/>'
    defs = (
        f'<defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>'
        '<filter id="sh" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="18" stdDeviation="22" flood-color="#0B1A33" flood-opacity="0.28"/></filter>'
        "</defs>"
    )
    if not mac:
        body = f'<rect width="1024" height="1024" fill="url(#bg)"/>{glow}{sparkle}{art}'
        return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">{defs}{body}</svg>'
    # macOS: content inside an 824pt squircle with a soft shadow (Big Sur+ grid)
    tile = "M 285 100 L 739 100 C 841 100 924 183 924 285 L 924 739 C 924 841 841 924 739 924 L 285 924 C 183 924 100 841 100 739 L 100 285 C 100 183 183 100 285 100 Z"
    inner = f'<g clip-path="url(#tile)"><rect width="1024" height="1024" fill="url(#bg)"/>{glow}<g transform="translate(512 512) scale(0.805) translate(-512 -512)">{sparkle}{art}</g></g>'
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">{defs}'
        f'<clipPath id="tile"><path d="{tile}"/></clipPath>'
        f'<path d="{tile}" fill="#AFC7E8" filter="url(#sh)"/>{inner}</svg>'
    )


def write_icons():
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, "icons")
    os.makedirs(out, exist_ok=True)
    for name, kw in {"icon_light": {}, "icon_dark": {"dark": True}, "icon_mac": {"mac": True}}.items():
        with open(os.path.join(out, f"{name}.svg"), "w") as fh:
            fh.write(icon_svg(**kw))


write_icons()
