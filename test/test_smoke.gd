extends GutTest

func test_arithmetic_holds_up():
    assert_eq(2 + 2, 4, "Math is fine.")

func test_godot_loaded():
    assert_true(Engine.get_version_info().major >= 4, "Engine is Godot 4 or later.")
