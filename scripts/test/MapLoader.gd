extends Node3D

## Loads a JSON map (produced by tools/map_editor.html) and instantiates the
## described entities. Drop this on a Node3D in a scene that already has a
## Player + lighting + navmesh.

@export_file("*.json") var map_path: String = "res://maps/starting_zone.json"
@export var enemy_scene: PackedScene
@export var orb_scene: PackedScene

signal map_loaded(zones: Array)

func _ready() -> void:
    if not FileAccess.file_exists(map_path):
        push_warning("MapLoader: file not found at %s" % map_path)
        return
    var f := FileAccess.open(map_path, FileAccess.READ)
    var text := f.get_as_text()
    f.close()
    var parsed: Variant = JSON.parse_string(text)
    if parsed == null or not parsed is Dictionary:
        push_error("MapLoader: failed to parse %s" % map_path)
        return
    _build(parsed as Dictionary)

func _build(data: Dictionary) -> void:
    var zones: Array = []
    var ents: Array = data.get("entities", [])
    for raw in ents:
        if not raw is Dictionary:
            continue
        var e: Dictionary = raw
        match e.get("type", ""):
            "rock": _spawn_rock(e)
            "enemy": _spawn_enemy(e)
            "orb": _spawn_orb(e)
            "zone": zones.append(_spawn_zone(e))
    var ps: Variant = data.get("player_spawn")
    if ps is Dictionary:
        var player := get_tree().get_first_node_in_group("player")
        if player is Node3D:
            (player as Node3D).global_position = Vector3(ps.x, 0.0, ps.z)
    map_loaded.emit(zones)

func _spawn_rock(e: Dictionary) -> void:
    var size_xz: float = float(e.get("size_xz", 1.0))
    var size_y: float = float(e.get("size_y", 1.0))
    var rot_y: float = float(e.get("rot_y", 0.0))
    var tilt_x: float = float(e.get("tilt_x", 0.0))
    var tilt_z: float = float(e.get("tilt_z", 0.0))

    var rock := StaticBody3D.new()
    rock.add_to_group("rock")
    rock.position = Vector3(float(e.x), size_y * 0.5, float(e.z))
    rock.rotation = Vector3(tilt_x, rot_y, tilt_z)

    var mesh_inst := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(size_xz, size_y, size_xz)
    mesh_inst.mesh = mesh
    var mat := StandardMaterial3D.new()
    var shade := 0.22 + randf() * 0.22
    mat.albedo_color = Color(shade + 0.04, shade, shade - 0.02, 1.0)
    mat.roughness = 0.92
    mesh_inst.material_override = mat
    rock.add_child(mesh_inst)

    var coll := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = mesh.size
    coll.shape = shape
    rock.add_child(coll)

    var obs := NavigationObstacle3D.new()
    obs.radius = max(mesh.size.x, mesh.size.z) * 0.55
    obs.height = mesh.size.y
    obs.avoidance_enabled = true
    rock.add_child(obs)

    add_child(rock)

func _spawn_enemy(e: Dictionary) -> void:
    if enemy_scene == null:
        return
    var en := enemy_scene.instantiate() as Node3D
    if en == null:
        return
    en.position = Vector3(float(e.x), 0.0, float(e.z))
    add_child(en)

func _spawn_orb(e: Dictionary) -> void:
    if orb_scene == null:
        return
    var orb := orb_scene.instantiate() as Node3D
    if orb == null:
        return
    orb.position = Vector3(float(e.x), 0.0, float(e.z))
    if "fill_amount" in orb and e.has("fill_amount"):
        orb.set("fill_amount", float(e.fill_amount))
    add_child(orb)

func _spawn_zone(e: Dictionary) -> Dictionary:
    # Zones are metadata + a runtime Area3D you can connect to (e.g. trigger UI,
    # change ambient music, gate enemy types). Returned dictionary preserves the
    # full zone data including name and monster_type for game logic to consume.
    var x1: float = float(e.x1)
    var z1: float = float(e.z1)
    var x2: float = float(e.x2)
    var z2: float = float(e.z2)
    var min_x := minf(x1, x2)
    var max_x := maxf(x1, x2)
    var min_z := minf(z1, z2)
    var max_z := maxf(z1, z2)
    var cx := (min_x + max_x) * 0.5
    var cz := (min_z + max_z) * 0.5
    var width := max_x - min_x
    var depth := max_z - min_z

    var area := Area3D.new()
    area.name = "Zone_" + String(e.get("name", "Unnamed")).replace(" ", "_")
    area.position = Vector3(cx, 1.0, cz)
    area.add_to_group("zone")
    area.set_meta("zone_name", String(e.get("name", "Unnamed Zone")))
    area.set_meta("monster_type", String(e.get("monster_type", "none")))

    var coll := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(width, 2.0, depth)
    coll.shape = shape
    area.add_child(coll)
    add_child(area)
    return {
        "name": area.get_meta("zone_name"),
        "monster_type": area.get_meta("monster_type"),
        "area": area,
        "rect": Rect2(min_x, min_z, width, depth),
    }
