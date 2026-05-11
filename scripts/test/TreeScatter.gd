extends Node3D

@export var tree_count: int = 90
@export var bush_count: int = 140
@export var area_min: Vector2 = Vector2(-95, -95)
@export var area_max: Vector2 = Vector2(95, 95)
@export var clear_radius_around_origin: float = 8.0
@export var random_seed: int = 99221

func _ready() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = random_seed
    for i in tree_count:
        var pos := _pick_position(rng)
        if pos == Vector3.INF:
            continue
        _spawn_tree(pos, rng)
    for i in bush_count:
        var pos := _pick_position(rng)
        if pos == Vector3.INF:
            continue
        _spawn_bush(pos, rng)

func _pick_position(rng: RandomNumberGenerator) -> Vector3:
    for attempt in 12:
        var p := Vector3(
            rng.randf_range(area_min.x, area_max.x),
            0.0,
            rng.randf_range(area_min.y, area_max.y))
        if p.length() >= clear_radius_around_origin:
            return p
    return Vector3.INF

func _spawn_tree(pos: Vector3, rng: RandomNumberGenerator) -> void:
    var trunk_height := rng.randf_range(3.5, 6.5)
    var trunk_radius := rng.randf_range(0.18, 0.32)
    var canopy_radius := rng.randf_range(1.4, 2.6)
    var rot_y := rng.randf_range(0.0, TAU)
    var lean_x := rng.randf_range(-0.06, 0.06)
    var lean_z := rng.randf_range(-0.06, 0.06)

    var tree := StaticBody3D.new()
    tree.add_to_group("tree")
    tree.position = pos
    tree.rotation = Vector3(lean_x, rot_y, lean_z)

    # Trunk visual
    var trunk_mesh_inst := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = trunk_radius * 0.75
    trunk_mesh.bottom_radius = trunk_radius
    trunk_mesh.height = trunk_height
    trunk_mesh_inst.mesh = trunk_mesh
    trunk_mesh_inst.position = Vector3(0, trunk_height * 0.5, 0)
    var trunk_mat := StandardMaterial3D.new()
    var tshade := 0.10 + rng.randf() * 0.08
    trunk_mat.albedo_color = Color(tshade + 0.06, tshade, tshade * 0.7, 1.0)
    trunk_mat.roughness = 0.95
    trunk_mesh_inst.material_override = trunk_mat
    tree.add_child(trunk_mesh_inst)

    # Canopy: two overlapping spheres for fullness
    for i in 2:
        var canopy_mesh_inst := MeshInstance3D.new()
        var canopy_mesh := SphereMesh.new()
        var r := canopy_radius * rng.randf_range(0.85, 1.15)
        canopy_mesh.radius = r
        canopy_mesh.height = r * 2.0 * rng.randf_range(0.85, 1.05)
        canopy_mesh_inst.mesh = canopy_mesh
        var offset_xz := Vector3(rng.randf_range(-0.4, 0.4), 0.0, rng.randf_range(-0.4, 0.4))
        canopy_mesh_inst.position = Vector3(0, trunk_height, 0) + offset_xz + Vector3(0, rng.randf_range(-0.2, 0.4), 0)
        var canopy_mat := StandardMaterial3D.new()
        var g := 0.22 + rng.randf() * 0.18
        canopy_mat.albedo_color = Color(g * 0.45, g, g * 0.4, 1.0)
        canopy_mat.roughness = 0.85
        canopy_mesh_inst.material_override = canopy_mat
        tree.add_child(canopy_mesh_inst)

    # Trunk collision (player + enemies can't pass through)
    var coll := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = trunk_radius
    shape.height = trunk_height
    coll.shape = shape
    coll.position = Vector3(0, trunk_height * 0.5, 0)
    tree.add_child(coll)

    # Navigation obstacle so enemies path around it
    var obs := NavigationObstacle3D.new()
    obs.radius = trunk_radius * 1.5
    obs.height = trunk_height
    obs.avoidance_enabled = true
    tree.add_child(obs)

    add_child(tree)

func _spawn_bush(pos: Vector3, rng: RandomNumberGenerator) -> void:
    # Small grass/bush tuft — visual only, no collision so the player runs through it.
    var bush := Node3D.new()
    bush.position = pos
    bush.rotation.y = rng.randf_range(0.0, TAU)
    var size := rng.randf_range(0.25, 0.7)
    var mesh_inst := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = size
    mesh.height = size * rng.randf_range(0.7, 1.2)
    mesh_inst.mesh = mesh
    mesh_inst.position.y = size * 0.4
    var mat := StandardMaterial3D.new()
    var g := 0.20 + rng.randf() * 0.18
    mat.albedo_color = Color(g * 0.5, g + 0.05, g * 0.35, 1.0)
    mat.roughness = 0.9
    mesh_inst.material_override = mat
    bush.add_child(mesh_inst)
    add_child(bush)
