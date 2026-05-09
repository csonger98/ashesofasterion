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
art/ audio/ shaders/   Asset directories
```
