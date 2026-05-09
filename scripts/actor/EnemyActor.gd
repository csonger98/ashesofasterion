class_name EnemyActor
extends CharacterBody3D

@export var max_hp: int = 30
@export var move_speed: float = 2.5
@export var contact_damage: int = 5
@export var attack_cooldown_sec: float = 1.2

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hp_pivot: Node3D = $HpBar/FgPivot

var hp: int
var _player: Node3D
var _last_attack_time: float = -999.0

signal died

func _ready() -> void:
    hp = max_hp
    if _hurtbox != null:
        _hurtbox.damaged.connect(_on_damaged)
    _player = get_tree().get_first_node_in_group("player")
    _refresh_hp_bar()

func _physics_process(_delta: float) -> void:
    if _player == null:
        _player = get_tree().get_first_node_in_group("player")
        return
    var dir := (_player.global_position - global_position)
    dir.y = 0.0
    var dist := dir.length()
    if dist > 1.4:
        velocity.x = dir.normalized().x * move_speed
        velocity.z = dir.normalized().z * move_speed
    else:
        velocity.x = 0.0
        velocity.z = 0.0
        _maybe_attack_player()
    move_and_slide()

func _maybe_attack_player() -> void:
    var now := Time.get_ticks_msec() / 1000.0
    if now - _last_attack_time < attack_cooldown_sec:
        return
    _last_attack_time = now
    var p := _player as Node
    if p != null and p.has_method("receive_attack"):
        p.receive_attack(contact_damage)

func _on_damaged(amount: int) -> void:
    hp -= amount
    _refresh_hp_bar()
    if hp <= 0:
        died.emit()
        queue_free()

func _refresh_hp_bar() -> void:
    if _hp_pivot == null:
        return
    var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
    _hp_pivot.scale.x = ratio
