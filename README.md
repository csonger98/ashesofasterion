# Ashes of Asterion

Dark fantasy ARPG. Solo-dev project in Godot 4.

- **Design Document:** [docs/design/2026-05-09-ashes-of-asterion-gdd.md](docs/design/2026-05-09-ashes-of-asterion-gdd.md)
- **Implementation Plans:** [docs/plans/](docs/plans/)

## Setup

1. Install [Godot 4.6 or later](https://godotengine.org/download).
2. Open this project in Godot (`File > Open Project`, select `project.godot`).
3. Run the project: F5 or `godot` from the command line.

## Tests

Tests use [GUT](https://github.com/bitwes/Gut). Run from CLI:

```
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

> **First-run / CI note:** Godot 4 only registers `class_name` declarations from
> third-party scripts (like GUT's `GutTest`) after a full editor project parse.
> On a fresh clone — or whenever scripts under `addons/` add or change a
> `class_name` — run an editor-quit warmup first (`--headless --import` alone
> is not sufficient). You may need to run it twice on a cold project (the
> first pass scans, the second pass indexes class_names):
>
> ```
> godot --headless --editor --quit-after 1
> ```
>
> Then run the GUT CLI command above.

## Project Structure

```
scripts/      GDScript code, organized by responsibility
scenes/       Godot scenes (.tscn)
resources/    Data resources (.tres)
addons/       Third-party plugins (e.g. gut)
test/         Unit tests
docs/         Design and implementation plans
art/ audio/ shaders/   Asset directories
```

## Status

- **2026-05-09:** Plan 1 (Foundation / Combat Prototype) complete. Tag: `v0.1.0-foundation`.
- Player can move (WASD), aim (mouse), attack (LMB), and dodge (Space). Sword and Dodge XP tracks active. One test enemy walks toward player and dies after 3 hits.
- 20 GUT tests passing across SkillTrack, SkillRegistry, hit→XP routing, and smoke.
- See [docs/plans/2026-05-09-foundation-combat-prototype.md](docs/plans/2026-05-09-foundation-combat-prototype.md) for the implementation details.
- Next: **Plan 2 — Crafting & Inventory MVP**.

## Manual playtest checklist (Plan 1 acceptance)

Run the project (F5 in editor or `godot` from CLI). Verify:

- [ ] WASD moves the player capsule.
- [ ] Iso camera follows smoothly without rotating.
- [ ] Player rotates to face the mouse cursor; aim indicator points at cursor.
- [ ] LMB swings the sword. Each landed hit on the red enemy increments **Sword** XP by 10 in the HUD.
- [ ] After 5 landed hits, Sword reaches L1 (50 XP threshold).
- [ ] Space dodges with brief i-frames and a velocity burst.
- [ ] Dodging within ~2.5m of the enemy increments **Dodge** XP by 8.
- [ ] Enemy walks toward player and prints "Player took 5 damage" to the Output panel on contact (unless dodging through i-frames).
- [ ] Enemy dies after 3 sword hits and is freed.
- [ ] No script errors in the Output panel.
