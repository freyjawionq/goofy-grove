#!/usr/bin/env python3
"""Generate default.project.json for Goofy Grove.

The static 3D world (ground, the Grove, six base plots, paths, trees, the
shop, the egg nests, statues, hills and clouds) is data, so it is generated
deterministically here instead of being hand-typed into one huge JSON file.
Run:  python3 tools/gen_project.py   (writes ../default.project.json)
Gameplay objects the scripts look up by name: Workspace/Bases/Base<n> with
Pad1..Pad14, BankZone, LockDome and SignPost; Workspace/Nests/<EggId>.
"""
import json
import math
import random
import os

rng = random.Random(20261117)


def col(r, g, b):
    return [round(r / 255, 5), round(g / 255, 5), round(b / 255, 5)]


def part(name, pos, size, color, material="Plastic", shape=None, anchored=True,
         cancollide=True, transparency=0.0):
    props = {
        "Anchored": anchored,
        "CanCollide": cancollide,
        "Color": col(*color),
        "Material": material,
        "Position": [round(pos[0], 2), round(pos[1], 2), round(pos[2], 2)],
        "Size": [size[0], size[1], size[2]],
    }
    if shape:
        props["Shape"] = shape
    if transparency:
        props["Transparency"] = transparency
    return {"$className": "Part", "$properties": props}


def folder(name, children):
    node = {"$className": "Folder"}
    node.update(children)
    return name, node


GRASS = (96, 168, 84)
MEADOW = (124, 196, 104)
PATH = (222, 199, 148)
STONE = (148, 148, 152)
WOOD = (128, 90, 54)
DARKWOOD = (96, 66, 40)

workspace = {}

# --- ground, meadow, plaza, ring road and cross paths -----------------------
workspace["Ground"] = part("Ground", (0, -1, 0), (440, 2, 440), GRASS, "Grass")
workspace["Meadow"] = part("Meadow", (0, -0.44, 0), (156, 1, 156), MEADOW, "Grass")
workspace["Plaza"] = part("Plaza", (0, -0.3, 0), (34, 1, 34), STONE, "Slate")
for name, pos, size in (
    ("PathN", (0, -0.4, -62), (10, 1, 60)),
    ("PathS", (0, -0.4, 62), (10, 1, 60)),
    ("PathE", (62, -0.4, 0), (60, 1, 10)),
    ("PathW", (-62, -0.4, 0), (60, 1, 10)),
):
    workspace[name] = part(name, pos, size, PATH, "Sand")
for i in range(48):  # ring road of flat stones at radius 104
    a = i / 48 * math.tau
    workspace[f"RingStone{i + 1}"] = part(
        f"RingStone{i + 1}", (math.cos(a) * 104, -0.35, math.sin(a) * 104),
        (11, 1, 11), PATH, "Sand")

# --- the six base plots ------------------------------------------------------
PLOT_TINTS = [(232, 120, 120), (240, 190, 90), (130, 210, 130),
              (120, 180, 240), (200, 140, 230), (240, 150, 190)]
bases = {}
for idx in range(6):
    a = math.radians(30 + idx * 60)
    cx, cz = math.cos(a) * 138, math.sin(a) * 138
    plot = {}
    plot["Platform"] = part("Platform", (cx, -0.2, cz), (46, 1, 46), PLOT_TINTS[idx], "Concrete")
    n = 0
    for row, dz in enumerate((-11, 0, 11)):
        for dx in (-16, -8, 0, 8, 16):
            n += 1
            if n > 14:
                break
            plot[f"Pad{n}"] = part(f"Pad{n}", (cx + dx, 0.8, cz + dz),
                                   (6.4, 1, 6.4), (245, 242, 235), "SmoothPlastic")
    plot["BankZone"] = part("BankZone", (cx, 0.55, cz + 19), (12, 0.5, 6),
                            (80, 255, 140), "Neon", cancollide=False, transparency=0.35)
    plot["LockDome"] = part("LockDome", (cx, 6, cz), (52, 30, 52),
                            (150, 215, 255), "Glass", shape="Ball",
                            cancollide=False, transparency=1.0)
    plot["SignPostPost"] = part("SignPostPost", (cx + 15, 3, cz + 19), (1, 6, 1), DARKWOOD, "Wood")
    plot["SignPost"] = part("SignPost", (cx + 15, 6.5, cz + 19), (11, 3.4, 0.5), PLOT_TINTS[idx], "Wood")
    for sx, sz in ((-22, -22), (22, -22), (-22, 22), (22, 22)):
        plot[f"Post{sx}_{sz}"] = part(f"Post{sx}_{sz}", (cx + sx, 1.5, cz + sz),
                                      (1.6, 3, 1.6), DARKWOOD, "Wood")
    bases[f"Base{idx + 1}"] = {"$className": "Folder", **plot}
workspace["Bases"] = {"$className": "Folder", **bases}

# --- spawn, welcome sign ------------------------------------------------------
workspace["SpawnLocation"] = {
    "$className": "SpawnLocation",
    "$properties": {
        "Anchored": True, "Color": col(245, 200, 80), "Material": "Slate",
        "Neutral": True, "Position": [0, 0.5, 96], "Size": [14, 1, 14],
    },
}
workspace["WelcomePost1"] = part("WelcomePost1", (-7, 3, 88), (1, 6, 1), DARKWOOD, "Wood")
workspace["WelcomePost2"] = part("WelcomePost2", (7, 3, 88), (1, 6, 1), DARKWOOD, "Wood")
workspace["WelcomeSign"] = part("WelcomeSign", (0, 6.5, 88), (17, 4, 0.5), (250, 214, 90), "Wood")

# --- shop stall ----------------------------------------------------------------
shop = {}
shop["Counter"] = part("Counter", (-30, 1.2, 84), (16, 2.4, 5), WOOD, "Wood")
shop["Post1"] = part("Post1", (-37, 3.4, 81), (1, 6.8, 1), DARKWOOD, "Wood")
shop["Post2"] = part("Post2", (-23, 3.4, 81), (1, 6.8, 1), DARKWOOD, "Wood")
shop["Roof"] = part("Roof", (-30, 7.2, 83), (18, 0.8, 9), (198, 84, 74), "Brick")
shop["Sign"] = part("Sign", (-30, 5.4, 80.4), (12, 2.6, 0.5), (250, 214, 90), "Wood")
workspace["Shop"] = {"$className": "Folder", **shop}

# --- egg nests ------------------------------------------------------------------
EGGS = (("GroveEgg", (250, 235, 180), 30), ("RoyalEgg", (255, 205, 80), 38),
        ("CosmicEgg", (170, 130, 255), 46))
nests = {}
for egg_id, color, x in EGGS:
    nests[egg_id + "Pedestal"] = part(egg_id + "Pedestal", (x, 0.8, 88), (6, 1.6, 6), STONE, "Slate")
    nests[egg_id] = part(egg_id, (x, 3.4, 88), (3.6, 4.4, 3.6), color, "SmoothPlastic", shape="Ball")
workspace["Nests"] = {"$className": "Folder", **nests}

# --- grove dressing: trees, rocks, flowers, bushes, fence -----------------------
def tree(name, x, z, s=1.0):
    return [
        (name + "Trunk", part(name + "Trunk", (x, 3 * s, z), (1.7 * s, 6 * s, 1.7 * s), (110, 76, 44), "Wood")),
        (name + "Top", part(name + "Top", (x, (6.5 + 1.8) * s, z), (6.4 * s, 5.4 * s, 6.4 * s), (58, 142, 66), "Grass", shape="Ball")),
        (name + "Top2", part(name + "Top2", (x + 2.2 * s, (6.5 + 0.6) * s, z + 1.2 * s), (4.4 * s, 3.8 * s, 4.4 * s), (72, 160, 78), "Grass", shape="Ball")),
    ]

placed = 0
for i in range(90):
    if placed >= 34:
        break
    a = rng.uniform(0, math.tau)
    r = rng.uniform(80, 165)
    x, z = math.cos(a) * r, math.sin(a) * r
    if any((x - math.cos(math.radians(30 + k * 60)) * 138) ** 2 + (z - math.sin(math.radians(30 + k * 60)) * 138) ** 2 < 34 ** 2 for k in range(6)):
        continue  # keep the plots clear
    if abs(x) < 14 or abs(z) < 14:
        continue  # keep the cross paths clear
    for nm, node in tree(f"Tree{placed + 1}", x, z, rng.uniform(0.85, 1.3)):
        workspace[nm] = node
    placed += 1

for i in range(14):
    a = rng.uniform(0, math.tau)
    r = rng.uniform(20, 70)
    x, z = math.cos(a) * r, math.sin(a) * r
    s = rng.uniform(1.4, 3.2)
    workspace[f"Rock{i + 1}"] = part(f"Rock{i + 1}", (x, s * 0.3, z), (s * 1.6, s, s * 1.4), (138, 138, 142), "Slate", shape="Ball")

FLOWER_COLORS = [(255, 105, 160), (255, 220, 90), (150, 120, 255), (255, 140, 90), (120, 220, 255)]
for i in range(44):
    a = rng.uniform(0, math.tau)
    r = rng.uniform(14, 74)
    x, z = math.cos(a) * r, math.sin(a) * r
    workspace[f"Flower{i + 1}"] = part(f"Flower{i + 1}", (x, 0.55, z), (0.85, 0.85, 0.85),
                                       FLOWER_COLORS[i % len(FLOWER_COLORS)], "Neon", shape="Ball", cancollide=False)

for i in range(16):
    a = rng.uniform(0, math.tau)
    r = rng.uniform(76, 96)
    x, z = math.cos(a) * r, math.sin(a) * r
    s = rng.uniform(2.6, 4.4)
    workspace[f"Bush{i + 1}"] = part(f"Bush{i + 1}", (x, s * 0.32, z), (s, s * 0.75, s), (48, 122, 58), "Grass", shape="Ball")

for i in range(40):  # grove fence ring
    a = i / 40 * math.tau
    workspace[f"Fence{i + 1}"] = part(f"Fence{i + 1}", (math.cos(a) * 79, 1.6, math.sin(a) * 79),
                                      (1.1, 3.2, 1.1), WOOD, "Wood")

for i in range(8):  # lamps on the cross paths
    x, z = ((0, -40), (0, 40), (0, -96), (0, 150 - 190), (-40, 0), (40, 0), (-96, 0), (96, 0))[i]
    workspace[f"LampPost{i + 1}"] = part(f"LampPost{i + 1}", (x + 6, 3, z), (0.7, 6, 0.7), (60, 60, 66), "Metal")
    workspace[f"LampBall{i + 1}"] = part(f"LampBall{i + 1}", (x + 6, 6.6, z), (1.6, 1.6, 1.6), (255, 240, 170), "Neon", shape="Ball", cancollide=False)

# --- the Gobbler statue and warning signs at the grove's north edge --------------
statue = {}
statue["Body"] = part("Body", (0, 2.6, -58), (7, 5.2, 7), (120, 124, 128), "Slate", shape="Ball")
statue["Belly"] = part("Belly", (0, 4.6, -57.4), (5.6, 4.2, 5.6), (134, 138, 142), "Slate", shape="Ball")
statue["Mouth"] = part("Mouth", (0, 2.2, -54.4), (4.4, 1.1, 0.6), (60, 60, 64), "Slate")
statue["EyeL"] = part("EyeL", (-1.7, 5.4, -54.9), (1.1, 1.1, 1.1), (90, 92, 96), "Slate", shape="Ball")
statue["EyeR"] = part("EyeR", (1.7, 5.4, -54.9), (1.1, 1.1, 1.1), (90, 92, 96), "Slate", shape="Ball")
statue["SignPost"] = part("SignPost", (8, 2.4, -54), (0.8, 4.8, 0.8), DARKWOOD, "Wood")
statue["Sign"] = part("Sign", (8, 5.2, -54), (8, 2.6, 0.5), (230, 90, 80), "Wood")
workspace["GobblerStatue"] = {"$className": "Folder", **statue}

# --- display statues of three cast members near spawn ------------------------------
def statue_model(prefix, x, z, parts):
    out = {}
    for j, (size, color, material, shape, off) in enumerate(parts):
        out[f"{prefix}P{j + 1}"] = part(f"{prefix}P{j + 1}", (x + off[0], off[1], z + off[2]),
                                        size, color, material, shape=shape)
    out[prefix + "Pedestal"] = part(prefix + "Pedestal", (x, 0.7, z), (7, 1.4, 7), STONE, "Slate")
    return out

workspace.update(statue_model("StatueBopple", -18, 108, [
    ((2.2, 2.2, 2.2), (214, 48, 49), "SmoothPlastic", "Ball", (0, 3.2, 0)),
    ((0.3, 0.9, 0.3), (111, 66, 35), "Plastic", None, (0, 4.6, 0)),
    ((0.9, 0.4, 0.6), (46, 204, 113), "Plastic", "Ball", (0.45, 4.95, 0)),
]))
workspace.update(statue_model("StatueCactus", 0, 114, [
    ((1.8, 3.4, 1.8), (39, 174, 96), "SmoothPlastic", None, (0, 3.8, 0)),
    ((0.9, 1.6, 0.9), (39, 174, 96), "SmoothPlastic", None, (1.3, 4.4, 0)),
    ((0.9, 1.2, 0.9), (39, 174, 96), "SmoothPlastic", None, (-1.3, 4.8, 0)),
    ((0.9, 0.9, 0.9), (255, 95, 205), "Neon", "Ball", (0, 5.9, 0)),
]))
workspace.update(statue_model("StatueGloob", 18, 108, [
    ((3.4, 3, 3.4), (130, 70, 220), "SmoothPlastic", "Ball", (0, 3.4, 0)),
    ((2.4, 1.9, 2.4), (150, 95, 235), "SmoothPlastic", "Ball", (0, 5.3, 0)),
    ((0.8, 0.8, 0.8), (255, 220, 80), "Neon", "Ball", (-0.8, 5.5, 1.4)),
    ((0.8, 0.8, 0.8), (255, 220, 80), "Neon", "Ball", (0.8, 5.5, 1.4)),
]))

# --- hills and clouds ---------------------------------------------------------------
for i in range(8):
    a = i / 8 * math.tau + 0.4
    s = rng.uniform(38, 62)
    workspace[f"Hill{i + 1}"] = part(f"Hill{i + 1}", (math.cos(a) * 208, -s * 0.35, math.sin(a) * 208),
                                     (s, s * 0.62, s), (104, 138, 108), "Grass", shape="Ball")
for i in range(6):
    cx = rng.uniform(-160, 160)
    cz = rng.uniform(-160, 160)
    cy = rng.uniform(54, 68)
    for j in range(3):
        s = rng.uniform(9, 16)
        workspace[f"Cloud{i + 1}_{j + 1}"] = part(
            f"Cloud{i + 1}_{j + 1}", (cx + (j - 1) * 9, cy, cz), (s, s * 0.45, s * 0.8),
            (250, 250, 252), "SmoothPlastic", shape="Ball", cancollide=False)

project = {
    "name": "goofy-grove",
    "tree": {
        "$className": "DataModel",
        "Players": {"$properties": {"CharacterAutoLoads": True}},
        "ServerScriptService": {"Server": {"$path": "src/server"}},
        "ReplicatedStorage": {"Shared": {"$path": "src/shared"}},
        "StarterPlayer": {"StarterPlayerScripts": {"Client": {"$path": "src/client"}}},
        "Workspace": {"$properties": {"FilteringEnabled": True}, **workspace},
        "Lighting": {
            "$properties": {
                "Ambient": [0.55, 0.55, 0.6],
                "Brightness": 3,
                "ClockTime": 14.5,
                "GlobalShadows": True,
                "Outlines": False,
                "Technology": "Voxel",
            }
        },
        "SoundService": {"$properties": {"RespectFilteringEnabled": True}},
    },
}

out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "default.project.json")
with open(out_path, "w") as fh:
    json.dump(project, fh, indent=2)


def count(node):
    total = 0
    for key, value in node.items():
        if isinstance(value, dict):
            if "$className" in value:
                total += 1
            total += count(value)
    return total


print("wrote", out_path, "instances:", count(project["tree"]))
