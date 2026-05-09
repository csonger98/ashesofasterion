# Ashes of Asterion

Dark fantasy ARPG. Solo-dev project in Godot 4.

- **Design Document:** [docs/design/2026-05-09-ashes-of-asterion-gdd.md](docs/design/2026-05-09-ashes-of-asterion-gdd.md)
- **Implementation Plans:** [docs/plans/](docs/plans/)

## Setup

1. Install [Godot 4.3 or later](https://godotengine.org/download).
2. Open this project in Godot (`File > Open Project`, select `project.godot`).
3. Run the project: F5 or `godot` from the command line.

## Tests

Tests use [GUT](https://github.com/bitwes/Gut). Run from CLI:

```
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

## Project Structure

```
scripts/      GDScript code, organized by responsibility
scenes/       Godot scenes (.tscn)
resources/    Data resources (.tres)
addons/       Third-party plugins (e.g. gut)
test/         Unit tests
art/ audio/ shaders/   Asset directories
```
