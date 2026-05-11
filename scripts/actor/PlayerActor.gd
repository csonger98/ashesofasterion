class_name PlayerActor
extends CharacterBody3D

@export var move_speed: float = 6.0
@export var acceleration: float = 30.0
@export var deceleration: float = 35.0

@export var dodge_speed: float = 7.0
@export var dodge_duration_sec: float = 0.7
@export var dodge_iframe_duration_sec: float = 0.55
## How much faster than natural to play the Roll animation. 1.0 = natural.
## dodge_duration_sec gets auto-set to roll_length / this on character load.
@export var dodge_anim_speed_factor: float = 1.25
@export var dodge_cooldown_sec: float = 0.5
@export var dodge_proximity_radius: float = 2.5
@export var dodge_xp_reward: int = 8

@export_group("Resources")
@export var max_hp: int = 100
@export var max_stamina: float = 100.0
@export var max_mana: float = 100.0
@export var max_corruption: float = 100.0
@export var stamina_dodge_cost: float = 25.0
@export var stamina_attack_cost: float = 10.0
@export var stamina_regen_per_sec: float = 20.0
@export var mana_regen_per_sec: float = 5.0

@export_group("Potions")
@export_range(1, 5) var max_potion_slots: int = 5
@export_range(0, 5) var starting_potion_slots: int = 2
@export var potion_recharge_sec: float = 15.0
@export var default_potion: Resource  # Potion

@onready var _hitbox: Hitbox = $Hitbox
@onready var _aim_indicator: Node3D = $Mesh/AimIndicator
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _character_root: Node3D = get_node_or_null("Character")
@onready var _swing_trail: Node = get_node_or_null("SwingTrail")

@export_group("Character Model")
@export var character_glb_path: String = "res://art/characters/CesiumMan.glb"
## Rotate the loaded model around Y to face -Z (Godot forward). 180 for glTF defaults.
@export var character_y_rotation_deg: float = 180.0
@export var character_scale: float = 1.6
@export var sword_bone_name: String = "hand_r"
@export var sword_grip_offset: Vector3 = Vector3(0.0, 0.04, 0.0)
@export var sword_grip_rotation_deg: Vector3 = Vector3(-90.0, 90.0, 0.0)

enum AnimState { LOCOMOTION, ATTACK, DODGE, HURT, DEATH }

var _anim_player: AnimationPlayer
var _anim_state: int = AnimState.LOCOMOTION
var _idle_animation: StringName = &""
var _move_animation: StringName = &""
var _attack_animations: Array[StringName] = []
var _dodge_animation: StringName = &""
var _hurt_animation: StringName = &""
var _death_animation: StringName = &""
var _swing_index: int = 0

var aim_direction: Vector3 = Vector3.FORWARD
var aim_world_point: Vector3 = Vector3.ZERO

var hp: int
var stamina: float
var mana: float
var corruption: float

# Continuous potion supply: integer part = visible charge count,
# fractional part = progress toward the next charge.
var potion_charge: float = 0.0

# Active slot capacity. Starts at starting_potion_slots and can grow via
# unlock_potion_slot() up to max_potion_slots (progression).
var unlocked_potion_slots: int = 0

var potion_count: int:
    get:
        return int(floorf(potion_charge))

var _is_dodging: bool = false
var _is_iframe: bool = false
var _is_attacking: bool = false
var _last_dodge_end_time: float = -999.0
var _swing_tween: Tween = null

signal stats_changed
signal died

func _ready() -> void:
    hp = max_hp
    stamina = max_stamina
    mana = max_mana
    corruption = 0.0
    unlocked_potion_slots = clampi(starting_potion_slots, 0, max_potion_slots)
    potion_charge = float(unlocked_potion_slots)
    if _hitbox != null:
        _hitbox.hit_landed.connect(_on_hit_landed)
    _load_character_model()
    stats_changed.emit()

func _load_character_model() -> void:
    if _character_root == null:
        return
    if not ResourceLoader.exists(character_glb_path):
        # GLB not yet imported by the Godot editor. Capsule stays visible as a fallback.
        push_warning("Player character GLB not found at %s. Open Godot once to import it." % character_glb_path)
        return
    var scene := load(character_glb_path) as PackedScene
    if scene == null:
        return
    var instance := scene.instantiate() as Node3D
    if instance == null:
        return
    instance.rotation.y = deg_to_rad(character_y_rotation_deg)
    instance.scale = Vector3.ONE * character_scale
    _character_root.add_child(instance)
    # Hide the placeholder capsule but keep its children (AimIndicator + sword) drawing.
    if _mesh != null:
        _mesh.mesh = null
    # Pick up the AnimationPlayer if the model has one; play first animation as idle/move loop.
    _anim_player = instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
    if _anim_player != null:
        _setup_animations()
        _anim_player.animation_finished.connect(_on_animation_finished)
    _attach_sword_to_hand(instance)

func _attach_sword_to_hand(character_root: Node) -> void:
    if _aim_indicator == null:
        return
    # Find any Skeleton3D in the rig regardless of node name (varies per asset pack).
    var skel: Skeleton3D = null
    var matches := character_root.find_children("*", "Skeleton3D", true, false)
    if matches.size() > 0:
        skel = matches[0] as Skeleton3D
    if skel == null:
        push_warning("Player: Skeleton3D not found in character — sword stays floating.")
        return
    var bone_idx := skel.find_bone(sword_bone_name)
    if bone_idx < 0:
        # Print all bone names to help diagnose if user has the wrong sword_bone_name.
        var names: Array = []
        for i in skel.get_bone_count():
            names.append(skel.get_bone_name(i))
        push_warning("Player: bone '%s' not found. Available bones: %s" % [sword_bone_name, names])
        return
    print("[Sword] attaching to bone '%s' (idx=%d) on skeleton '%s'" % [sword_bone_name, bone_idx, skel.name])
    var rest := skel.get_bone_rest(bone_idx)
    print("[Sword] bone rest basis: x=%s y=%s z=%s origin=%s" % [rest.basis.x, rest.basis.y, rest.basis.z, rest.origin])
    var attach := BoneAttachment3D.new()
    attach.name = "SwordAttach"
    attach.bone_name = sword_bone_name
    attach.bone_idx = bone_idx
    skel.add_child(attach)
    # SwordRig holds the grip orientation (how the sword sits in the hand).
    # Its rotation is set once and never changed.
    var rig := Node3D.new()
    rig.name = "SwordRig"
    rig.position = sword_grip_offset
    rig.rotation = Vector3(
        deg_to_rad(sword_grip_rotation_deg.x),
        deg_to_rad(sword_grip_rotation_deg.y),
        deg_to_rad(sword_grip_rotation_deg.z))
    attach.add_child(rig)
    # SwingNode is the swing-tween pivot — starts at identity rotation, gets
    # rotated by the swing tween, returns to identity after each swing. This
    # decouples swing motion from grip orientation so successive swings don't
    # drift the sword's resting pose.
    var swing_node := Node3D.new()
    swing_node.name = "SwingNode"
    rig.add_child(swing_node)
    # Reparent existing sword children — preserves their local transforms so
    # the blade-tip-relative-to-grip layout stays intact.
    for piece_name in ["Blade", "BladeTip", "BladeBase", "Crossguard", "Grip", "Pommel"]:
        var piece := _aim_indicator.get_node_or_null(piece_name)
        if piece != null:
            var local_xform := (piece as Node3D).transform
            _aim_indicator.remove_child(piece)
            swing_node.add_child(piece)
            (piece as Node3D).transform = local_xform
    # Repoint _aim_indicator at SwingNode so swing tweens only affect swing.
    _aim_indicator = swing_node

func _setup_animations() -> void:
    var anims := _anim_player.get_animation_list()
    if anims.is_empty():
        return
    _idle_animation = &""
    _move_animation = &""
    # Movement preference order: sprint > run > jog > walk.
    var move_priority := -1
    for a in anims:
        var n := String(a).to_lower()
        if "backwards" in n or "strafe" in n:
            continue
        # Idle — first plain "idle" wins; skip flavor variants.
        if ("idle" in n) and not ("crouch" in n or "torch" in n or "talking" in n or "attack" in n or "hit" in n or "sit" in n or "swim" in n or "spell" in n or "pistol" in n or "sword" in n) and _idle_animation == &"":
            _idle_animation = a
        elif "sprint" in n and move_priority < 4:
            _move_animation = a; move_priority = 4
        elif "run" in n and move_priority < 3:
            _move_animation = a; move_priority = 3
        elif "jog" in n and move_priority < 2:
            _move_animation = a; move_priority = 2
        elif ("walk" in n or "move" in n) and move_priority < 1:
            _move_animation = a; move_priority = 1
    # Fallback if nothing matched
    if _idle_animation == &"":
        _idle_animation = anims[0]
    if _move_animation == &"":
        _move_animation = anims[0]
    # Attack variants — sword-only, no punches, no root-motion versions.
    var attack_keywords := ["sword_attack", "slice_horizontal", "slice_diagonal", "chop", "stab", "1h_melee"]
    for keyword in attack_keywords:
        for a in anims:
            var an := String(a).to_lower()
            if keyword in an and not "_rm" in an and not _attack_animations.has(a):
                _attack_animations.append(a)
        if _attack_animations.size() >= 3:
            break
    # Dodge / roll. Prefer plain "Roll" over "Roll_RM" (RM = root motion, can drift).
    for a in anims:
        var n := String(a).to_lower()
        if (n == "roll" or n == "dodge") or (("dodge" in n or "roll" in n) and not "_rm" in n):
            _dodge_animation = a
            break
    # Hurt.
    for a in anims:
        var n := String(a).to_lower()
        if n.begins_with("hit") or "hurt" in n or "damage" in n:
            _hurt_animation = a
            break
    # Death.
    for a in anims:
        var n := String(a).to_lower()
        if "death" in n or "dying" in n or n.begins_with("die"):
            _death_animation = a
            break
    _force_loop(_idle_animation)
    _force_loop(_move_animation)
    # Sync gameplay dodge_duration to play Roll at exactly dodge_anim_speed_factor.
    if _dodge_animation != &"" and _anim_player.has_animation(_dodge_animation):
        var roll_anim := _anim_player.get_animation(_dodge_animation)
        if roll_anim != null and roll_anim.length > 0.0 and dodge_anim_speed_factor > 0.0:
            dodge_duration_sec = roll_anim.length / dodge_anim_speed_factor
            dodge_iframe_duration_sec = dodge_duration_sec * 0.8
    print("[PlayerAnim] idle=%s, move=%s, attacks=%s, dodge=%s (gameplay %.2fs at %.2fx), hurt=%s, death=%s" % [
        _idle_animation, _move_animation, _attack_animations,
        _dodge_animation, dodge_duration_sec, dodge_anim_speed_factor,
        _hurt_animation, _death_animation
    ])

func _force_loop(anim_name: StringName) -> void:
    if _anim_player == null or anim_name == &"":
        return
    if not _anim_player.has_animation(anim_name):
        return
    var a := _anim_player.get_animation(anim_name)
    if a != null:
        a.loop_mode = Animation.LOOP_LINEAR

func _play_one_shot(state: int, anim_name: StringName) -> bool:
    if _anim_player == null or anim_name == &"":
        return false
    if not _anim_player.has_animation(anim_name):
        return false
    _anim_state = state
    # play(blend=0) snaps instantly without a T-pose gap; seek(0,true) guarantees
    # we restart from frame 0 even if the same anim was already playing.
    _anim_player.play(anim_name, 0.0)
    _anim_player.seek(0.0, true)
    return true

func _on_animation_finished(_anim_name: StringName) -> void:
    if _anim_state == AnimState.DEATH:
        return
    _anim_state = AnimState.LOCOMOTION
    # Drive locomotion immediately so there's no one-frame gap where the rig
    # holds the last pose of the just-finished one-shot (dodge/hurt/etc).
    if _anim_player == null:
        return
    var moving := velocity.length_squared() > 0.5
    var target_anim: StringName = _move_animation if moving else _idle_animation
    if target_anim != &"":
        _anim_player.play(target_anim, 0.12)

func _physics_process(delta: float) -> void:
    _regen_resources(delta)
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
    _update_anim()

func _update_anim() -> void:
    if _anim_player == null:
        return
    if _anim_state != AnimState.LOCOMOTION:
        return
    var moving := velocity.length_squared() > 0.5
    var target_anim: StringName = _move_animation if moving else _idle_animation
    if target_anim == &"":
        return
    if _anim_player.current_animation != String(target_anim):
        _anim_player.play(target_anim, 0.12)

func _regen_resources(delta: float) -> void:
    var changed := false
    if stamina < max_stamina:
        stamina = minf(stamina + stamina_regen_per_sec * delta, max_stamina)
        changed = true
    if mana < max_mana:
        mana = minf(mana + mana_regen_per_sec * delta, max_mana)
        changed = true
    if potion_charge < float(unlocked_potion_slots) and potion_recharge_sec > 0.0:
        var prev := potion_charge
        potion_charge = minf(potion_charge + delta / potion_recharge_sec, float(unlocked_potion_slots))
        if potion_charge != prev:
            changed = true
    if changed:
        stats_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack_light"):
        _swing_light()
    elif event.is_action_pressed("dodge"):
        _try_dodge()
    elif event.is_action_pressed("use_potion"):
        _use_potion()

## Drinks the potion, healing only what's missing (no overflow waste).
## Charge cost is proportional to actual healing done — a 10-HP heal from a
## 40-HP potion costs 0.25 of a charge, leaving 0.75 in the bar.
func _use_potion() -> void:
    if potion_count <= 0:
        return
    if default_potion == null:
        return
    var p := default_potion
    var missing_hp := max_hp - hp
    if missing_hp <= 0 and p.restore_stamina <= 0.0 and p.restore_mana <= 0.0 and p.remove_corruption <= 0.0:
        # Nothing to heal — don't waste a charge.
        return
    var max_heal: int = p.restore_hp
    var heal_amount: int = mini(missing_hp, max_heal) if missing_hp > 0 else 0
    if heal_amount > 0:
        hp += heal_amount
    var charge_used := 0.0
    if max_heal > 0:
        charge_used = float(heal_amount) / float(max_heal)
    else:
        charge_used = 1.0  # potion has no HP component — fall back to full charge
    # Side effects always at full strength when triggered.
    if p.restore_stamina > 0.0:
        stamina = minf(stamina + p.restore_stamina, max_stamina)
    if p.restore_mana > 0.0:
        mana = minf(mana + p.restore_mana, max_mana)
    if p.remove_corruption > 0.0:
        corruption = maxf(corruption - p.remove_corruption, 0.0)
    potion_charge = maxf(potion_charge - charge_used, 0.0)
    stats_changed.emit()

func add_potion(amount: int = 1) -> bool:
    if potion_charge >= float(unlocked_potion_slots):
        return false
    potion_charge = minf(potion_charge + float(amount), float(unlocked_potion_slots))
    stats_changed.emit()
    return true

func get_potion_recharge_remaining() -> float:
    var fract := potion_charge - floorf(potion_charge)
    if fract == 0.0 and potion_charge >= float(unlocked_potion_slots):
        return 0.0
    if potion_recharge_sec <= 0.0:
        return 0.0
    return maxf(potion_recharge_sec * (1.0 - fract), 0.0)

func get_potion_recharge_fraction() -> float:
    if potion_charge >= float(unlocked_potion_slots):
        return 1.0
    return potion_charge - floorf(potion_charge)

## Pours fraction-of-a-charge into the potion supply.
## Overflow rolls up: 1.4 fill on 0.5 charge = 1.9 total = 1 visible charge with 0.9 in the bar.
func add_potion_recharge(fraction: float) -> void:
    if potion_charge >= float(unlocked_potion_slots):
        return
    potion_charge = minf(potion_charge + fraction, float(unlocked_potion_slots))
    stats_changed.emit()

## Unlock an additional potion slot (progression). Capped at max_potion_slots.
## Returns true if a slot was actually unlocked.
func unlock_potion_slot() -> bool:
    if unlocked_potion_slots >= max_potion_slots:
        return false
    unlocked_potion_slots += 1
    stats_changed.emit()
    return true

func _swing_light() -> void:
    if _hitbox == null:
        return
    if stamina < stamina_attack_cost:
        return
    # No-cancel: a swing must follow through before another can start.
    if _is_attacking:
        return
    _is_attacking = true
    stamina = maxf(stamina - stamina_attack_cost, 0.0)
    stats_changed.emit()
    _hitbox.start_swing()
    _animate_swing()
    _play_sfx("swing")

func _play_dodge_animation_scaled() -> void:
    if _anim_player == null or _dodge_animation == &"":
        return
    if not _anim_player.has_animation(_dodge_animation):
        return
    var anim := _anim_player.get_animation(_dodge_animation)
    if anim == null:
        return
    var anim_length: float = anim.length
    var play_speed: float = 1.0
    if dodge_duration_sec > 0.0 and anim_length > 0.0:
        play_speed = anim_length / dodge_duration_sec
    _anim_state = AnimState.DODGE
    _anim_player.play(_dodge_animation, 0.0, play_speed)
    _anim_player.seek(0.0, true)

func _play_attack_animation(variant: int) -> void:
    if _attack_animations.is_empty() or _anim_player == null:
        return
    var anim := _attack_animations[variant % _attack_animations.size()]
    if not _anim_player.has_animation(anim):
        return
    var speeds := [1.05, 0.92, 1.18]
    var speed: float = speeds[variant % speeds.size()]
    _anim_state = AnimState.ATTACK
    _anim_player.play(anim, 0.0, speed)
    _anim_player.seek(0.0, true)

func _play_sfx(key: String) -> void:
    var s := get_tree().root.get_node_or_null("Sfx")
    if s != null:
        s.call("play_at", key, global_position)

func _animate_swing() -> void:
    if _aim_indicator == null:
        return
    if _swing_tween != null and _swing_tween.is_valid():
        _swing_tween.kill()
    # Reset all rotation axes so a previous variant doesn't leak into this one.
    _aim_indicator.rotation = Vector3.ZERO
    if _swing_trail != null:
        _swing_trail.call("start")
    var variant := _swing_index % 3
    _swing_index += 1
    match variant:
        0:
            # Right-to-left horizontal slash.
            _swing_tween = create_tween()
            _swing_tween.tween_property(_aim_indicator, "rotation:y", deg_to_rad(-65.0), 0.10) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            _swing_tween.tween_property(_aim_indicator, "rotation:y", deg_to_rad(70.0), 0.18) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            _swing_tween.tween_property(_aim_indicator, "rotation:y", 0.0, 0.07)
        1:
            # Left-to-right horizontal slash (mirror, slightly faster).
            _swing_tween = create_tween()
            _swing_tween.tween_property(_aim_indicator, "rotation:y", deg_to_rad(65.0), 0.09) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            _swing_tween.tween_property(_aim_indicator, "rotation:y", deg_to_rad(-70.0), 0.16) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            _swing_tween.tween_property(_aim_indicator, "rotation:y", 0.0, 0.07)
        _:
            # Overhead chop — windup raises blade up-and-back, then strikes downward.
            _swing_tween = create_tween()
            _swing_tween.parallel().tween_property(_aim_indicator, "rotation:x", deg_to_rad(-55.0), 0.12) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            _swing_tween.parallel().tween_property(_aim_indicator, "rotation:y", deg_to_rad(-15.0), 0.12)
            _swing_tween.tween_property(_aim_indicator, "rotation:x", deg_to_rad(55.0), 0.16) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            _swing_tween.tween_property(_aim_indicator, "rotation", Vector3.ZERO, 0.07)
    _swing_tween.tween_callback(_on_swing_done)

func _on_swing_done() -> void:
    _is_attacking = false
    if _swing_trail != null:
        _swing_trail.call("stop")

func _try_dodge() -> void:
    var now := Time.get_ticks_msec() / 1000.0
    if _is_dodging or (now - _last_dodge_end_time) < dodge_cooldown_sec:
        return
    if stamina < stamina_dodge_cost:
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
    stamina = maxf(stamina - stamina_dodge_cost, 0.0)
    stats_changed.emit()
    _play_sfx("dodge")
    _play_dodge_animation_scaled()
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
    hp = max(hp - damage, 0)
    stats_changed.emit()
    _shake_camera(0.15)
    _play_sfx("player_hurt")
    if hp == 0:
        _play_sfx("player_die")
        _play_one_shot(AnimState.DEATH, _death_animation)
        died.emit()
    else:
        _play_one_shot(AnimState.HURT, _hurt_animation)

func _on_hit_landed(_target: Node, damage: int, archetype: String) -> void:
    SkillRegistry.award_xp(archetype, damage)
    _shake_camera(0.06)

func _shake_camera(amount: float) -> void:
    var cam := get_viewport().get_camera_3d()
    if cam is IsoCamera:
        (cam as IsoCamera).add_shake(amount)

func _read_movement_input() -> Vector3:
    var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var z := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    var local := Vector3(x, 0.0, z)
    if local.length_squared() > 1.0:
        local = local.normalized()
    # Camera-relative WASD: W = up-on-screen, D = right-on-screen, etc.
    var cam := get_viewport().get_camera_3d()
    if cam == null:
        return local
    var cam_right := cam.global_transform.basis.x
    cam_right.y = 0.0
    cam_right = cam_right.normalized()
    var cam_back := cam.global_transform.basis.z
    cam_back.y = 0.0
    cam_back = cam_back.normalized()
    return cam_right * local.x + cam_back * local.z

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
    # Body faces movement direction when moving; otherwise faces the cursor.
    var face_target: Vector3 = Vector3.ZERO
    var planar_vel := Vector3(velocity.x, 0.0, velocity.z)
    if planar_vel.length_squared() > 0.5:
        face_target = global_position + planar_vel
    elif to_aim.length_squared() > 0.001:
        face_target = aim_world_point
    else:
        return
    look_at(face_target, Vector3.UP)
    rotation.x = 0.0
    rotation.z = 0.0
