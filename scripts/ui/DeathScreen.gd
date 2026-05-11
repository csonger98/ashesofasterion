extends CanvasLayer

@export var player_path: NodePath

@onready var _root: Control = $Root
@onready var _restart_button: Button = $Root/Center/VBox/Restart

var _player: PlayerActor

func _ready() -> void:
    _root.visible = false
    _resolve_player()
    if _player != null:
        _player.died.connect(_on_player_died)
    _restart_button.pressed.connect(_on_restart_pressed)

func _resolve_player() -> void:
    if not player_path.is_empty():
        var n := get_node_or_null(player_path)
        if n is PlayerActor:
            _player = n
            return
    var found := get_tree().get_first_node_in_group("player")
    if found is PlayerActor:
        _player = found

func _on_player_died() -> void:
    _root.visible = true
    _restart_button.grab_focus()
    get_tree().paused = true

func _on_restart_pressed() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
    if not _root.visible:
        return
    if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
        _on_restart_pressed()
