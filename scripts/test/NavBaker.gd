extends NavigationRegion3D

func _ready() -> void:
    # Wait one physics frame so procedurally-spawned static bodies (rocks)
    # are present in the tree before we bake the navmesh around them.
    await get_tree().physics_frame
    bake_navigation_mesh(false)
