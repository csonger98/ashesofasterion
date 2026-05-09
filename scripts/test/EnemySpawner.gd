extends Node3D

@export var enemy_scene: PackedScene
@export var max_concurrent: int = 1
@export var respawn_delay_sec: float = 1.5
@export var spawn_radius_min: float = 2.5
@export var spawn_radius_max: float = 7.0

var _alive: int = 0

func _ready() -> void:
    if enemy_scene == null:
        push_warning("EnemySpawner has no enemy_scene assigned")
        return
    _ensure_population()

func _ensure_population() -> void:
    while _alive < max_concurrent:
        _spawn_one()

func _spawn_one() -> void:
    if enemy_scene == null:
        return
    var enemy := enemy_scene.instantiate()
    if enemy is EnemyActor:
        (enemy as EnemyActor).died.connect(_on_enemy_died)
    if enemy is Node3D:
        var angle := randf() * TAU
        var dist := lerpf(spawn_radius_min, spawn_radius_max, randf())
        (enemy as Node3D).position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
    add_child(enemy)
    _alive += 1

func _on_enemy_died() -> void:
    _alive -= 1
    await get_tree().create_timer(respawn_delay_sec).timeout
    if is_inside_tree():
        _ensure_population()
