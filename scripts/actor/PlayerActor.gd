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

func receive_attack(damage: int) -> void:
    # Plan 1 placeholder: just log. HP system + i-frames arrive in later plans.
    print("Player took %d damage" % damage)

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
        # Rotate the player so its forward (-Z) points at the cursor.
        # look_at handles the sign convention; we zero pitch/roll to keep iso flat.
        look_at(aim_world_point, Vector3.UP)
        rotation.x = 0.0
        rotation.z = 0.0
