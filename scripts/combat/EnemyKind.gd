class_name EnemyKind
extends Resource

@export var display_name: String = ""
@export var max_hp: int = 30
@export var move_speed: float = 2.5
@export var contact_damage: int = 5
@export var attack_cooldown_sec: float = 1.2
@export var mesh_color: Color = Color(0.667, 0.2, 0.2)

@export_group("Drops")
## Fraction of the potion recharge bar this enemy's orb fills (0.0 - 1.0+).
## Tier hint: grunt 0.33, elite 0.67, mini-boss 1.0+
@export var health_orb_fill_amount: float = 0.33
@export_range(0.0, 1.0) var health_orb_drop_chance: float = 1.0
