extends Area3D

@export var fill_amount: float = 0.33
@export var lifetime_sec: float = 30.0
@export var bob_height: float = 0.12
@export var bob_speed: float = 3.0
@export var spin_speed: float = 2.0
## Visual scale curve: bigger orbs visually represent bigger fill amounts.
@export var min_visual_scale: float = 0.7
@export var max_visual_scale: float = 1.6

@onready var _mesh_root: Node3D = $MeshRoot

var _t: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
    _base_y = _mesh_root.position.y
    var s := lerpf(min_visual_scale, max_visual_scale, clampf(fill_amount, 0.0, 1.0))
    _mesh_root.scale = Vector3(s, s, s)
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
    if body.has_method("add_potion_recharge"):
        body.add_potion_recharge(fill_amount)
        queue_free()
