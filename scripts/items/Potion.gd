class_name Potion
extends Resource

@export var display_name: String = ""
@export_range(1, 10) var tier: int = 1
@export var restore_hp: int = 0
@export var restore_stamina: float = 0.0
@export var restore_mana: float = 0.0
@export var remove_corruption: float = 0.0
@export var icon_color: Color = Color(0.85, 0.18, 0.18)
