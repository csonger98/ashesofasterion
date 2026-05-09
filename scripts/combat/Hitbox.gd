class_name Hitbox
extends Area3D

signal hit_landed(target: Node, damage: int, archetype: String)

@export var weapon: Weapon

var _active: bool = false
var _already_hit_this_swing: Array[Node] = []

func _ready() -> void:
    monitoring = false
    monitorable = false
    area_entered.connect(_on_area_entered)

func start_swing() -> void:
    if weapon == null:
        push_warning("Hitbox.start_swing called with no weapon assigned")
        return
    _already_hit_this_swing.clear()
    _active = true
    monitoring = true
    var dur := weapon.attack_duration_sec
    await get_tree().create_timer(dur).timeout
    end_swing()

func end_swing() -> void:
    _active = false
    monitoring = false

func _on_area_entered(area: Area3D) -> void:
    if not _active:
        return
    if not (area is Hurtbox):
        return
    var hb := area as Hurtbox
    var target_actor := hb.get_node_or_null(hb.owner_actor_path)
    if target_actor == null or target_actor in _already_hit_this_swing:
        return
    _already_hit_this_swing.append(target_actor)
    hb.receive_damage(weapon.base_damage)
    hit_landed.emit(target_actor, weapon.base_damage, weapon.archetype)
