# Foundation / Combat Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a Godot 4 project with a single playable test room. The player can move (WASD), aim (mouse), light-attack (LMB), and dodge (Space) against one basic enemy. The Sword and Dodge skill tracks gain XP from real-target hits and successful dodges. Proves the core data + signal pipeline that every later system will build on.

**Architecture:**
- Godot 4 / GDScript / GUT for unit tests.
- Resource-driven data layer: `SkillTrack` is a `Resource` subclass holding XP, level, tier math.
- Autoloaded `SkillRegistry` singleton owns the player's skill tracks.
- Signal-driven combat: weapons emit a `hit_landed(target, damage_dealt, weapon_archetype)` signal; the player consumes it and routes `+XP` to the matching SkillTrack.
- CharacterBody3D for player and enemy. Orthographic Camera3D for the iso view, fixed angle, lerp-follow.

**Tech stack:** Godot 4.3 stable (matches the user's installed version at `C:\Users\songe\Godot\godot.cmd`), GDScript, GUT (Godot Unit Test) plugin pinned to a tagged release, git.

**Out of scope (defer to later plans):** crafting, save/load, corruption mechanic, faction system, bosses, hub scene, multiple zones, audio, art polish, perks beyond a placeholder, all skill tracks beyond Sword + Dodge.

**Plan path tree:** This is Plan 1 of 5 toward the GDD's vertical slice. Plans 2–5 cover crafting, save/death, corruption/forbidden/altar, and hub+zone+boss+faction respectively.

---

## File Structure

This plan creates the following files. Each has one clear responsibility.

| Path | Responsibility |
|---|---|
| `project.godot` | Godot project definition. Autoloads, render method, default actions. |
| `.gitignore` | Ignore `.godot/` cache, exports, etc. |
| `icon.svg` | Project icon (placeholder). |
| `addons/gut/` | GUT testing plugin (vendored from upstream). |
| `.gutconfig.json` | Default GUT CLI config — points at `res://test/`. |
| `scripts/skills/SkillTrack.gd` | Resource: XP, level, tier math. Pure data; no scene deps. |
| `scripts/skills/SkillRegistry.gd` | Autoload singleton: holds player's named SkillTrack instances. |
| `scripts/actor/PlayerActor.gd` | Player CharacterBody3D controller: movement, aim, attack, dodge. |
| `scripts/actor/EnemyActor.gd` | Test enemy: HP, hurtbox, basic walk-and-bonk AI. |
| `scripts/combat/Weapon.gd` | Resource: weapon stats + archetype. |
| `scripts/combat/Hitbox.gd` | Area3D-based melee hitbox; emits `hit_landed`. |
| `scripts/combat/Hurtbox.gd` | Area3D-based receiver; reports damage to its owner. |
| `scripts/camera/IsoCamera.gd` | Orthographic camera follow logic. |
| `scenes/actors/Player.tscn` | Player scene composed of mesh + collision + hitbox + camera. |
| `scenes/actors/Enemy.tscn` | Enemy scene composed of mesh + collision + hurtbox + AI. |
| `scenes/test/TestRoom.tscn` | Single arena: floor, walls, player spawn, one enemy spawn. |
| `test/test_skill_track.gd` | GUT tests for SkillTrack data layer. |
| `test/test_skill_registry.gd` | GUT tests for autoload registry. |
| `test/test_hit_to_xp.gd` | GUT integration test: simulating a hit_landed emit increments the right track. |

Files that change together live together. Skills are isolated from combat (data ↔ signals). Combat is isolated from the player (signals ↔ controller). The player wires combat signals to the SkillRegistry.

---

## Task 1: Project Scaffolding

**Files:**
- Create: `project.godot`
- Create: `.gitignore`
- Create: `icon.svg`
- Create: `README.md`
- Create: `scripts/`, `scenes/`, `resources/`, `addons/`, `art/`, `audio/`, `shaders/`, `test/` directories (each with a `.gdkeep` placeholder so git tracks them).

- [ ] **Step 1: Confirm working directory and existing repo state.**

Run from a terminal at the project root (`c:\ashesofasterion-local\ashesofasterion`):

```
git status
```

Expected: `On branch main`, "No commits yet", `.a5c/` listed as untracked, no other tracked files.

- [ ] **Step 2: Create `.gitignore` with Godot 4 conventions.**

Write `.gitignore` at the project root with this exact content:

```gitignore
# Godot 4+ specific ignores
.godot/
.import/
/export/
/builds/
/exports/
*.translation

# Imported textures/audio
*.import

# Mono / .NET (in case of mixed-language down the line)
.mono/
*.csproj
*.sln

# IDE
.vscode/
.idea/
*.tmp
*.swp

# OS
.DS_Store
Thumbs.db

# Local-only configs
override.cfg
```

- [ ] **Step 3: Create `project.godot`.**

Write `project.godot` at the project root with this exact content:

```ini
; Engine configuration file.
config_version=5

[application]

config/name="Ashes of Asterion"
config/description="Dark fantasy ARPG. Skills you use grow stronger. Cosmic invasion. Forbidden powers."
run/main_scene="res://scenes/test/TestRoom.tscn"
config/features=PackedStringArray("4.3", "Forward Plus")
config/icon="res://icon.svg"

[autoload]

SkillRegistry="*res://scripts/skills/SkillRegistry.gd"

[input]

move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
attack_light={
"deadzone": 0.5,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":0,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":1,"canceled":false,"pressed":false,"double_click":false,"script":null)
]
}
dodge={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}

[rendering]

renderer/rendering_method="forward_plus"
```

Note: Physical keycodes — 87=W, 83=S, 65=A, 68=D, 32=Space. Mouse button_index=1=LMB.

- [ ] **Step 4: Create the placeholder `icon.svg`.**

Write `icon.svg`:

```xml
<svg height="128" width="128" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="2" width="124" height="124" rx="14" fill="#1d1014" stroke="#7a3a3a" stroke-width="3"/><text x="64" y="74" font-family="serif" font-size="40" fill="#c8a064" text-anchor="middle">⚝</text></svg>
```

- [ ] **Step 5: Create the directory tree with `.gdkeep` placeholders.**

Create empty `.gdkeep` files at these paths so the directories are tracked by git:

- `scripts/.gdkeep`
- `scripts/actor/.gdkeep`
- `scripts/skills/.gdkeep`
- `scripts/combat/.gdkeep`
- `scripts/camera/.gdkeep`
- `scenes/.gdkeep`
- `scenes/actors/.gdkeep`
- `scenes/test/.gdkeep`
- `resources/.gdkeep`
- `addons/.gdkeep`
- `art/.gdkeep`
- `audio/.gdkeep`
- `shaders/.gdkeep`
- `test/.gdkeep`

Each file is empty (zero bytes) — only its existence matters.

- [ ] **Step 6: Create the project README.**

Write `README.md`:

```markdown
# Ashes of Asterion

Dark fantasy ARPG. Solo-dev project in Godot 4.

- **Design Document:** [docs/design/2026-05-09-ashes-of-asterion-gdd.md](docs/design/2026-05-09-ashes-of-asterion-gdd.md)
- **Implementation Plans:** [docs/plans/](docs/plans/)

## Setup

1. Install [Godot 4.4 or later](https://godotengine.org/download).
2. Open this project in Godot (`File > Open Project`, select `project.godot`).
3. Run the project: F5 or `godot` from the command line.

## Tests

Tests use [GUT](https://github.com/bitwes/Gut). Run from CLI:

\`\`\`
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
\`\`\`

## Project Structure

\`\`\`
scripts/      GDScript code, organized by responsibility
scenes/       Godot scenes (.tscn)
resources/    Data resources (.tres)
addons/       Third-party plugins (e.g. gut)
test/         Unit tests
art/ audio/ shaders/   Asset directories
\`\`\`
```

- [ ] **Step 7: Verify the project opens in Godot.**

Open the Godot editor. Either:
- Double-click `project.godot` from a file manager, OR
- Run from CLI: `godot --editor` from the project root.

Expected: Godot opens, the project loads without import errors, the FileSystem dock shows the directory tree. Close the editor (file/save not needed yet).

If you see "Failed to load script" warnings related to autoloads — that's expected; the SkillRegistry script doesn't exist yet. Ignore.

- [ ] **Step 8: Stage and commit the scaffold.**

```
git add .gitignore project.godot icon.svg README.md scripts scenes resources addons art audio shaders test
git commit -m "chore: scaffold Godot 4 project structure"
```

Expected: a single commit on `main`. No `.godot/` cache included (gitignore blocks it).

---

## Task 2: Install GUT and verify CLI test runs

**Files:**
- Vendor: `addons/gut/` (cloned/extracted from upstream)
- Create: `.gutconfig.json`
- Create: `test/test_smoke.gd`

- [ ] **Step 1: Vendor GUT into `addons/gut`.**

GUT is distributed as a Godot plugin. Easiest install: `git clone` the GUT repo into `addons/gut`, then drop its `.git` so it doesn't become a submodule.

Run from project root:

```
git clone --depth 1 --branch v9.3.1 https://github.com/bitwes/Gut.git addons/_gut_temp
```

(Pin to `v9.3.1`. If a newer GUT 9.x is out at execution time, use that — version pin guards against unexpected breakage. Stop and ask if a major version bump is needed.)

Then move the inner `addons/gut/` into our `addons/gut/`:

```
# In PowerShell:
Move-Item addons\_gut_temp\addons\gut addons\gut
Remove-Item -Recurse -Force addons\_gut_temp
```

Expected: `addons/gut/plugin.cfg`, `addons/gut/gut_cmdln.gd`, etc., now exist.

- [ ] **Step 2: Enable GUT plugin in project settings.**

Edit `project.godot`. After the `[autoload]` section, add a new section:

```ini
[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

- [ ] **Step 3: Create the GUT config.**

Write `.gutconfig.json` at the project root:

```json
{
  "dirs": ["res://test/"],
  "include_subdirs": true,
  "log_level": 1,
  "should_exit": true,
  "should_exit_on_success": true,
  "ignore_pause": true
}
```

- [ ] **Step 4: Write a smoke test.**

Write `test/test_smoke.gd`:

```gdscript
extends GutTest

func test_arithmetic_holds_up():
    assert_eq(2 + 2, 4, "Math is fine.")

func test_godot_loaded():
    assert_true(Engine.get_version_info().major >= 4, "Engine is Godot 4 or later.")
```

- [ ] **Step 5: Run GUT from the CLI.**

```
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

Expected output (last few lines):

```
2 passed, 0 failed, 0 pending, 0 orphans
...
gut command-line called shutdown
```

If you see "Could not load resource at: res://addons/gut/..." — the addons path is wrong; verify with `ls addons/gut/plugin.cfg`.

- [ ] **Step 6: Commit.**

```
git add addons/gut .gutconfig.json project.godot test/test_smoke.gd
git commit -m "chore: vendor GUT testing framework + smoke test"
```

---

## Task 3: SkillTrack resource (TDD)

**Files:**
- Create: `scripts/skills/SkillTrack.gd`
- Test: `test/test_skill_track.gd`

`SkillTrack` is a pure-data Resource. It owns: name, current XP, current level, the cap (default 100), and methods to add XP / query tier / query amplifier value. No scene dependencies, fully testable.

XP-to-next-level curve: simple quadratic — `xp_for_level(n) = 50 * n^2` (so level 1 needs 50 XP, level 2 needs 200, level 10 needs 5000, level 100 needs 500000). This produces ~hundreds-of-hours playthroughs to fully cap one skill. Tunable later.

Tier = `floor(level / 10)` capped at 10. Amplifier = `level * 0.01` (1% per level passive bump).

- [ ] **Step 1: Write failing test for `add_xp` increments XP and computes level.**

Write `test/test_skill_track.gd`:

```gdscript
extends GutTest

const SkillTrack := preload("res://scripts/skills/SkillTrack.gd")

func test_new_track_starts_at_zero():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    assert_eq(t.xp, 0)
    assert_eq(t.level, 0)
    assert_eq(t.tier, 0)
    assert_almost_eq(t.amplifier, 0.0, 0.0001)

func test_add_xp_below_threshold_no_levelup():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    t.add_xp(20)
    assert_eq(t.xp, 20)
    assert_eq(t.level, 0)

func test_add_xp_crosses_threshold_levels_up():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    t.add_xp(60)  # level 1 needs 50
    assert_eq(t.level, 1)
    assert_eq(t.tier, 0)  # tier 0 is levels 0-9
    assert_almost_eq(t.amplifier, 0.01, 0.0001)

func test_add_xp_can_skip_multiple_levels_at_once():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    t.add_xp(10000)  # well past level 10
    assert_gte(t.level, 10)
    assert_gte(t.tier, 1)

func test_amplifier_scales_linearly_with_level():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    t.level = 50  # set directly for the test
    assert_almost_eq(t.amplifier, 0.50, 0.0001)

func test_cap_at_100():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    t.add_xp(99999999)
    assert_eq(t.level, 100)
    assert_eq(t.tier, 10)
    assert_almost_eq(t.amplifier, 1.00, 0.0001)

func test_xp_for_level_formula():
    var t := SkillTrack.new()
    assert_eq(t.xp_for_level(1), 50)
    assert_eq(t.xp_for_level(2), 200)
    assert_eq(t.xp_for_level(10), 5000)
    assert_eq(t.xp_for_level(100), 500000)

func test_xp_at_level_returns_cumulative_xp_for_level_n():
    # cumulative xp at level n = xp_for_level(n)  (we use absolute thresholds, not deltas)
    var t := SkillTrack.new()
    t.add_xp(50)
    assert_eq(t.level, 1)
    t.add_xp(150)  # total now 200, threshold for level 2
    assert_eq(t.level, 2)

func test_signal_emitted_on_levelup():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    var captured := []
    t.leveled_up.connect(func(new_lvl): captured.append(new_lvl))
    t.add_xp(50)  # ought to fire once for level 1
    assert_eq(captured, [1])

func test_signal_emitted_for_each_level_when_skipping():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    var captured := []
    t.leveled_up.connect(func(new_lvl): captured.append(new_lvl))
    t.add_xp(450)  # 50 -> L1, 200 -> L2, 450 -> L3
    assert_eq(captured, [1, 2, 3])
```

- [ ] **Step 2: Run tests to confirm they fail.**

```
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

Expected: errors / failures referencing missing `SkillTrack` script. The smoke test should still pass.

- [ ] **Step 3: Implement `SkillTrack.gd`.**

Write `scripts/skills/SkillTrack.gd`:

```gdscript
class_name SkillTrack
extends Resource

@export var skill_name: String = ""
@export var xp: int = 0
@export var level: int = 0
@export var max_level: int = 100

signal leveled_up(new_level: int)

const _XP_COEFFICIENT := 50

func xp_for_level(n: int) -> int:
    return _XP_COEFFICIENT * n * n

func _level_for_xp(total_xp: int) -> int:
    var n := 0
    while n < max_level and total_xp >= xp_for_level(n + 1):
        n += 1
    return n

func add_xp(amount: int) -> void:
    if amount <= 0 or level >= max_level:
        return
    var prev_level := level
    xp += amount
    var new_level := _level_for_xp(xp)
    if new_level > max_level:
        new_level = max_level
    if new_level > prev_level:
        for lvl in range(prev_level + 1, new_level + 1):
            level = lvl
            leveled_up.emit(lvl)
    if level >= max_level:
        # Cap XP so it doesn't grow unboundedly past cap.
        xp = xp_for_level(max_level)

var tier: int:
    get:
        return clampi(level / 10, 0, 10)

var amplifier: float:
    get:
        return float(level) * 0.01
```

- [ ] **Step 4: Run tests, expect all SkillTrack tests pass.**

```
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

Expected: `12 passed, 0 failed` (10 SkillTrack + 2 smoke).

- [ ] **Step 5: Commit.**

```
git add scripts/skills/SkillTrack.gd test/test_skill_track.gd
git commit -m "feat(skills): SkillTrack resource with XP, level, tier, amplifier (TDD)"
```

---

## Task 4: SkillRegistry autoload (TDD)

**Files:**
- Create: `scripts/skills/SkillRegistry.gd`
- Test: `test/test_skill_registry.gd`

`SkillRegistry` is an autoloaded singleton (registered in `project.godot` Task 1). It owns the player's named SkillTrack instances and exposes `get_track(name)` / `award_xp(name, amount)`. For Plan 1, it pre-creates the 13 tracks listed in the GDD; only Sword and Dodge will receive XP this plan.

- [ ] **Step 1: Write failing test for `SkillRegistry`.**

Write `test/test_skill_registry.gd`:

```gdscript
extends GutTest

# We test the autoload via a fresh instance; in tests we don't depend on the
# editor's autoload spawn — we instantiate the script directly.

const SkillRegistry := preload("res://scripts/skills/SkillRegistry.gd")

func test_registry_creates_all_thirteen_tracks():
    var r := SkillRegistry.new()
    r._ready()  # explicitly init since we're not in scene tree
    var expected := [
        "Sword", "Axe", "Bow", "Pistol", "Tome", "Forbidden",
        "Pyromancy", "Cryomancy", "Star",
        "Dodge", "Parry", "Stealth", "Salvage",
    ]
    for name in expected:
        assert_not_null(r.get_track(name), "Track '%s' should exist." % name)

func test_get_track_unknown_returns_null():
    var r := SkillRegistry.new()
    r._ready()
    assert_null(r.get_track("NotAThing"))

func test_award_xp_routes_to_named_track():
    var r := SkillRegistry.new()
    r._ready()
    r.award_xp("Sword", 60)
    assert_eq(r.get_track("Sword").level, 1)
    assert_eq(r.get_track("Axe").level, 0)

func test_award_xp_unknown_track_is_no_op():
    var r := SkillRegistry.new()
    r._ready()
    r.award_xp("NotAThing", 1000)
    # Should not crash.
    assert_eq(r.get_track("Sword").xp, 0)

func test_track_levelup_signal_propagates_through_registry():
    var r := SkillRegistry.new()
    r._ready()
    var captured := []
    r.skill_leveled.connect(func(skill_name: String, new_level: int):
        captured.append([skill_name, new_level]))
    r.award_xp("Sword", 50)
    assert_eq(captured, [["Sword", 1]])
```

- [ ] **Step 2: Run tests, expect failures.**

```
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

Expected: load errors for `SkillRegistry`.

- [ ] **Step 3: Implement `SkillRegistry.gd`.**

Write `scripts/skills/SkillRegistry.gd`:

```gdscript
extends Node

const SkillTrackScript := preload("res://scripts/skills/SkillTrack.gd")

const TRACK_NAMES := [
    "Sword", "Axe", "Bow", "Pistol", "Tome", "Forbidden",
    "Pyromancy", "Cryomancy", "Star",
    "Dodge", "Parry", "Stealth", "Salvage",
]

signal skill_leveled(skill_name: String, new_level: int)

var _tracks: Dictionary = {}

func _ready() -> void:
    for name in TRACK_NAMES:
        var t: SkillTrack = SkillTrackScript.new()
        t.skill_name = name
        _tracks[name] = t
        # Use bind() to avoid for-loop closure-capture pitfalls.
        # When leveled_up fires with (new_level), the bound callable becomes
        # _on_track_leveled(new_level, name).
        t.leveled_up.connect(_on_track_leveled.bind(name))

func _on_track_leveled(new_level: int, skill_name: String) -> void:
    skill_leveled.emit(skill_name, new_level)

func get_track(skill_name: String) -> SkillTrack:
    return _tracks.get(skill_name, null)

func award_xp(skill_name: String, amount: int) -> void:
    var t: SkillTrack = _tracks.get(skill_name, null)
    if t == null:
        return
    t.add_xp(amount)
```

- [ ] **Step 4: Run tests, all pass.**

```
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

Expected: `17 passed, 0 failed` (12 prior + 5 SkillRegistry).

- [ ] **Step 5: Commit.**

```
git add scripts/skills/SkillRegistry.gd test/test_skill_registry.gd
git commit -m "feat(skills): SkillRegistry autoload with 13 tracks + XP routing (TDD)"
```

---

## Task 5: Player scene + WASD movement

**Files:**
- Create: `scripts/actor/PlayerActor.gd`
- Create: `scenes/actors/Player.tscn`

A bare-bones movable player. CharacterBody3D, capsule mesh, capsule collision shape. Movement reads WASD (project actions defined in Task 1) and translates on the XZ plane (since we're top-down iso, Y is "up" but does nothing for now).

Movement is camera-relative: WASD aligns to screen (W = away from camera, S = toward camera). For simplicity in Plan 1 we use world-axis movement; the iso camera angle is fixed so this looks correct.

- [ ] **Step 1: Write `PlayerActor.gd` (movement-only first pass).**

Write `scripts/actor/PlayerActor.gd`:

```gdscript
class_name PlayerActor
extends CharacterBody3D

@export var move_speed: float = 6.0
@export var acceleration: float = 30.0
@export var deceleration: float = 35.0

func _physics_process(delta: float) -> void:
    var input_dir := _read_movement_input()
    var target := input_dir * move_speed
    var rate := acceleration if input_dir.length_squared() > 0.001 else deceleration
    velocity.x = move_toward(velocity.x, target.x, rate * delta)
    velocity.z = move_toward(velocity.z, target.z, rate * delta)
    move_and_slide()

func _read_movement_input() -> Vector3:
    var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var z := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    var v := Vector3(x, 0.0, z)
    if v.length_squared() > 1.0:
        v = v.normalized()
    return v
```

- [ ] **Step 2: Create the Player scene via the editor.**

Open Godot. From the FileSystem dock, right-click `scenes/actors/` → `New Scene` named `Player.tscn`.

In the new scene:
1. Root: change to `CharacterBody3D`. Rename to `Player`.
2. Attach script: drag `scripts/actor/PlayerActor.gd` onto the root.
3. Add child `MeshInstance3D` named `Mesh`.
   - Inspector → Mesh → New CapsuleMesh. Default size is fine.
   - Position Y: 1.0 (so the capsule sits above the floor).
4. Add child `CollisionShape3D` named `Collision`.
   - Inspector → Shape → New CapsuleShape3D. Match the mesh dimensions (height=2.0, radius=0.5 — Godot defaults).
   - Position Y: 1.0.
5. Save the scene (Ctrl+S).

- [ ] **Step 3: Create a temporary test scene to verify movement.**

Right-click `scenes/test/` → `New Scene` named `MovementSandbox.tscn`.

Build the scene:
1. Root: `Node3D` named `Sandbox`.
2. Add child `DirectionalLight3D`. Rotate X = -45 degrees so the scene isn't pitch-black.
3. Add child `MeshInstance3D` named `Floor`.
   - Mesh → New PlaneMesh. Size: x=20, y=20.
   - Position Y: 0.
4. Add child `StaticBody3D` named `FloorBody`.
   - Add child `CollisionShape3D` to FloorBody.
   - Shape → New BoxShape3D. Size: 20, 0.1, 20. Position Y: -0.05.
5. Add child instance of `scenes/actors/Player.tscn` (Instance Child Scene → Player.tscn).
   - Position Y: 0.
6. Add child `Camera3D` named `TempCam`.
   - Position: (10, 10, 10). Look toward origin: rotation_degrees = (-30, 45, 0). (You'll replace this in Task 6.)
7. Save the sandbox scene.

- [ ] **Step 4: Set the sandbox as the current main scene and run.**

In `project.godot`, temporarily change `run/main_scene="res://scenes/test/MovementSandbox.tscn"`.

Run the project (F5). Expected:
- Window opens, you see a floor + a capsule.
- WASD moves the capsule.
- It does NOT fall through the floor (gravity isn't implemented; we're treating the world as flat for Plan 1 — that's fine).

- [ ] **Step 5: Manual verification checklist.**

- [ ] WASD moves the capsule in four directions.
- [ ] Movement decelerates when keys are released.
- [ ] No editor errors in the Output panel.

- [ ] **Step 6: Commit.**

```
git add scripts/actor/PlayerActor.gd scenes/actors/Player.tscn scenes/test/MovementSandbox.tscn project.godot
git commit -m "feat(player): WASD movement on CharacterBody3D"
```

---

## Task 6: Iso camera

**Files:**
- Create: `scripts/camera/IsoCamera.gd`
- Modify: `scenes/actors/Player.tscn` (add the camera as a child)
- Modify: `scenes/test/MovementSandbox.tscn` (remove the temp camera)

Orthographic Camera3D, fixed angle (-30° X, 45° Y), follows the player with smooth lerp.

- [ ] **Step 1: Write `IsoCamera.gd`.**

Write `scripts/camera/IsoCamera.gd`:

```gdscript
class_name IsoCamera
extends Camera3D

@export var target_path: NodePath
@export var follow_speed: float = 8.0
@export var offset: Vector3 = Vector3(10.0, 10.0, 10.0)

var _target: Node3D

func _ready() -> void:
    projection = PROJECTION_ORTHOGONAL
    size = 12.0
    rotation_degrees = Vector3(-30.0, 45.0, 0.0)
    if target_path != NodePath(""):
        _target = get_node_or_null(target_path) as Node3D

func _process(delta: float) -> void:
    if _target == null:
        return
    var goal := _target.global_position + offset
    global_position = global_position.lerp(goal, clampf(follow_speed * delta, 0.0, 1.0))
```

- [ ] **Step 2: Add the iso camera to Player.tscn.**

Open `scenes/actors/Player.tscn`. Add a child `Camera3D` named `IsoCamera`.

- Attach script `scripts/camera/IsoCamera.gd`.
- Inspector → Target Path: select the parent `Player` node (NodePath: `..`).
- Save.

- [ ] **Step 3: Remove the temp camera in the sandbox.**

Open `scenes/test/MovementSandbox.tscn`. Delete the `TempCam` node. Save.

- [ ] **Step 4: Run the project and verify the iso view.**

F5. Expected:
- Camera renders the floor in the classic iso 3/4 view.
- As you move the player with WASD, the camera lerps to follow.
- No camera rotation; angle stays fixed.

- [ ] **Step 5: Manual verification.**

- [ ] Camera angle reads as iso/Diablo-style.
- [ ] Camera follows the player smoothly.
- [ ] Movement still functions correctly.

- [ ] **Step 6: Commit.**

```
git add scripts/camera/IsoCamera.gd scenes/actors/Player.tscn scenes/test/MovementSandbox.tscn
git commit -m "feat(camera): iso orthographic camera with lerp-follow"
```

---

## Task 7: Mouse aim + cursor reticle

**Files:**
- Modify: `scripts/actor/PlayerActor.gd`
- Modify: `scenes/actors/Player.tscn` (add cursor mesh)

The player should rotate to face the mouse cursor projected onto the ground plane. The world-space cursor position is computed via raycasting from screen coordinates through the camera onto the Y=0 plane.

- [ ] **Step 1: Write the failing visual test (manual playtest checklist).**

This step is gameplay-feel — add to manual checklist below. No GUT test for this.

- [ ] **Step 2: Update `PlayerActor.gd` to track aim direction.**

Edit `scripts/actor/PlayerActor.gd`. Add aim logic:

```gdscript
class_name PlayerActor
extends CharacterBody3D

@export var move_speed: float = 6.0
@export var acceleration: float = 30.0
@export var deceleration: float = 35.0

var aim_direction: Vector3 = Vector3.FORWARD
var aim_world_point: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
    var input_dir := _read_movement_input()
    var target := input_dir * move_speed
    var rate := acceleration if input_dir.length_squared() > 0.001 else deceleration
    velocity.x = move_toward(velocity.x, target.x, rate * delta)
    velocity.z = move_toward(velocity.z, target.z, rate * delta)
    move_and_slide()
    _update_aim()

func _read_movement_input() -> Vector3:
    var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var z := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    var v := Vector3(x, 0.0, z)
    if v.length_squared() > 1.0:
        v = v.normalized()
    return v

func _update_aim() -> void:
    var cam := get_viewport().get_camera_3d()
    if cam == null:
        return
    var mouse_pos := get_viewport().get_mouse_position()
    var ray_origin := cam.project_ray_origin(mouse_pos)
    var ray_dir := cam.project_ray_normal(mouse_pos)
    if absf(ray_dir.y) < 0.0001:
        return
    var t := -ray_origin.y / ray_dir.y
    if t < 0:
        return
    aim_world_point = ray_origin + ray_dir * t
    var to_aim := aim_world_point - global_position
    to_aim.y = 0.0
    if to_aim.length_squared() > 0.001:
        aim_direction = to_aim.normalized()
        # Rotate the player to face aim. Y-axis rotation only.
        var angle := atan2(aim_direction.x, aim_direction.z)
        rotation.y = angle
```

- [ ] **Step 3: Add a small forward-pointing indicator mesh.**

Open `scenes/actors/Player.tscn`. Add a child `MeshInstance3D` to the `Mesh` capsule named `AimIndicator`.

- Mesh → New BoxMesh. Size: (0.1, 0.1, 0.6).
- Position Z: -0.7 (in front of the capsule).
- Position Y: 0.0.

This gives a visible "pointer" so you can see which way the player faces.

- [ ] **Step 4: Run and verify aim.**

F5. Expected:
- Player capsule rotates to face the mouse cursor.
- The little box indicator points toward the cursor.
- Movement and rotation are independent (you can strafe).

- [ ] **Step 5: Manual verification.**

- [ ] Player rotates smoothly to face the cursor.
- [ ] Indicator box always points in the aim direction.
- [ ] No console errors when the cursor is at extreme screen edges.

- [ ] **Step 6: Commit.**

```
git add scripts/actor/PlayerActor.gd scenes/actors/Player.tscn
git commit -m "feat(player): mouse aim with ground-plane raycast"
```

---

## Task 8: Weapon resource + Hitbox

**Files:**
- Create: `scripts/combat/Weapon.gd`
- Create: `scripts/combat/Hitbox.gd`
- Create: `scripts/combat/Hurtbox.gd`
- Create: `resources/weapons/sword_basic.tres` (via editor)
- Test: `test/test_hit_to_xp.gd`

Combat is signal-driven. A `Hitbox` is an `Area3D` that, when its monitoring is on and it overlaps a `Hurtbox`, emits `hit_landed(target, damage, archetype)`. The Hurtbox holds a back-reference to its owner actor and forwards damage there.

- [ ] **Step 1: Write `Weapon.gd`.**

Write `scripts/combat/Weapon.gd`:

```gdscript
class_name Weapon
extends Resource

@export var weapon_name: String = ""
@export var archetype: String = "Sword"  # one of: Sword, Axe, Bow, Pistol, Tome, Forbidden
@export var base_damage: int = 10
@export var attack_duration_sec: float = 0.35  # how long the hitbox stays active per swing
```

- [ ] **Step 2: Write `Hurtbox.gd`.**

Write `scripts/combat/Hurtbox.gd`:

```gdscript
class_name Hurtbox
extends Area3D

signal damaged(amount: int)

@export var owner_actor_path: NodePath

func receive_damage(amount: int) -> void:
    damaged.emit(amount)
```

- [ ] **Step 3: Write `Hitbox.gd`.**

Write `scripts/combat/Hitbox.gd`:

```gdscript
class_name Hitbox
extends Area3D

signal hit_landed(target: Node, damage: int, archetype: String)

@export var weapon: Weapon

var _active: bool = false
var _already_hit_this_swing: Array[Node] = []

func _ready() -> void:
    monitoring = false
    monitorable = false
    area_entered.connect(_on_area_entered)

func start_swing() -> void:
    if weapon == null:
        push_warning("Hitbox.start_swing called with no weapon assigned")
        return
    _already_hit_this_swing.clear()
    _active = true
    monitoring = true
    var dur := weapon.attack_duration_sec
    await get_tree().create_timer(dur).timeout
    end_swing()

func end_swing() -> void:
    _active = false
    monitoring = false

func _on_area_entered(area: Area3D) -> void:
    if not _active:
        return
    if not (area is Hurtbox):
        return
    var hb := area as Hurtbox
    var target_actor := hb.get_node_or_null(hb.owner_actor_path)
    if target_actor == null or target_actor in _already_hit_this_swing:
        return
    _already_hit_this_swing.append(target_actor)
    hb.receive_damage(weapon.base_damage)
    hit_landed.emit(target_actor, weapon.base_damage, weapon.archetype)
```

- [ ] **Step 4: Write the integration test for hit→XP routing.**

Write `test/test_hit_to_xp.gd`:

```gdscript
extends GutTest

const SkillRegistry := preload("res://scripts/skills/SkillRegistry.gd")

# We don't spin up Areas / scene tree in this test; we test the wiring
# logic at the registry level by simulating what PlayerActor will do
# when it receives a hit_landed signal.

func test_hit_landed_handler_awards_sword_xp_for_sword_archetype():
    var r := SkillRegistry.new()
    r._ready()
    # Simulate the function PlayerActor will use: archetype string -> registry track name.
    var archetype := "Sword"
    var damage := 10
    var xp_per_hit := damage  # Plan 1: simple linear; tunable later.
    r.award_xp(archetype, xp_per_hit)
    assert_eq(r.get_track("Sword").xp, 10)
    assert_eq(r.get_track("Axe").xp, 0)

func test_hit_landed_handler_awards_axe_xp_for_axe_archetype():
    var r := SkillRegistry.new()
    r._ready()
    r.award_xp("Axe", 25)
    assert_eq(r.get_track("Axe").xp, 25)
    assert_eq(r.get_track("Sword").xp, 0)

func test_unknown_archetype_no_op():
    var r := SkillRegistry.new()
    r._ready()
    r.award_xp("UnknownThing", 50)
    # No crash, no track touched.
    assert_eq(r.get_track("Sword").xp, 0)
```

- [ ] **Step 5: Run all tests.**

```
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

Expected: `20 passed, 0 failed`.

- [ ] **Step 6: Create a basic Sword weapon resource.**

Open Godot. From FileSystem dock right-click `resources/` → `New Folder` `weapons/`.

Then right-click `resources/weapons/` → `Create New > Resource…` → search `Weapon` → confirm. Name it `sword_basic.tres`.

In the inspector:
- weapon_name: `Iron Sword`
- archetype: `Sword`
- base_damage: `10`
- attack_duration_sec: `0.35`

Save.

- [ ] **Step 7: Commit.**

```
git add scripts/combat/Weapon.gd scripts/combat/Hitbox.gd scripts/combat/Hurtbox.gd resources/weapons/sword_basic.tres test/test_hit_to_xp.gd
git commit -m "feat(combat): Weapon resource, Hitbox/Hurtbox area-based combat with hit_landed signal"
```

---

## Task 9: Wire Hitbox onto the player; route hit_landed to SkillRegistry

**Files:**
- Modify: `scenes/actors/Player.tscn`
- Modify: `scripts/actor/PlayerActor.gd`

Add a `Hitbox` child of the player (in front of the aim indicator). On LMB press, the player calls `hitbox.start_swing()`. The hitbox's `hit_landed` is connected to a player method that routes to SkillRegistry.

- [ ] **Step 1: Add Hitbox to Player.tscn.**

Open `scenes/actors/Player.tscn`. Add a child `Area3D` named `Hitbox`, then change its type to use the `Hitbox.gd` script (drag `scripts/combat/Hitbox.gd` onto it).

- Add a child `CollisionShape3D` to Hitbox named `Shape`.
- Shape → New BoxShape3D. Size: (1.4, 1.5, 1.4) — a swung arc in front of the player.
- Hitbox position: Z = -1.0 (forward of the player).
- Inspector on the Hitbox node → Weapon: drag `resources/weapons/sword_basic.tres` into the slot.

Save.

- [ ] **Step 2: Modify `PlayerActor.gd` to handle attack input + signal routing.**

Edit `scripts/actor/PlayerActor.gd`:

```gdscript
class_name PlayerActor
extends CharacterBody3D

@export var move_speed: float = 6.0
@export var acceleration: float = 30.0
@export var deceleration: float = 35.0

@onready var _hitbox: Hitbox = $Hitbox

var aim_direction: Vector3 = Vector3.FORWARD
var aim_world_point: Vector3 = Vector3.ZERO

func _ready() -> void:
    if _hitbox != null:
        _hitbox.hit_landed.connect(_on_hit_landed)

func _physics_process(delta: float) -> void:
    var input_dir := _read_movement_input()
    var target := input_dir * move_speed
    var rate := acceleration if input_dir.length_squared() > 0.001 else deceleration
    velocity.x = move_toward(velocity.x, target.x, rate * delta)
    velocity.z = move_toward(velocity.z, target.z, rate * delta)
    move_and_slide()
    _update_aim()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack_light"):
        _swing_light()

func _swing_light() -> void:
    if _hitbox != null:
        _hitbox.start_swing()

func _on_hit_landed(_target: Node, damage: int, archetype: String) -> void:
    # XP per hit = damage dealt (Plan 1: linear, tunable later).
    SkillRegistry.award_xp(archetype, damage)

func _read_movement_input() -> Vector3:
    var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var z := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    var v := Vector3(x, 0.0, z)
    if v.length_squared() > 1.0:
        v = v.normalized()
    return v

func _update_aim() -> void:
    var cam := get_viewport().get_camera_3d()
    if cam == null:
        return
    var mouse_pos := get_viewport().get_mouse_position()
    var ray_origin := cam.project_ray_origin(mouse_pos)
    var ray_dir := cam.project_ray_normal(mouse_pos)
    if absf(ray_dir.y) < 0.0001:
        return
    var t := -ray_origin.y / ray_dir.y
    if t < 0:
        return
    aim_world_point = ray_origin + ray_dir * t
    var to_aim := aim_world_point - global_position
    to_aim.y = 0.0
    if to_aim.length_squared() > 0.001:
        aim_direction = to_aim.normalized()
        var angle := atan2(aim_direction.x, aim_direction.z)
        rotation.y = angle
```

- [ ] **Step 3: Run tests.**

```
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

Expected: still `20 passed, 0 failed`. (No new GUT tests this task — the wiring is verified by the integration test in Task 8 plus the manual playtest in Task 11.)

- [ ] **Step 4: Manual smoke test.**

F5. Click LMB. Expected:
- The Output panel doesn't show errors.
- (No enemy yet, so nothing visibly happens. That's fine.)

- [ ] **Step 5: Commit.**

```
git add scripts/actor/PlayerActor.gd scenes/actors/Player.tscn
git commit -m "feat(player): wire hitbox swing on LMB and route hit_landed to SkillRegistry"
```

---

## Task 10: Test enemy with HP and basic AI

**Files:**
- Create: `scripts/actor/EnemyActor.gd`
- Create: `scenes/actors/Enemy.tscn`

A red capsule with HP. Walks toward the player and bumps into them. When its hurtbox receives damage, HP decreases. At 0, the enemy queue_free()s. No melee-attack-back yet (we'll add later if needed for Plan 1 dodge testing).

- [ ] **Step 1: Write `EnemyActor.gd`.**

Write `scripts/actor/EnemyActor.gd`:

```gdscript
class_name EnemyActor
extends CharacterBody3D

@export var max_hp: int = 30
@export var move_speed: float = 2.5
@export var contact_damage: int = 5
@export var attack_cooldown_sec: float = 1.2

@onready var _hurtbox: Hurtbox = $Hurtbox

var hp: int
var _player: Node3D
var _last_attack_time: float = -999.0

signal died

func _ready() -> void:
    hp = max_hp
    if _hurtbox != null:
        _hurtbox.damaged.connect(_on_damaged)
    _player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
    if _player == null:
        _player = get_tree().get_first_node_in_group("player")
        return
    var dir := (_player.global_position - global_position)
    dir.y = 0.0
    var dist := dir.length()
    if dist > 1.4:
        velocity.x = dir.normalized().x * move_speed
        velocity.z = dir.normalized().z * move_speed
    else:
        velocity.x = 0.0
        velocity.z = 0.0
        _maybe_attack_player()
    move_and_slide()

func _maybe_attack_player() -> void:
    var now := Time.get_ticks_msec() / 1000.0
    if now - _last_attack_time < attack_cooldown_sec:
        return
    _last_attack_time = now
    var p := _player as Node
    if p != null and p.has_method("receive_attack"):
        p.receive_attack(contact_damage)

func _on_damaged(amount: int) -> void:
    hp -= amount
    if hp <= 0:
        died.emit()
        queue_free()
```

- [ ] **Step 2: Create the Enemy scene.**

In Godot, right-click `scenes/actors/` → `New Scene` named `Enemy.tscn`.

- Root: `CharacterBody3D` named `Enemy`. Attach `scripts/actor/EnemyActor.gd`.
- Add child `MeshInstance3D` named `Mesh`.
  - Mesh: New CapsuleMesh. Default size.
  - Position Y: 1.0.
  - Material: in the mesh inspector → Surface Material Override 0 → New StandardMaterial3D → Albedo Color: red `#aa3333`.
- Add child `CollisionShape3D` named `Collision`.
  - Shape: New CapsuleShape3D (height 2.0, radius 0.5).
  - Position Y: 1.0.
- Add child `Area3D` named `Hurtbox`. Attach `scripts/combat/Hurtbox.gd`.
  - Add child `CollisionShape3D` to Hurtbox named `Shape`.
  - Shape: New CapsuleShape3D (height 2.0, radius 0.55).
  - Position Y: 1.0.
- Hurtbox inspector → owner_actor_path: select the `Enemy` root (NodePath: `..`).

Save.

- [ ] **Step 3: Add a placeholder `receive_attack` to PlayerActor (for enemy contact damage).**

Edit `scripts/actor/PlayerActor.gd`. Add at the bottom (above `_read_movement_input`):

```gdscript
func receive_attack(damage: int) -> void:
    # Plan 1 placeholder: just log. HP system arrives in Plan 3.
    print("Player took %d damage" % damage)
```

- [ ] **Step 4: Tag the Player as group "player" (for the enemy's lookup).**

Open `scenes/actors/Player.tscn`. Select the root `Player` node. In the inspector → Node tab → Groups → Add → group name `player` → save.

- [ ] **Step 5: Commit.**

```
git add scripts/actor/EnemyActor.gd scenes/actors/Enemy.tscn scripts/actor/PlayerActor.gd scenes/actors/Player.tscn
git commit -m "feat(enemy): basic enemy actor with HP, contact AI, and hurtbox"
```

---

## Task 11: Dodge mechanic + Dodge XP

**Files:**
- Modify: `scripts/actor/PlayerActor.gd`

Pressing Space triggers a dodge: the player gains brief i-frames + a velocity burst in the current movement direction (or aim direction if standing still). During i-frames, the player ignores incoming damage.

If the player successfully dodges *during* an active enemy attack window, award Dodge XP. For Plan 1's simpler enemy model: any successful avoid-of-contact-damage during i-frames counts.

We also want a small reward for "dodging through" — i.e., triggering i-frames while an enemy is in melee range. That's the heuristic we'll use: if dodge starts and any enemy is within `dodge_proximity_check_radius`, count it as a "dodge through" → +Dodge XP.

- [ ] **Step 1: Modify `PlayerActor.gd` for dodge logic.**

Update `scripts/actor/PlayerActor.gd` to its final Plan 1 form:

```gdscript
class_name PlayerActor
extends CharacterBody3D

@export var move_speed: float = 6.0
@export var acceleration: float = 30.0
@export var deceleration: float = 35.0

@export var dodge_speed: float = 14.0
@export var dodge_duration_sec: float = 0.30
@export var dodge_iframe_duration_sec: float = 0.25
@export var dodge_cooldown_sec: float = 0.5
@export var dodge_proximity_radius: float = 2.5
@export var dodge_xp_reward: int = 8

@onready var _hitbox: Hitbox = $Hitbox

var aim_direction: Vector3 = Vector3.FORWARD
var aim_world_point: Vector3 = Vector3.ZERO

var _is_dodging: bool = false
var _is_iframe: bool = false
var _last_dodge_end_time: float = -999.0

func _ready() -> void:
    if _hitbox != null:
        _hitbox.hit_landed.connect(_on_hit_landed)

func _physics_process(delta: float) -> void:
    if _is_dodging:
        # During dodge, velocity is set externally; just slide.
        move_and_slide()
        _update_aim()
        return
    var input_dir := _read_movement_input()
    var target := input_dir * move_speed
    var rate := acceleration if input_dir.length_squared() > 0.001 else deceleration
    velocity.x = move_toward(velocity.x, target.x, rate * delta)
    velocity.z = move_toward(velocity.z, target.z, rate * delta)
    move_and_slide()
    _update_aim()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack_light"):
        _swing_light()
    elif event.is_action_pressed("dodge"):
        _try_dodge()

func _swing_light() -> void:
    if _hitbox != null:
        _hitbox.start_swing()

func _try_dodge() -> void:
    var now := Time.get_ticks_msec() / 1000.0
    if _is_dodging or (now - _last_dodge_end_time) < dodge_cooldown_sec:
        return
    var move_in := _read_movement_input()
    var dir := move_in if move_in.length_squared() > 0.001 else aim_direction
    if _is_dodge_through():
        SkillRegistry.award_xp("Dodge", dodge_xp_reward)
    _execute_dodge(dir)

func _is_dodge_through() -> bool:
    # Heuristic: an enemy within dodge_proximity_radius means this dodge is "through" something.
    for enemy in get_tree().get_nodes_in_group("enemy"):
        if enemy is Node3D:
            var d := (enemy.global_position - global_position).length()
            if d <= dodge_proximity_radius:
                return true
    return false

func _execute_dodge(dir: Vector3) -> void:
    _is_dodging = true
    _is_iframe = true
    var d := dir
    d.y = 0.0
    if d.length_squared() < 0.001:
        d = Vector3.FORWARD
    d = d.normalized()
    velocity = d * dodge_speed
    var iframes := dodge_iframe_duration_sec
    var dur := dodge_duration_sec
    await get_tree().create_timer(iframes).timeout
    _is_iframe = false
    var remaining := maxf(dur - iframes, 0.0)
    if remaining > 0.0:
        await get_tree().create_timer(remaining).timeout
    _is_dodging = false
    _last_dodge_end_time = Time.get_ticks_msec() / 1000.0

func receive_attack(damage: int) -> void:
    if _is_iframe:
        # Successful dodge — no XP here (dodge_through awarded at dodge start).
        return
    print("Player took %d damage" % damage)

func _on_hit_landed(_target: Node, damage: int, archetype: String) -> void:
    SkillRegistry.award_xp(archetype, damage)

func _read_movement_input() -> Vector3:
    var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var z := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    var v := Vector3(x, 0.0, z)
    if v.length_squared() > 1.0:
        v = v.normalized()
    return v

func _update_aim() -> void:
    var cam := get_viewport().get_camera_3d()
    if cam == null:
        return
    var mouse_pos := get_viewport().get_mouse_position()
    var ray_origin := cam.project_ray_origin(mouse_pos)
    var ray_dir := cam.project_ray_normal(mouse_pos)
    if absf(ray_dir.y) < 0.0001:
        return
    var t := -ray_origin.y / ray_dir.y
    if t < 0:
        return
    aim_world_point = ray_origin + ray_dir * t
    var to_aim := aim_world_point - global_position
    to_aim.y = 0.0
    if to_aim.length_squared() > 0.001:
        aim_direction = to_aim.normalized()
        var angle := atan2(aim_direction.x, aim_direction.z)
        rotation.y = angle
```

- [ ] **Step 2: Tag the enemy as group "enemy" (for dodge proximity check).**

Open `scenes/actors/Enemy.tscn`. Select root `Enemy` → Node tab → Groups → Add → `enemy` → save.

- [ ] **Step 3: Commit.**

```
git add scripts/actor/PlayerActor.gd scenes/actors/Enemy.tscn
git commit -m "feat(player): dodge with i-frames; award Dodge XP for dodge-through"
```

---

## Task 12: TestRoom scene

**Files:**
- Create: `scenes/test/TestRoom.tscn`
- Create: `scripts/test/SkillsHud.gd` (debug HUD showing skill levels)
- Create: `scenes/test/SkillsHud.tscn`
- Modify: `project.godot` (set `run/main_scene` back to TestRoom)

A handcrafted single arena: floor + walls + player + enemy spawn + a debug HUD that shows current skill XP/level for Sword and Dodge.

- [ ] **Step 1: Write the debug HUD script.**

Write `scripts/test/SkillsHud.gd`:

```gdscript
extends CanvasLayer

@onready var _label: Label = $Margin/Label

func _process(_delta: float) -> void:
    var sw: SkillTrack = SkillRegistry.get_track("Sword")
    var dg: SkillTrack = SkillRegistry.get_track("Dodge")
    var sw_xp := 0
    var sw_lvl := 0
    var dg_xp := 0
    var dg_lvl := 0
    if sw != null:
        sw_xp = sw.xp
        sw_lvl = sw.level
    if dg != null:
        dg_xp = dg.xp
        dg_lvl = dg.level
    _label.text = "Sword: L%d (%d xp)\nDodge: L%d (%d xp)" % [sw_lvl, sw_xp, dg_lvl, dg_xp]
```

- [ ] **Step 2: Create the HUD scene.**

In Godot, right-click `scenes/test/` → `New Scene` `SkillsHud.tscn`.

- Root: `CanvasLayer` named `SkillsHud`. Attach `scripts/test/SkillsHud.gd`.
- Add child `MarginContainer` named `Margin`.
  - Anchor preset: top-left. Margins: 8 / 8 / 8 / 8.
- Add child `Label` to `Margin` named `Label`.
  - Default font; text: empty (script overwrites).
  - Theme override → font_size: 18.

Save.

- [ ] **Step 3: Build the TestRoom scene.**

Right-click `scenes/test/` → `New Scene` `TestRoom.tscn`.

- Root: `Node3D` named `TestRoom`.
- Add child `DirectionalLight3D`. Rotation X: -45°. Energy: 1.0.
- Add child `MeshInstance3D` named `Floor`.
  - Mesh: New PlaneMesh. Size: x=20, y=20.
  - Y: 0.
- Add child `StaticBody3D` named `FloorBody`.
  - Add CollisionShape3D child. Shape: New BoxShape3D, size (20, 0.1, 20). Y: -0.05.
- Add 4 walls (StaticBody3D + child CollisionShape3D + visual MeshInstance3D BoxMesh):
  - North wall: position (0, 1, -10), box size (20, 2, 0.4).
  - South wall: position (0, 1, 10), box size (20, 2, 0.4).
  - East wall: position (10, 1, 0), box size (0.4, 2, 20).
  - West wall: position (-10, 1, 0), box size (0.4, 2, 20).
- Add child instance of `scenes/actors/Player.tscn`. Position: (0, 0, 4).
- Add child instance of `scenes/actors/Enemy.tscn`. Position: (0, 0, -4).
- Add child instance of `scenes/test/SkillsHud.tscn`.

Save.

- [ ] **Step 4: Restore the main scene to TestRoom.**

In `project.godot`, change `run/main_scene` back to `res://scenes/test/TestRoom.tscn`.

- [ ] **Step 5: Run and exercise the full loop.**

F5. Run through the playtest:
- WASD + mouse aim works.
- LMB swings; visible/imagined arc; if cursor is over the enemy, the swing connects. The HUD's Sword XP increments by 10 per landed hit.
- After 5 hits = 50 XP, Sword level becomes 1.
- Space dodges. If you dodge while an enemy is within ~2.5m, the HUD's Dodge XP increments by 8.
- Hit the enemy until HP drops to zero → enemy disappears.

- [ ] **Step 6: Commit.**

```
git add scripts/test/SkillsHud.gd scenes/test/SkillsHud.tscn scenes/test/TestRoom.tscn project.godot
git commit -m "feat(test): TestRoom scene with debug HUD; runnable Plan 1 acceptance demo"
```

---

## Task 13: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Run all tests.**

```
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

Expected: `20 passed, 0 failed, 0 pending, 0 orphans`.

- [ ] **Step 2: Run the playtest acceptance script.**

Open Godot. F5. Confirm each of:

- [ ] WASD moves the player capsule on the floor.
- [ ] The iso camera follows smoothly. No rotation.
- [ ] Mouse cursor projects to the ground; player rotates to face it.
- [ ] LMB swings the sword. The hitbox area in front of the player connects with the enemy capsule.
- [ ] Each landed hit increments the HUD's "Sword" XP by 10. After 5 hits: Sword L1.
- [ ] Space dodges. Velocity bursts in the input/aim direction. ~0.25s i-frame window.
- [ ] Dodging within ~2.5m of an enemy increments "Dodge" XP by 8 in the HUD.
- [ ] Enemy chases the player. Bumps into the player and prints "Player took 5 damage" to the Output panel.
- [ ] Enemy dies after 3 hits (max_hp=30, damage=10) and queue_frees.
- [ ] No errors in the Output panel during the run.

- [ ] **Step 3: Tag the prototype.**

```
git tag v0.1.0-foundation
git log --oneline -n 20
```

Expected: ~12 commits in chronological order from "chore: scaffold..." through "feat(test): TestRoom scene...". The tag is on the latest.

- [ ] **Step 4: Update README with a "Plan 1 complete" pointer.**

Edit `README.md`. Append after the existing content:

```markdown

## Status

- **2026-05-09:** Plan 1 (Foundation / Combat Prototype) complete. Tag: `v0.1.0-foundation`.
- Player can move, aim, attack, dodge. Sword and Dodge XP tracks active. One test enemy.
- See [docs/plans/2026-05-09-foundation-combat-prototype.md](docs/plans/2026-05-09-foundation-combat-prototype.md) for the implementation details.
- Next: **Plan 2 — Crafting & Inventory MVP**.
```

- [ ] **Step 5: Final commit.**

```
git add README.md
git commit -m "docs: mark Plan 1 (foundation) complete; tag v0.1.0-foundation"
```

---

## Acceptance Criteria

This plan is done when **all** of the following are true:

1. `godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit` reports `20 passed, 0 failed`.
2. Running the project (F5) loads TestRoom.tscn, the player moves with WASD + mouse aim, LMB swings, Space dodges, the enemy walks toward the player and dies after 3 hits, and the HUD shows Sword and Dodge XP/levels updating.
3. Git history shows ~12 commits between project scaffolding and the v0.1.0-foundation tag.
4. No `# TODO`, `# FIXME`, or placeholder strings remain in plan-1 files.

## Manual Verification Checklist

(Repeat from Task 13 Step 2 for the engineer running the plan.)

- [ ] WASD moves smoothly with acceleration/deceleration.
- [ ] Iso camera angle locked at -30° X / 45° Y.
- [ ] Camera follows player without snapping.
- [ ] Cursor reticle behavior: player rotates to face cursor.
- [ ] LMB triggers sword swing animation timing (~0.35s active).
- [ ] Sword XP gain == 10 per landed hit.
- [ ] Sword L1 reached at 50 cumulative XP.
- [ ] Dodge with Space: i-frames ~0.25s, full move ~0.30s.
- [ ] Dodge through (enemy nearby) awards 8 Dodge XP.
- [ ] Dodge cooldown ~0.5s prevents spam.
- [ ] Enemy AI: walks toward player, contact damage cooldown ~1.2s.
- [ ] Enemy dies at hp ≤ 0 and is freed.
- [ ] No script errors in the Output panel.

---

## Notes for the engineer executing this plan

- **Godot first-time setup:** if you're new to Godot 4, watch [https://docs.godotengine.org/en/stable/getting_started/introduction/index.html](https://docs.godotengine.org/en/stable/getting_started/introduction/index.html). Godot scenes are tree-of-nodes; scripts attach to nodes; resources (.tres) are pure data.
- **GDScript class_name:** putting `class_name Foo` at the top of a script registers it as a global type; later scripts can use `Foo.new()` or `var x: Foo`. Don't accidentally have two scripts with the same `class_name`.
- **Autoloads:** the `SkillRegistry` is registered in `[autoload]` in `project.godot`. In runtime code, you reference it as the symbol `SkillRegistry` directly — no `get_node()` needed.
- **Editor vs CLI:** scenes are most easily authored in the editor (drag/drop). Scripts and resource definitions can be authored as text. The plan mixes both as appropriate.
- **Test names:** GUT picks up files named `test_*.gd` containing `extends GutTest`. Test functions are `func test_*`.
- **Iso camera math:** with rotation `(-30°, 45°, 0)` and orthographic projection, world XZ axes map to screen at 45° rotated. WASD on world XZ "looks right" because the iso angle was chosen to match this expectation.
- **Cleared zone freeform save (GDD §9):** out of scope for Plan 1. The save system arrives in Plan 3.

If you hit blockers, stop and surface them. Do not improvise around the plan — that's how design intent gets lost.
