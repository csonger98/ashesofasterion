class_name EnemyActor
extends CharacterBody3D

@export var kind: Resource  # EnemyKind
@export var max_hp: int = 30
@export var move_speed: float = 2.5
@export var contact_damage: int = 5
@export var attack_cooldown_sec: float = 1.2

@export_group("Feedback")
@export var hit_flash_duration_sec: float = 0.18
@export var knockback_speed: float = 3.5
@export var knockback_decay: float = 12.0

@export_group("Drops")
@export var health_orb_scene: PackedScene

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hp_fg: MeshInstance3D = $HpBar/Fg
@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _mesh: MeshInstance3D = $Mesh

var hp: int
var _player: Node3D
var _last_attack_time: float = -999.0
var _mat: StandardMaterial3D
var _base_color: Color = Color.WHITE
var _flash_tween: Tween
var _knockback_velocity: Vector3 = Vector3.ZERO

signal died

func _ready() -> void:
    if kind != null:
        max_hp = kind.max_hp
        move_speed = kind.move_speed
        contact_damage = kind.contact_damage
        attack_cooldown_sec = kind.attack_cooldown_sec
    hp = max_hp
    if _hurtbox != null:
        _hurtbox.damaged.connect(_on_damaged)
    if _mesh != null and _mesh.material_override is StandardMaterial3D:
        _mat = (_mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
        _mesh.material_override = _mat
        if kind != null:
            _mat.albedo_color = kind.mesh_color
        _base_color = _mat.albedo_color
    _player = get_tree().get_first_node_in_group("player")
    if _nav_agent != null and _nav_agent.avoidance_enabled:
        _nav_agent.velocity_computed.connect(_on_velocity_computed)
    _refresh_hp_bar()

func _physics_process(delta: float) -> void:
    if _player == null:
        _player = get_tree().get_first_node_in_group("player")
        return
    _nav_agent.target_position = _player.global_position

    var to_player := _player.global_position - global_position
    to_player.y = 0.0
    var dist_to_player := to_player.length()

    var desired := Vector3.ZERO
    if dist_to_player <= _nav_agent.target_desired_distance:
        _maybe_attack_player()
    else:
        var next_pos := _nav_agent.get_next_path_position()
        var dir := next_pos - global_position
        dir.y = 0.0
        if dir.length_squared() > 0.0001:
            dir = dir.normalized()
        else:
            # Path not loaded yet (or stale) — walk straight at player as fallback.
            dir = to_player / dist_to_player
        desired.x = dir.x * move_speed
        desired.z = dir.z * move_speed

    if _knockback_velocity.length_squared() > 0.0001:
        _knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)

    if _nav_agent.avoidance_enabled:
        # Feed desired velocity to avoidance; final velocity arrives via signal.
        _nav_agent.velocity = desired
    else:
        velocity.x = desired.x + _knockback_velocity.x
        velocity.z = desired.z + _knockback_velocity.z
        move_and_slide()
        _face_player()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
    velocity.x = safe_velocity.x + _knockback_velocity.x
    velocity.z = safe_velocity.z + _knockback_velocity.z
    move_and_slide()
    _face_player()

func _face_player() -> void:
    if _player == null:
        return
    var to_player := _player.global_position - global_position
    to_player.y = 0.0
    if to_player.length_squared() < 0.001:
        return
    look_at(global_position + to_player, Vector3.UP)
    rotation.x = 0.0
    rotation.z = 0.0

func _maybe_attack_player() -> void:
    var now := Time.get_ticks_msec() / 1000.0
    if now - _last_attack_time < attack_cooldown_sec:
        return
    _last_attack_time = now
    var p := _player as Node
    if p != null and p.has_method("receive_attack"):
        p.receive_attack(contact_damage)
        _play_sfx("enemy_attack")

func _play_sfx(key: String) -> void:
    var s := get_tree().root.get_node_or_null("Sfx")
    if s != null:
        s.call("play_at", key, global_position)

func _on_damaged(amount: int) -> void:
    hp -= amount
    _refresh_hp_bar()
    _flash_hit()
    _apply_knockback_from_player()
    _play_sfx("hit")
    if hp <= 0:
        _play_sfx("enemy_die")
        _maybe_drop_health_orb()
        died.emit()
        queue_free()

func _maybe_drop_health_orb() -> void:
    if health_orb_scene == null:
        return
    var fill := 0.33
    var drop_chance := 1.0
    if kind != null:
        fill = kind.health_orb_fill_amount
        drop_chance = kind.health_orb_drop_chance
    if randf() > drop_chance:
        return
    var orb := health_orb_scene.instantiate() as Node3D
    if orb == null:
        return
    var scene_root := get_tree().current_scene
    if scene_root == null:
        return
    scene_root.add_child(orb)
    orb.global_position = Vector3(global_position.x, 0.0, global_position.z)
    if "fill_amount" in orb:
        orb.set("fill_amount", fill)

func _flash_hit() -> void:
    if _mat == null:
        return
    if _flash_tween != null and _flash_tween.is_valid():
        _flash_tween.kill()
    _mat.albedo_color = Color.WHITE
    _flash_tween = create_tween()
    _flash_tween.tween_property(_mat, "albedo_color", _base_color, hit_flash_duration_sec)

func _apply_knockback_from_player() -> void:
    if _player == null:
        return
    var away := global_position - _player.global_position
    away.y = 0.0
    if away.length_squared() < 0.0001:
        away = Vector3.FORWARD
    _knockback_velocity = away.normalized() * knockback_speed

func _refresh_hp_bar() -> void:
    if _hp_fg == null:
        return
    var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
    _hp_fg.scale.x = ratio
