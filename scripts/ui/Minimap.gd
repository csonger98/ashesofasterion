extends Control

@export var world_size: float = 200.0
@export var displayed_radius: float = 60.0
@export var vision_radius: float = 25.0
@export var fog_update_interval_sec: float = 0.1
@export var background_color: Color = Color(0.04, 0.04, 0.06, 0.9)
@export var border_color: Color = Color(0.5, 0.5, 0.55, 1.0)
@export var explored_tint: Color = Color(0.18, 0.18, 0.22, 1.0)
@export var vision_tint: Color = Color(0.32, 0.32, 0.38, 0.4)
@export var player_color: Color = Color(0.2, 0.85, 1.0)
@export var enemy_color: Color = Color(0.95, 0.25, 0.25)
@export var rock_color: Color = Color(0.5, 0.48, 0.42)
@export var entity_dot_radius: float = 3.0
@export var rock_dot_radius: float = 1.5

const FOG_PADDING_PX: int = 80

var _player: Node3D
var _explored: Image
var _explored_tex: ImageTexture
var _fog_timer: float = 0.0
var _fog_size: int = 0

func _ready() -> void:
    clip_contents = true
    # Fog image is the world size plus a black padding ring on every side, so the
    # displayed region around a player at the world edge always samples valid
    # texels (padding stays black = unexplored).
    _fog_size = int(world_size) + 2 * FOG_PADDING_PX
    _explored = Image.create(_fog_size, _fog_size, false, Image.FORMAT_L8)
    _explored.fill(Color(0, 0, 0, 1))
    _explored_tex = ImageTexture.create_from_image(_explored)
    _try_resolve_player()

func _process(delta: float) -> void:
    if _player == null:
        _try_resolve_player()
        if _player == null:
            return
    _fog_timer += delta
    if _fog_timer >= fog_update_interval_sec:
        _fog_timer = 0.0
        _update_explored()
    queue_redraw()

func _try_resolve_player() -> void:
    var p := get_tree().get_first_node_in_group("player")
    if p is Node3D:
        _player = p

func _world_to_image(world_xz: Vector2) -> Vector2:
    # 1 px per world unit, with FOG_PADDING_PX of unexplored padding around the world.
    return Vector2(
        world_xz.x + world_size * 0.5 + float(FOG_PADDING_PX),
        world_xz.y + world_size * 0.5 + float(FOG_PADDING_PX))

func _update_explored() -> void:
    var img_pos := _world_to_image(Vector2(_player.global_position.x, _player.global_position.z))
    var pcx := int(img_pos.x)
    var pcy := int(img_pos.y)
    var r := int(vision_radius)
    var r_sq := r * r
    var changed := false
    for dy in range(-r, r + 1):
        var y := pcy + dy
        if y < 0 or y >= _fog_size:
            continue
        for dx in range(-r, r + 1):
            var x := pcx + dx
            if x < 0 or x >= _fog_size:
                continue
            if dx * dx + dy * dy > r_sq:
                continue
            if _explored.get_pixel(x, y).r < 1.0:
                _explored.set_pixel(x, y, Color(1, 1, 1, 1))
                changed = true
    if changed:
        _explored_tex.update(_explored)

func _draw() -> void:
    var rect := Rect2(Vector2.ZERO, size)
    draw_rect(rect, background_color, true)
    if _player == null:
        draw_rect(rect, border_color, false, 1.0)
        return

    var center := size * 0.5
    var px_per_unit := size.x * 0.5 / displayed_radius

    # Source rect on fog texture corresponding to displayed area, in pixel coords.
    var pxz := Vector2(_player.global_position.x, _player.global_position.z)
    var src_min := _world_to_image(pxz - Vector2(displayed_radius, displayed_radius))
    var src_max := _world_to_image(pxz + Vector2(displayed_radius, displayed_radius))
    var src_rect := Rect2(src_min, src_max - src_min)
    draw_texture_rect_region(_explored_tex, rect, src_rect, explored_tint)

    # Soft "current vision" overlay (a brighter circle at center).
    draw_circle(center, vision_radius * px_per_unit, vision_tint)

    # Rocks: drawn if explored at any point.
    for rock in get_tree().get_nodes_in_group("rock"):
        if rock is Node3D:
            var rn := rock as Node3D
            if _is_explored(rn.global_position):
                _draw_dot(rn, center, px_per_unit, rock_color, rock_dot_radius)

    # Enemies: drawn only if currently visible.
    for enemy in get_tree().get_nodes_in_group("enemy"):
        if enemy is Node3D:
            var en := enemy as Node3D
            if _is_visible_now(en.global_position):
                _draw_dot(en, center, px_per_unit, enemy_color, entity_dot_radius)

    draw_circle(center, entity_dot_radius, player_color)
    draw_rect(rect, border_color, false, 1.0)

func _draw_dot(n: Node3D, center: Vector2, px_per_unit: float, color: Color, radius: float) -> void:
    var rel := n.global_position - _player.global_position
    var p := center + Vector2(rel.x, rel.z) * px_per_unit
    draw_circle(p, radius, color)

func _is_explored(world_pos: Vector3) -> bool:
    var img := _world_to_image(Vector2(world_pos.x, world_pos.z))
    var x := int(img.x)
    var y := int(img.y)
    if x < 0 or x >= _fog_size or y < 0 or y >= _fog_size:
        return false
    return _explored.get_pixel(x, y).r > 0.5

func _is_visible_now(world_pos: Vector3) -> bool:
    var d := world_pos - _player.global_position
    d.y = 0.0
    return d.length_squared() <= vision_radius * vision_radius
