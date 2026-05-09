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
