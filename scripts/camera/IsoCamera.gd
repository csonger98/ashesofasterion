class_name IsoCamera
extends Camera3D

@export var target_path: NodePath
@export var follow_speed: float = 8.0
@export var offset: Vector3 = Vector3(10.0, 10.0, 10.0)

var _target: Node3D

func _ready() -> void:
    # top_level decouples this camera from the parent's transform; the parent's
    # rotation (e.g. PlayerActor's look_at-based aim) would otherwise spin the
    # iso view around. We position via global_position in _process anyway.
    top_level = true
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
