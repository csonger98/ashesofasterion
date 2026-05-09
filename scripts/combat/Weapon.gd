class_name Weapon
extends Resource

@export var weapon_name: String = ""
@export var archetype: String = "Sword"  # one of: Sword, Axe, Bow, Pistol, Tome, Forbidden
@export var base_damage: int = 10
@export var attack_duration_sec: float = 0.35  # how long the hitbox stays active per swing
