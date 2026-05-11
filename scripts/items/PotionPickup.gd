extends Area3D

@export var lifetime_sec: float = 30.0
@export var bob_height: float = 0.15
@export var bob_speed: float = 2.5
@export var spin_speed: float = 1.5

@onready var _mesh_root: Node3D = $MeshRoot

var _t: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
    _base_y = _mesh_root.position.y
    body_entered.connect(_on_body_entered)
    if lifetime_sec > 0.0:
        await get_tree().create_timer(lifetime_sec).timeout
        if is_instance_valid(self):
            queue_free()

func _process(delta: float) -> void:
    _t += delta
    _mesh_root.position.y = _base_y + sin(_t * bob_speed) * bob_height
    _mesh_root.rotation.y += spin_speed * delta

func _on_body_entered(body: Node) -> void:
    if not body.is_in_group("player"):
        return
    if body.has_method("add_potion"):
        if body.add_potion(1):
            queue_free()
