class_name SkillTrack
extends Resource

@export var skill_name: String = ""
@export var xp: int = 0
@export var level: int = 0
@export var max_level: int = 100

signal leveled_up(new_level: int)

const _XP_COEFFICIENT := 50

func xp_for_level(n: int) -> int:
    return _XP_COEFFICIENT * n * n

func _level_for_xp(total_xp: int) -> int:
    var n := 0
    while n < max_level and total_xp >= xp_for_level(n + 1):
        n += 1
    return n

func add_xp(amount: int) -> void:
    if amount <= 0 or level >= max_level:
        return
    var prev_level := level
    xp += amount
    var new_level := _level_for_xp(xp)
    if new_level > max_level:
        new_level = max_level
    if new_level > prev_level:
        for lvl in range(prev_level + 1, new_level + 1):
            level = lvl
            leveled_up.emit(lvl)
    if level >= max_level:
        # Cap XP so it doesn't grow unboundedly past cap.
        xp = xp_for_level(max_level)

var tier: int:
    get:
        return clampi(level / 10, 0, 10)

var amplifier: float:
    get:
        return float(level) * 0.01
