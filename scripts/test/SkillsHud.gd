extends CanvasLayer

@onready var _label: Label = $Margin/Label

func _process(_delta: float) -> void:
    var sw: SkillTrack = SkillRegistry.get_track("Sword")
    var dg: SkillTrack = SkillRegistry.get_track("Dodge")
    var sw_xp := 0
    var sw_lvl := 0
    var dg_xp := 0
    var dg_lvl := 0
    if sw != null:
        sw_xp = sw.xp
        sw_lvl = sw.level
    if dg != null:
        dg_xp = dg.xp
        dg_lvl = dg.level
    _label.text = "Sword: L%d (%d xp)\nDodge: L%d (%d xp)" % [sw_lvl, sw_xp, dg_lvl, dg_xp]
