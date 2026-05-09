extends GutTest

# We test the autoload via a fresh instance; in tests we don't depend on the
# editor's autoload spawn — we instantiate the script directly.

const SkillRegistry := preload("res://scripts/skills/SkillRegistry.gd")

func test_registry_creates_all_thirteen_tracks():
    var r := SkillRegistry.new()
    r._ready()  # explicitly init since we're not in scene tree
    var expected := [
        "Sword", "Axe", "Bow", "Pistol", "Tome", "Forbidden",
        "Pyromancy", "Cryomancy", "Star",
        "Dodge", "Parry", "Stealth", "Salvage",
    ]
    for name in expected:
        assert_not_null(r.get_track(name), "Track '%s' should exist." % name)

func test_get_track_unknown_returns_null():
    var r := SkillRegistry.new()
    r._ready()
    assert_null(r.get_track("NotAThing"))

func test_award_xp_routes_to_named_track():
    var r := SkillRegistry.new()
    r._ready()
    r.award_xp("Sword", 60)
    assert_eq(r.get_track("Sword").level, 1)
    assert_eq(r.get_track("Axe").level, 0)

func test_award_xp_unknown_track_is_no_op():
    var r := SkillRegistry.new()
    r._ready()
    r.award_xp("NotAThing", 1000)
    # Should not crash.
    assert_eq(r.get_track("Sword").xp, 0)

func test_track_levelup_signal_propagates_through_registry():
    var r := SkillRegistry.new()
    r._ready()
    var captured := []
    r.skill_leveled.connect(func(skill_name: String, new_level: int):
        captured.append([skill_name, new_level]))
    r.award_xp("Sword", 50)
    assert_eq(captured, [["Sword", 1]])
