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
            var n: Node3D = enemy
            var d: float = (n.global_position - global_position).length()
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
    var local := Vector3(x, 0.0, z)
    if local.length_squared() > 1.0:
        local = local.normalized()
    # Player-relative movement: W moves forward (the way the player faces),
    # D strafes right, etc. transform.basis carries the player's current Y rotation
    # (set by look_at in _update_aim each frame), so we rotate local input into world.
    return transform.basis * local

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
