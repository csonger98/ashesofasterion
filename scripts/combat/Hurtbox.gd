class_name Hurtbox
extends Area3D

signal damaged(amount: int)

@export var owner_actor_path: NodePath

func receive_damage(amount: int) -> void:
    damaged.emit(amount)
