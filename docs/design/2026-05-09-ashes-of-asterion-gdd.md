# Ashes of Asterion — Game Design Document

> **Status:** v0.1 — initial GDD from brainstorming session 2026-05-09. Approved by author. Subject to revision during implementation.

## Context

**Ashes of Asterion** is a new game project being designed from scratch by a solo developer. The game's pitch (from the GitHub repo description):

> Dark fantasy ARPG. No classes. No character levels. Only the skills you actually use grow stronger. Your magical world has been invaded by something from beyond the stars. Loot the wreckage, master forbidden powers, and carve through the ashes of Asterion.

This document is the Game Design Document — a vision-and-systems spec, not yet an implementation plan. The next step after approval is a separate implementation plan and (eventually) a vertical slice prototype.

---

## 1. Vision & Pillars

**One-line pitch:** A dark fantasy ARPG where a magical world is dying after an alien invasion, and your survivor character grows by *what you actually do* — wield a sword, you get better with swords; wield forbidden alien magic, you get stronger and more corrupted.

**Design pillars** (the few rules every system must answer to):

1. **You are what you do.** No classes, no character levels. The only progression axis is the skills you use. Build expression emerges from habit.
2. **Power has a price.** Forbidden alien powers are real and tempting. Using them progresses a Corruption arc that the world reacts to.
3. **Everything is craftable.** Loot is not the obsession. Materials and recipes are; the verb is *salvage and craft*, not *roll affixes*.
4. **Handcrafted, not procedural.** The world is finite, designed, lore-soaked. Replay value comes from faction routes and corruption choices, not random generation.
5. **Solo-dev shippable.** Every system above must be implementable by one person in Godot. Scope reduction is itself a pillar.

---

## 2. Confirmed Pillars (rolling summary)

| Decision | Locked value |
|---|---|
| Engine | Godot 4 |
| Team | Solo developer |
| Platform | PC primary |
| Camera | Isometric (3/4 angle), orthographic projection |
| Art pipeline | 3D models rendered through orthographic camera (animate once, render all directions) |
| Combat | WASD + mouse aim, action ARPG with dodge roll |
| Run structure | Souls-like persistent character (no roguelite reset) |
| World structure | Hub + crash-site spokes (handcrafted zones) |
| Multiplayer | Single-player only |
| Skill model | Hybrid use-based, ~13 tracks |
| Skill cap | 100 per skill, 10 tiers (every 10 levels) |
| Tier rewards | Per-level **amplifier point** (small passive bump) **plus** perk choice every 10 levels |
| Forbidden cost | Corruption resource (dual-purpose meter + per-cast cost) |
| Resources | HP / Stamina / Mana / Corruption (4 resources) |
| Use rule | Successful actions vs. real opponents only — no dummy grinding |
| Loot model | Crafting-first; no random affixes; recipes/schematics are the collectible |
| Save system | Bonfires + cleared-zone freeform saves (with respawn-on-reload caveat) |
| Death penalty | Drop XP/echoes at death spot; recover or lose them |
| Factions | Four (Order, Ash Pact, Choir, Wayfarers) |
| Protagonist | Blank-slate, player-named survivor |
| Story delivery | Branching, faction-driven; environmental + dialogue |
| Length target | ~25–35 hr main path + 10–15 hr endgame |
| Tone | Dark fantasy visuals, **EDM-influenced soundtrack** |

---

## 3. Core Gameplay Loop

```
            +--------------------+
            |        HUB         |
            | (refuge / cathedral)|
            |  craft, train, rest |
            +----------+---------+
                       |
            choose crash-site spoke
                       |
                       v
            +--------------------+
            |   CRASH-SITE ZONE  |
            |  (handcrafted)     |
            |  fight, salvage,   |
            |  find schematics,  |
            |  pursue boss,      |
            |  earn faction rep  |
            +----------+---------+
                       |
              die? --> recover echoes (corpse run) or lose
              live? -> return to hub, craft, level skills passively from XP banked
                       |
                       v
            corruption rises with forbidden use
            faction standing shifts
            new schematics + zones unlock
```

Moment-to-moment loop (in a zone): *engage → aim/dodge → land hits → bank skill XP → loot materials → discover schematics → push deeper → boss → return*.

Session loop (per playthrough hour): *clear an arc of a crash site → craft an upgrade at hub → spend perk choices → take a faction quest → return to a deeper layer*.

---

## 4. Combat

### Controls (PC, M+KB)

| Input | Action |
|---|---|
| WASD | Movement |
| Mouse | Aim cursor (cone of attack/cast) |
| LMB | Light attack with equipped weapon |
| RMB | Heavy attack / aimed weapon special |
| Space | Dodge roll (Stamina) |
| Shift | Block / parry (weapon-dependent) |
| 1–4 | Skill / spell hotbar (Mana, sometimes Corruption) |
| Q | Consumable (potion, salve) |
| E | Interact (loot, doors, dialogue) |
| Tab | Inventory / craft / skills overlay |
| F | Targeted lock (soft-lock to nearest enemy) |

Controller (gamepad) supported as parity later; M+KB is primary.

### Combat feel pillars

- **Aim matters.** Hits don't auto-track; arcs and aim cones determine connect. Aim discipline grows naturally as the player improves.
- **Stamina-managed action.** Dodge, heavy attack, parry all consume Stamina. Light attacks are free or cheap. Encourages varied engagement.
- **Mana for spells, Corruption for forbidden.** Two mage axes that compete for hotbar slots and resource attention.
- **Soft target-lock**, not hard target-lock. Iso camera does not rotate. Lock biases aim toward an enemy but doesn't force movement.
- **No floating damage numbers.** Damage feedback is hit-flash, screen-shake, blood/ichor splatter, and audio. Pure dark-fantasy presentation. (Optional toggle for accessibility.)

### Enemies

- Mortal corruption-touched: cultists, beasts, fallen knights of the Order. Telegraph-driven combat patterns.
- Alien wreckage hostile: writhing organic-mechanical things from the wrecks. Often spore-emitters, ground-effect zones, mid-air drifters.
- Mini-bosses at the heart of each crash site, plus a final crash-site boss.
- Final boss in the central crater that opened the invasion.

---

## 5. Skill System

### Track list (~13 tracks, locked)

**Weapon archetypes (6):** Sword · Axe · Bow · Pistol/Sidearm · Tome (caster focus) · Forbidden (alien weapons)
**Magic schools (3):** Pyromancy · Cryomancy · Star (alien / forbidden)
**Body skills (4):** Dodge · Parry · Stealth · Salvage

Each is its own use-based progression track. There are no underlying attributes — skill levels *are* the stats. Weapon damage and magic potency scale directly off the relevant track's level.

### Use rule

- A swing connecting on a real enemy → +Sword XP (or relevant weapon).
- A spell that successfully resolves on a real target → +Magic XP.
- A successful dodge through an attack → +Dodge XP.
- A successful parry → +Parry XP.
- Stealth XP = remaining undetected during contact + landing first hits unseen.
- Salvage XP = breaking down wreckage / corpses for materials.
- **No safe-grinding.** Training dummies and walls grant zero XP. (Deliberate; supports the "you are what you do" pillar.)

### Tier reward model

- **Every level (1–100):** an "amplifier point" to that skill — a small flat passive bump (proposed defaults: weapons +1% damage / level; magic +1% potency; body skills +1% effect).
- **Every tier (10 levels):** a perk choice from 2–3 options, hand-authored per skill.
- 13 skills × 10 perk-choice tiers ≈ 130 perks total to author. Significant but bounded; some perks shared across thematically adjacent skills (e.g. all weapons share a Tier 1 "Footwork" perk option) reduces effective authoring load.
- A focused playthrough is expected to hit ~60–80 in 2–3 main skills, ~30–50 in supporting skills, and barely touch 1–2 tracks. Maxing every track in one playthrough is not feasible.

### Cross-skill synergy

Selected perks reference adjacent tracks: e.g. *Pyromancy Tier 5 — Cinder Edge:* "When Sword skill is at least 30, your Pyromancy spells leave a burning weapon coat for 10s on cast." This rewards hybrid play without forcing classes.

---

## 6. Corruption (the unique mechanic)

Corruption is both a **persistent narrative meter** (0–100) and a **per-cast resource** for forbidden powers. It is the design's central pressure mechanic.

### How it accrues

- Casting Star magic (forbidden school) — +X Corruption per cast, X scales with spell tier.
- Wielding Forbidden weapons — +Corruption per kill with a forbidden weapon.
- Crafting forbidden gear at alien altars — +Corruption per craft.
- Choosing certain faction-quest outcomes (e.g. siding with the Choir).

### How it is reduced

- Quest-gated cleansing rituals at the Order's chapel (limited number per playthrough).
- Choice-driven story beats with the Wayfarers (sacrifice an item, pay a price).
- Sleep at certain anti-corruption shrines (each usable once).

### Threshold effects (proposed)

| Corruption | Effect |
|---|---|
| 0–24 | Baseline. Forbidden powers usable but expensive. NPCs neutral. |
| 25 | Mutation: **Star-touched eye** — see hidden runes / paths. +1 Forbidden cap. |
| 50 | Mutation: **Voidscar** — visible markings; some Order NPCs refuse trade. Forbidden +20% potency. |
| 75 | Mutation: **Spectral haze** — minor enemies sometimes flee on sight. Order hostile by default. Wayfarers charge 2× prices. |
| 100 | Locked into the **Ash** ending path — Choir aligned; cleansing rituals no longer work. |

Corruption is **the** narrative-pressure system. It interfaces with every faction, gates two endings, and reshapes what NPCs say to the player. It is not just flavor.

---

## 7. Crafting & Loot

### Hard rules

- **No random affixes.** No prefix-suffix slot machine.
- **Everything craftable from start.** Limited only by recipe knowledge and material access.
- **Schematics are the collectible.** Found in wreckage, taught by NPCs, gated by faction or corruption.
- **Material grade is the depth axis.** Same recipe, different grade tier, different output.

### Material types (proposed)

| Material | Source | Used for |
|---|---|---|
| Cinder | Pyre-touched enemies, fire wreckage | Pyromancy gear, fire-aligned weapons |
| Frost ore | Cold zones, ice creatures | Cryomancy gear, frost weapons |
| Ichor | Alien wreckage, forbidden enemies | Forbidden gear, Star-school catalysts |
| Sigil | Rare reagent in deep wreckage | Rune-engravings on weapons (passive effects) |
| Alloy | Iron / refined / void grade | Base weapon and armor frames |
| Voidsilk | Forbidden zones | High-end armor; raises Corruption when worn |
| Crystals | Caves, deep zones | Mana focus, spell catalyst |

Grade tiers: *rough → refined → exalted*. A grade upgrade = a sizeable stat jump, but the recipe is the same. This replaces the "loot treadmill."

### Recipe taxonomy

- **Common recipes:** Available at hub vendors (~20). Basic gear, basic potions.
- **Schematic recipes:** Found in wreckage, NPCs, hidden caches (~80–100 across the game). Most weapons, armor sets, advanced potions.
- **Forbidden constructs:** Recipe + alien altar required (~10–15). Each raises Corruption when crafted. These are the strongest items in the game.

### Crafting locations

- **Hub forge** — mortal weapons & upgrades.
- **Hub alchemist** — potions, salves, throwables.
- **Hub tailor** — armor sets.
- **Alien altar** (one per crash site) — forbidden constructs only; no mortal crafting here.

---

## 8. World & Zones

### Hub: The Refuge (working name: *Asterion's Ash*)

A surviving fortress-cathedral above the central crater. Static, safe, contains:
- 4 faction representatives (one per faction; their availability shifts with corruption / faction rep)
- Forge, alchemist, tailor (mortal crafting)
- Storage chest (shared across saves)
- Trainers (lore quests that grant rare schematics)
- A locked door to the central crater (final zone)

### Crash sites (5 spokes + 1 final)

Each is a handcrafted zone with:
- Distinct biome and corrupted-mortal/alien enemy mix
- 1 alien altar (forbidden crafting)
- ~3–5 hours of content, including 1 mid-boss and 1 main boss
- A "signature" forbidden power tied to the boss
- 2–3 schematic discoveries
- Faction quest hooks that resolve at the hub

Working zone list (final names in implementation):
1. **The Pyre Forest** — fire-touched woodland, Pyromancy synergy.
2. **The Glass Steppe** — vitrified plains, Cryomancy synergy.
3. **The Sunken Vestry** — drowned cathedral, Tome / Sword synergy.
4. **The Spore Hollow** — fungal-alien caves, Stealth / Bow synergy.
5. **The Choir's Reach** — high cult stronghold, Star-school synergy.
6. **The Crater** — final, opens after specific faction + corruption thresholds met.

### Zone interconnection

- Hub → any unlocked spoke via map screen (pure Bloodborne lamp / Hunter's Dream model).
- Within a zone, fully connected handcrafted geometry with internal shortcuts unlocking back to entry.

---

## 9. Save & Death

### Save system

- **Bonfires/altars** in zones and at the hub: refill HP/Stam/Mana, respawn most enemies, bank skill XP.
- **Once a zone is fully cleared,** the player gains the ability to **save anywhere within that zone** for the rest of that visit.
  - On reload, **enemies respawn** as if rested — so the chosen save spot becomes a tactical decision. ("Don't save in the middle of the spawn-heavy room.")
  - This is a deliberate twist on Souls-likes that rewards spatial awareness even after clearing.

### Death penalty

- Death drops all unspent skill XP ("**echoes**") at the death location.
- Player respawns at last bonfire. Recovers echoes if they reach the death spot before dying again.
- Die before recovery → echoes lost forever.
- Banked-at-bonfire XP is safe.

### Banked vs unspent XP

- XP is earned in real time during play.
- "Banking" happens at bonfires — at-bonfire, unspent XP becomes spent (auto-distributes per use, no manual allocation needed; the use-based model means the player has already chosen their build by acting).
- Echoes (the death-droppable amount) = XP earned since the last bonfire visit.

---

## 10. Factions & Story

### Factions (final names TBD)

| Faction | Core stance | Quest texture | Endgame |
|---|---|---|---|
| **The Order** | Purify all alien influence. Anti-corruption. | Cleansing missions, alien-relic destruction, defense of the hub. | Reclaim ending — restore mortal world. |
| **The Ash Pact** | Pragmatic survival; use alien tech *carefully*. | Salvage runs, gear-recovery quests, neutralizing radical Choir cells. | Steward ending — uneasy peace, hybrid civilization. |
| **The Choir** | Embrace transformation; the invasion is ascension. | Corruption-rising rituals, recruit dissidents, defile Order shrines. | Ash ending — the player ascends, world ends as we know it. |
| **The Wayfarers** | Neutral salvager merchants; loyal to no creed. | Trade, smuggling, escort, lore. | Vanish ending — the Wayfarers and the player walk away from all of it. |

Faction reputation is tracked numerically (-100 / +100). Each major quest line is gated by a reputation threshold and (often) a corruption threshold.

### Story shape

- **Cold open:** survivor wakes in the wreckage of their village. A Wayfarer caravan rescues them and brings them to the hub.
- **Act 1:** introduction to the four factions; first crash site quest (any faction can hook the player).
- **Act 2:** four crash sites cleared; faction conflict at the hub erupts. Player begins to lock into a faction route by mid-Act-2.
- **Act 3:** final faction-aligned crash site (different unlocks based on faction). Final crater opens.
- **Endings:** four primary, plus permutations driven by corruption thresholds and side-quests completed.

### Delivery

- **Default text-first** with light VO at the hub (one or two lines per faction rep on first meeting / on faction-shifting moments). Defers cost.
- Item descriptions, environmental staging, and journal entries carry the bulk of lore.
- Branching dialogue trees at the hub; choice-driven side quests.

---

## 11. Audio & Tone

### Visual tone (working)

Dark fantasy world, post-cataclysm. Earth tones — rust, moss, ash, bone — punctured by alien color (oily violets, bone-white, alien greens). Crash sites bleed wrongness into surrounding biomes. Order architecture: brass and stained glass. Choir architecture: flesh and crystal. Wayfarer presence: lantern-light and traveling tents.

### Audio tone (locked: fantasy + EDM)

- **Exploration:** ambient electronic with fantasy textures (drone synths over distant choirs, organic textures, sparse low percussion).
- **Combat:** EDM-driven — synthwave or industrial undertones with fantasy choral leads. Boss themes lean hard into electronic genre fusion (think **Furi** / **Hyper Light Drifter** / **Mick Gordon's Doom** style aggression layered with dark-fantasy choral motifs).
- **Hub:** quieter, longing electronic ambient with acoustic textures (faction quarter has its own light leitmotif).
- **Forbidden / Star magic:** synthesizer-led, distorted, alien — lean fully into EDM idioms (granular synthesis, glitchy percussion).
- This audio choice is **distinctive** and **solo-dev practical** — electronic music is more achievable for a solo composer than orchestral, and fits the cosmic-invasion theme thematically.

---

## 12. Technical Architecture (Godot)

High-level only — implementation plan will detail this.

### Project structure (proposed)

```
res://
  scenes/
    actors/         (Player.tscn, enemies, NPCs)
    zones/          (one scene per zone, hub.tscn, etc.)
    ui/             (HUD, inventory, skill panel, dialogue)
    boss/           (per-boss scenes)
  scripts/
    actor/          (BaseActor.gd, PlayerActor.gd, EnemyActor.gd)
    skills/         (SkillTrack.gd, PerkRegistry.gd, UseHook.gd)
    crafting/       (Recipe.gd, MaterialDef.gd, CraftingStation.gd)
    corruption/     (CorruptionTracker.gd, MutationApplier.gd)
    save/           (SaveSystem.gd, SaveSlot.gd)
    factions/       (FactionTracker.gd, FactionQuest.gd)
    ai/             (BaseAI.gd, behavior trees per archetype)
  resources/
    skills/         (one .tres per skill track + perks)
    recipes/        (one .tres per recipe)
    items/          (weapons, armor, materials, consumables)
    enemies/        (stat blocks + AI refs)
  art/              (3D models, animations, materials)
  audio/            (music, SFX)
  shaders/          (corruption visual effects, dissolve, etc.)
```

### Key technical pillars

- **Resources (.tres) for data.** Skills, recipes, items, enemy defs are Godot Resources, not scripts. Edited as data, version-controlled cleanly.
- **Signal-driven combat.** Hit detection emits signals (`hit_landed(actor, weapon, dmg)`), consumed by the SkillTrack to award XP. Decouples combat from progression.
- **Save = JSON snapshot of player state + zone-clear flags + faction state + corruption + recovered echoes pointer.** No save scummy mid-action saves on first pass; respect the "save respawns enemies" rule.
- **Camera:** orthographic Camera3D, fixed angle, lerp-follow Player. No rotation.
- **Lighting:** baked GI for static zones + dynamic lights for combat. Godot 4 LightmapGI handles this.

---

## 13. Scope & Roadmap

### Phase 0 — Pre-production (current phase)

- This GDD finalized.
- Core combat prototype: a single room, player + 1 enemy, WASD + mouse aim, dodge, light attack.
- Skill XP hookup: confirm `hit_landed` → SkillTrack pipeline works.
- Pick (or commission) an art style sample for the iso camera (1 character + 1 environment tile).

### Phase 1 — Vertical Slice (deliverable target)

**Scope:**
- 1 hub (cut-down, 2 NPCs, forge only)
- 1 crash site (~2 hours) with 1 mid-boss and 1 main boss
- 5 skill tracks playable (Sword, Bow, Pyromancy, Dodge, Salvage)
- 1 forbidden weapon assemblable at altar
- Full save/death/echo loop functional
- Corruption meter functional with one threshold effect (Star-touched eye)
- 1 faction (the Ash Pact) with 2 quests
- Audio: 3 tracks (hub, exploration, combat)

**Goal:** prove the core loop is fun and that the use-based system *feels* satisfying.

### Phase 2 — Production

If the slice plays well: scope the remaining 4 zones, 12 skills, 3 factions, full corruption + ending logic. Estimated 18–30 months solo at part-time pace; tighter if full-time.

### Phase 3 — Polish & Launch

UI pass, audio finalization, accessibility, controller support, demo build, marketing surface (Steam page).

---

## 14. Open Questions / Detail-Level TBDs

These are intentionally deferred — they are detail-level and best resolved during implementation, not in the GDD:

- Final faction names and visual designs.
- Final zone names and biome details.
- Recipe count per material grade (~target 100–150 total recipes).
- Voice acting scope (currently planned: hub-only, ~30 lines max).
- Difficulty options (single difficulty? mid + hard? accessibility settings?).
- Controller-first parity timeline.
- Localization plan.
- Final boss design specifics.

---

## 15. Verification Plan

A GDD is verified by **three checks**:

1. **Internal coherence.** Every system in this doc points to or supports the design pillars in §1. ✓ (Corruption ↔ Forbidden ↔ Factions all interlock; crafting ↔ schematics ↔ wreckage all interlock.)
2. **Solo-dev shippability.** Estimate scope per system. The vertical slice in §13 is the canonical test — if §13 cannot be built in 6–9 months solo, the GDD is over-scoped. Current estimate: feasible.
3. **Player-facing intuition.** Can the pitch be communicated in 30 seconds? *"Dark fantasy ARPG. You don't pick a class — you become what you use. The world's been invaded by alien wrongness, and the more you wield its forbidden powers, the more you become it. Loot the wreckage, craft your gear from the start, choose a faction, and decide what kind of survivor you'll be."* ✓

The implementation plan (next step) will define:
- Concrete acceptance tests for the vertical slice.
- A milestone-by-milestone build order.
- Critical-path dependencies between systems (e.g. Skill system must precede Combat tuning).
