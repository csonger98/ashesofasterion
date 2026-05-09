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
