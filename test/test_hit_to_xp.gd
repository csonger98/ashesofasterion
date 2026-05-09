extends GutTest

const SkillRegistry := preload("res://scripts/skills/SkillRegistry.gd")

# We don't spin up Areas / scene tree in this test; we test the wiring
# logic at the registry level by simulating what PlayerActor will do
# when it receives a hit_landed signal.

func test_hit_landed_handler_awards_sword_xp_for_sword_archetype():
    var r := SkillRegistry.new()
    r._ready()
    # Simulate the function PlayerActor will use: archetype string -> registry track name.
    var archetype := "Sword"
    var damage := 10
    var xp_per_hit := damage  # Plan 1: simple linear; tunable later.
    r.award_xp(archetype, xp_per_hit)
    assert_eq(r.get_track("Sword").xp, 10)
    assert_eq(r.get_track("Axe").xp, 0)

func test_hit_landed_handler_awards_axe_xp_for_axe_archetype():
    var r := SkillRegistry.new()
    r._ready()
    r.award_xp("Axe", 25)
    assert_eq(r.get_track("Axe").xp, 25)
    assert_eq(r.get_track("Sword").xp, 0)

func test_unknown_archetype_no_op():
    var r := SkillRegistry.new()
    r._ready()
    r.award_xp("UnknownThing", 50)
    # No crash, no track touched.
    assert_eq(r.get_track("Sword").xp, 0)
