extends MeshInstance3D

@export var tip_path: NodePath
@export var base_path: NodePath
@export var trail_color: Color = Color(0.9, 0.97, 1.0, 0.85)
@export var sample_lifetime_sec: float = 0.22
@export var min_segment_length: float = 0.04

var _imm: ImmediateMesh
var _mat: StandardMaterial3D
var _tip_node: Node3D
var _base_node: Node3D
var _samples: Array = []
var _recording: bool = false

func _ready() -> void:
    top_level = true
    global_transform = Transform3D.IDENTITY
    _imm = ImmediateMesh.new()
    mesh = _imm
    _mat = StandardMaterial3D.new()
    _mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _mat.albedo_color = trail_color
    _mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _mat.vertex_color_use_as_albedo = true
    material_override = _mat
    if not tip_path.is_empty():
        var tn := get_node_or_null(tip_path)
        if tn is Node3D:
            _tip_node = tn
    if not base_path.is_empty():
        var bn := get_node_or_null(base_path)
        if bn is Node3D:
            _base_node = bn

func start() -> void:
    _recording = true
    _samples.clear()

func stop() -> void:
    _recording = false

func _process(delta: float) -> void:
    if _recording and _tip_node != null and _base_node != null:
        var tip_pos: Vector3 = _tip_node.global_position
        var base_pos: Vector3 = _base_node.global_position
        var should_add := _samples.is_empty()
        if not should_add:
            var last_tip: Vector3 = _samples.back().tip
            should_add = tip_pos.distance_to(last_tip) >= min_segment_length
        if should_add:
            _samples.append({"tip": tip_pos, "base": base_pos, "age": 0.0})
    for i in range(_samples.size() - 1, -1, -1):
        _samples[i].age += delta
        if _samples[i].age >= sample_lifetime_sec:
            _samples.remove_at(i)
    _imm.clear_surfaces()
    if _samples.size() < 2:
        return
    _imm.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mat)
    for s in _samples:
        var age: float = s.age
        var tip: Vector3 = s.tip
        var base: Vector3 = s.base
        var alpha: float = 1.0 - (age / sample_lifetime_sec)
        var c := trail_color
        c.a *= alpha
        _imm.surface_set_color(c)
        _imm.surface_add_vertex(tip)
        _imm.surface_add_vertex(base)
    _imm.surface_end()
