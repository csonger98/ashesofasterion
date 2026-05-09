extends GutTest

const SkillTrack := preload("res://scripts/skills/SkillTrack.gd")

func test_new_track_starts_at_zero():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    assert_eq(t.xp, 0)
    assert_eq(t.level, 0)
    assert_eq(t.tier, 0)
    assert_almost_eq(t.amplifier, 0.0, 0.0001)

func test_add_xp_below_threshold_no_levelup():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    t.add_xp(20)
    assert_eq(t.xp, 20)
    assert_eq(t.level, 0)

func test_add_xp_crosses_threshold_levels_up():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    t.add_xp(60)  # level 1 needs 50
    assert_eq(t.level, 1)
    assert_eq(t.tier, 0)  # tier 0 is levels 0-9
    assert_almost_eq(t.amplifier, 0.01, 0.0001)

func test_add_xp_can_skip_multiple_levels_at_once():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    t.add_xp(10000)  # well past level 10
    assert_gte(t.level, 10)
    assert_gte(t.tier, 1)

func test_amplifier_scales_linearly_with_level():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    t.level = 50  # set directly for the test
    assert_almost_eq(t.amplifier, 0.50, 0.0001)

func test_cap_at_100():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    t.add_xp(99999999)
    assert_eq(t.level, 100)
    assert_eq(t.tier, 10)
    assert_almost_eq(t.amplifier, 1.00, 0.0001)

func test_xp_for_level_formula():
    var t := SkillTrack.new()
    assert_eq(t.xp_for_level(1), 50)
    assert_eq(t.xp_for_level(2), 200)
    assert_eq(t.xp_for_level(10), 5000)
    assert_eq(t.xp_for_level(100), 500000)

func test_xp_at_level_returns_cumulative_xp_for_level_n():
    # cumulative xp at level n = xp_for_level(n)  (we use absolute thresholds, not deltas)
    var t := SkillTrack.new()
    t.add_xp(50)
    assert_eq(t.level, 1)
    t.add_xp(150)  # total now 200, threshold for level 2
    assert_eq(t.level, 2)

func test_signal_emitted_on_levelup():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    var captured := []
    t.leveled_up.connect(func(new_lvl): captured.append(new_lvl))
    t.add_xp(50)  # ought to fire once for level 1
    assert_eq(captured, [1])

func test_signal_emitted_for_each_level_when_skipping():
    var t := SkillTrack.new()
    t.skill_name = "Sword"
    var captured := []
    t.leveled_up.connect(func(new_lvl): captured.append(new_lvl))
    t.add_xp(450)  # 50 -> L1, 200 -> L2, 450 -> L3
    assert_eq(captured, [1, 2, 3])
