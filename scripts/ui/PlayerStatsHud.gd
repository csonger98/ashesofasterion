extends CanvasLayer

@export var player_path: NodePath

@onready var _hp_bar: ProgressBar = $Margin/VBox/HpRow/Bar
@onready var _hp_label: Label = $Margin/VBox/HpRow/Label
@onready var _stamina_bar: ProgressBar = $Margin/VBox/StaminaRow/Bar
@onready var _stamina_label: Label = $Margin/VBox/StaminaRow/Label
@onready var _mana_bar: ProgressBar = $Margin/VBox/ManaRow/Bar
@onready var _mana_label: Label = $Margin/VBox/ManaRow/Label
@onready var _corruption_bar: ProgressBar = $Margin/VBox/CorruptionRow/Bar
@onready var _corruption_label: Label = $Margin/VBox/CorruptionRow/Label
@onready var _potion_row: Control = $Margin/VBox/PotionRow

var _player: PlayerActor
var _potion_slot_bars: Array[ProgressBar] = []
var _potion_label: Label

func _ready() -> void:
    _resolve_player()
    if _player != null:
        _build_potion_slots()
        _player.stats_changed.connect(_refresh)
        _refresh()

func _resolve_player() -> void:
    if not player_path.is_empty():
        var n := get_node_or_null(player_path)
        if n is PlayerActor:
            _player = n
            return
    var found := get_tree().get_first_node_in_group("player")
    if found is PlayerActor:
        _player = found

func _build_potion_slots() -> void:
    # Strip out the placeholder Bar/Label that sit in the .tscn for layout reference.
    for c in _potion_row.get_children():
        c.queue_free()
    var hbox := HBoxContainer.new()
    hbox.anchor_right = 1.0
    hbox.anchor_bottom = 1.0
    hbox.add_theme_constant_override("separation", 4)
    _potion_row.add_child(hbox)
    _potion_label = Label.new()
    _potion_label.text = "[Q]"
    _potion_label.add_theme_font_size_override("font_size", 16)
    _potion_label.add_theme_color_override("font_color", Color(1, 0.78, 0.5))
    _potion_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
    _potion_label.add_theme_constant_override("shadow_offset_x", 1)
    _potion_label.add_theme_constant_override("shadow_offset_y", 1)
    _potion_label.custom_minimum_size = Vector2(48, 0)
    _potion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hbox.add_child(_potion_label)
    _potion_slot_bars.clear()
    var fill_style := _make_styled_box(Color(0.95, 0.55, 0.18))
    var locked_fill := _make_styled_box(Color(0.3, 0.2, 0.1))
    var bg_style := _make_styled_box(Color(0.1, 0.1, 0.12, 0.85))
    for i in _player.max_potion_slots:
        var bar := ProgressBar.new()
        bar.max_value = 1.0
        bar.step = 0.001
        bar.show_percentage = false
        bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
        bar.custom_minimum_size = Vector2(0, 32)
        bar.add_theme_stylebox_override("fill", fill_style)
        bar.add_theme_stylebox_override("background", bg_style)
        bar.set_meta("locked_fill", locked_fill)
        bar.set_meta("unlocked_fill", fill_style)
        hbox.add_child(bar)
        _potion_slot_bars.append(bar)

func _make_styled_box(color: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.corner_radius_top_left = 3
    s.corner_radius_top_right = 3
    s.corner_radius_bottom_right = 3
    s.corner_radius_bottom_left = 3
    return s

func _process(_delta: float) -> void:
    if _player != null:
        _refresh_potion_slots()

func _refresh() -> void:
    if _player == null:
        return
    _set_bar(_hp_bar, _hp_label, "HP", _player.hp, _player.max_hp)
    _set_bar(_stamina_bar, _stamina_label, "Stamina", _player.stamina, _player.max_stamina)
    _set_bar(_mana_bar, _mana_label, "Mana", _player.mana, _player.max_mana)
    _set_bar(_corruption_bar, _corruption_label, "Corruption", _player.corruption, _player.max_corruption)
    _refresh_potion_slots()

func _refresh_potion_slots() -> void:
    if _potion_slot_bars.is_empty():
        return
    var unlocked := _player.unlocked_potion_slots
    var charge := _player.potion_charge
    for i in _potion_slot_bars.size():
        var bar: ProgressBar = _potion_slot_bars[i]
        if i >= unlocked:
            # Locked slot: dim, empty, distinct color so the player can tell it's unlockable.
            bar.value = 1.0
            bar.add_theme_stylebox_override("fill", bar.get_meta("locked_fill"))
            bar.modulate = Color(1, 1, 1, 0.35)
        else:
            bar.add_theme_stylebox_override("fill", bar.get_meta("unlocked_fill"))
            bar.modulate = Color(1, 1, 1, 1.0)
            bar.value = clampf(charge - float(i), 0.0, 1.0)
    _potion_label.text = "[Q] %d/%d" % [_player.potion_count, unlocked]

func _set_bar(bar: ProgressBar, label: Label, label_text: String, value: float, max_value: float) -> void:
    bar.max_value = max_value
    bar.value = value
    label.text = "%s  %d / %d" % [label_text, int(round(value)), int(round(max_value))]
