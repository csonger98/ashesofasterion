extends Node

# Sound effects autoload.
# Drop .ogg or .wav files at the paths below; missing files are silently skipped.
# Use: Sfx.play_at("swing", global_position)
const SOUNDS := {
    "swing": "res://audio/sfx/swing.ogg",
    "hit": "res://audio/sfx/hit.ogg",
    "dodge": "res://audio/sfx/dodge.ogg",
    "enemy_attack": "res://audio/sfx/enemy_attack.ogg",
    "enemy_die": "res://audio/sfx/enemy_die.ogg",
    "player_hurt": "res://audio/sfx/player_hurt.ogg",
    "player_die": "res://audio/sfx/player_die.ogg",
}

@export_range(0.0, 2.0) var volume_scale: float = 1.0

var _streams: Dictionary = {}

func _ready() -> void:
    for key in SOUNDS:
        var path: String = SOUNDS[key]
        if ResourceLoader.exists(path):
            _streams[key] = load(path)

func play_at(key: String, position: Vector3) -> void:
    if not _streams.has(key):
        return
    var p := AudioStreamPlayer3D.new()
    p.stream = _streams[key]
    p.unit_size = 6.0
    p.max_distance = 40.0
    p.volume_db = linear_to_db(volume_scale)
    p.finished.connect(p.queue_free)
    var scene_root := get_tree().current_scene
    if scene_root == null:
        return
    scene_root.add_child(p)
    p.global_position = position
    p.play()

func play_2d(key: String) -> void:
    if not _streams.has(key):
        return
    var p := AudioStreamPlayer.new()
    p.stream = _streams[key]
    p.volume_db = linear_to_db(volume_scale)
    p.finished.connect(p.queue_free)
    var scene_root := get_tree().current_scene
    if scene_root == null:
        return
    scene_root.add_child(p)
    p.play()
