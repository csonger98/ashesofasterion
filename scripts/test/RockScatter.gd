extends Node3D

@export var count: int = 120
@export var area_min: Vector2 = Vector2(-95, -95)
@export var area_max: Vector2 = Vector2(95, 95)
@export var clear_radius_around_origin: float = 6.0
@export var min_size: float = 0.4
@export var max_size: float = 2.4
@export var random_seed: int = 12345

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	for i in count:
		var pos := Vector3.ZERO
		var found := false
		for attempt in 12:
			pos = Vector3(
				rng.randf_range(area_min.x, area_max.x),
				0.0,
				rng.randf_range(area_min.y, area_max.y))
			if pos.length() >= clear_radius_around_origin:
				found = true
				break
		if not found:
			continue
		_spawn_rock(pos, rng)

func _spawn_rock(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var size_xz := rng.randf_range(min_size, max_size)
	var size_y := size_xz * rng.randf_range(0.5, 1.1)
	var rock := StaticBody3D.new()
	rock.add_to_group("rock")
	rock.position = pos + Vector3(0.0, size_y * 0.5, 0.0)
	rock.rotation = Vector3(
		rng.randf_range(-0.25, 0.25),
		rng.randf_range(0.0, TAU),
		rng.randf_range(-0.25, 0.25))

	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size_xz, size_y, size_xz * rng.randf_range(0.7, 1.0))
	mesh_inst.mesh = mesh

	var mat := StandardMaterial3D.new()
	var shade := 0.22 + rng.randf() * 0.22
	mat.albedo_color = Color(shade + 0.04, shade, shade - 0.02, 1.0)
	mat.roughness = 0.92
	mesh_inst.material_override = mat
	rock.add_child(mesh_inst)

	var coll := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	coll.shape = shape
	rock.add_child(coll)

	# Runtime navigation obstacle so enemies' avoidance steers around the rock
	# even if the navmesh bake didn't include it.
	var obs := NavigationObstacle3D.new()
	obs.radius = max(mesh.size.x, mesh.size.z) * 0.55
	obs.height = mesh.size.y
	obs.avoidance_enabled = true
	rock.add_child(obs)

	add_child(rock)
