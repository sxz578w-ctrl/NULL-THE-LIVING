# AFTERZERO Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an offline-first Android 3D top-down survival prototype that proves movement, combat, resource gathering, a transformative anomaly choice, and a base-building loop.

**Architecture:** Godot 4.7.2 GDScript with a Compatibility renderer. Keep game state, persistence, zone rules, and build costs in scene-independent scripts; scenes own presentation and input. No backend in the first slice.

**Tech Stack:** Godot 4.7.2 Stable, GDScript, Godot SceneTree headless tests, GitHub Actions Android arm64 debug export.

**Spec:** `docs/superpowers/specs/2026-11-24-afterzero-design.md`

## Global Constraints

- Android 64-bit is the first target; viewport is landscape 1280×720 with stretch canvas_items.
- Engine is Godot 4.7.2 Stable; do not use Godot 4.8 beta.
- Renderer is Compatibility; avoid features requiring Vulkan-only renderer paths.
- Game must start and complete its MVP loop without network access.
- All economy/state mutations go through typed, validated core methods.
- Local save schema is version 1; malformed data must not crash startup.
- No paid assets, paid APIs, secrets, auth provider, ads, or purchases in this phase.
- Do not claim device FPS or device compatibility without a real device test.

## Review Focus

- Save JSON with missing fields, wrong types, negative resource values, and unknown schema must fall back safely.
- Unknown resource IDs and zero/negative amounts must never mutate the inventory.
- Build requests for occupied/unknown slots or insufficient funds must leave inventory unchanged.
- Invalid or repeated pulse decisions must not award repeated rewards or apply effects twice.
- Touch input outside control bounds and simultaneous button presses must not break movement or pause state.

---

### Task 1: Repository foundation and project settings

**Files:**
- Create: `README.md`
- Create: `.gitignore`
- Create: `project.godot`
- Create: `scenes/main.tscn`
- Create: `scripts/main.gd`
- Create: `.github/workflows/android-apk.yml`
- Test: `tests/run_tests.gd`

**Interfaces:**
- Produces: project root scene `res://scenes/main.tscn`; headless runner `res://tests/run_tests.gd`.

- [ ] Write a headless smoke test that loads `res://scenes/main.tscn` and checks the root scene exists.
- [ ] Run the test before implementation; expected failure because the project files do not exist.
- [ ] Add project settings for Godot 4.7.2, landscape orientation, Compatibility renderer, application ID `com.afterzero.game`, and Arabic-first locale configuration.
- [ ] Implement a minimal root scene and main script with a visible boot/menu state.
- [ ] Run the smoke test and Godot headless editor parse/import.
- [ ] Commit as `chore: initialize afterzero godot project`.

### Task 2: Typed game state and resource economy

**Files:**
- Create: `scripts/core/game_state.gd`
- Test: `tests/test_game_state.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- Produces: `GameState.add_resource(id: String, amount: int) -> bool` and `GameState.spend_resources(cost: Dictionary) -> bool`.
- Resource IDs are exactly `scrap`, `flux`, and `echo`.

- [ ] Write tests for valid resource addition, unknown IDs, zero/negative amounts, atomic multi-resource spending, and insufficient resources.
- [ ] Run tests and confirm they fail because `GameState` is not implemented.
- [ ] Implement the typed state object with non-negative inventory invariants and atomic spending.
- [ ] Run targeted and full tests; expected all resource tests pass.
- [ ] Commit as `feat: add validated resource economy`.

### Task 3: Zone state and World Pulse choices

**Files:**
- Create: `scripts/world/zone_state.gd`
- Test: `tests/test_zone_state.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- Produces: `ZoneState.apply_pulse(choice: String) -> bool`, properties `stability`, `danger`, `route_open`, `pulse_count`, and `last_choice`.
- Exact choices: `anchor`, `harvest`, `refract`.

- [ ] Write tests for exact effects, invalid choice rejection, and one application per activation token.
- [ ] Run tests and confirm expected failures.
- [ ] Implement bounded state transitions: anchor improves stability and reduces danger; harvest adds danger and marks a resource bonus; refract opens the route and changes danger moderately.
- [ ] Verify values remain in 0..100 and count increments exactly once.
- [ ] Run targeted and full tests; expected all zone tests pass.
- [ ] Commit as `feat: implement world pulse zone decisions`.

### Task 4: Versioned local persistence

**Files:**
- Create: `scripts/core/save_service.gd`
- Test: `tests/test_save_service.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- Produces: `SaveService.save(data: Dictionary) -> bool`, `SaveService.load() -> Dictionary`, and `SaveService.validate(data: Dictionary) -> bool`.
- Save path: `user://afterzero_save_v1.json`.

- [ ] Write tests for round-trip, missing save, corrupted JSON, wrong schema, negative values, and missing nested objects.
- [ ] Run tests and confirm expected failures.
- [ ] Implement strict validation and safe defaults; write through a temporary file then replace the primary save.
- [ ] Run targeted and full tests; expected no malformed input crashes.
- [ ] Commit as `feat: add versioned local save service`.

### Task 5: Touch controls and player movement

**Files:**
- Create: `scripts/ui/touch_controls.gd`
- Create: `scripts/player/player_controller.gd`
- Create: `scenes/player.tscn`
- Test: `tests/test_touch_vector.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- Produces: normalized `Vector2` movement intent, action signals `attack_pressed`, `dash_pressed`, `interact_pressed`.
- Player uses `CharacterBody3D`; movement speed baseline 5.0 m/s; dash cooldown 1.0 s; dash duration 0.16 s.

- [ ] Write tests for dead-zone normalization, maximum magnitude clamp, and diagonal normalization.
- [ ] Run tests and confirm failure before implementation.
- [ ] Implement mobile virtual joystick and touch action buttons; keep keyboard/controller actions as development fallbacks only.
- [ ] Implement player movement, facing, health, and dash cooldown.
- [ ] Run input tests and a headless scene smoke test.
- [ ] Commit as `feat: add touch movement and player controller`.

### Task 6: World zone, resource nodes, and enemy combat

**Files:**
- Create: `scenes/world_zone.tscn`
- Create: `scripts/world/resource_node.gd`
- Create: `scripts/enemies/enemy_controller.gd`
- Create: `scripts/world/world_director.gd`
- Test: `tests/test_resource_node.gd`
- Test: `tests/test_enemy_rules.gd`

**Interfaces:**
- `ResourceNode.collect(state: GameState) -> bool` collects once and routes rewards through GameState.
- `EnemyController.apply_damage(amount: float) -> bool` rejects non-positive damage and returns true on first death.
- Enemy concurrency cap in prototype: 8.

- [ ] Write tests for one-time node collection, invalid reward, enemy damage, and repeated death.
- [ ] Confirm RED results.
- [ ] Implement a hand-built low-poly zone with distinct resource nodes, one enemy type, navigation/chase, proximity attack, and drop reward.
- [ ] Wire player attack/health and HUD signals.
- [ ] Run tests and scene smoke; verify no parse errors.
- [ ] Commit as `feat: add resource exploration and enemy combat`.

### Task 7: Anomaly puzzle and three outcomes

**Files:**
- Create: `scripts/world/pulse_core.gd`
- Create: `scenes/pulse_core.tscn`
- Test: `tests/test_pulse_core.gd`

**Interfaces:**
- `PulseCore.activate_node(node_id: String) -> bool` records each unique node in order.
- `PulseCore.resolve(choice: String, zone: ZoneState, state: GameState) -> bool` only succeeds after all three nodes are activated and only once per puzzle cycle.

- [ ] Write tests for ordered activation, duplicate node rejection, incomplete sequence, invalid outcome, and exactly-once reward.
- [ ] Confirm RED results.
- [ ] Implement three interactable pylons and a final console; choices update the zone state with their consequences.
- [ ] Run targeted and full test suites.
- [ ] Commit as `feat: add anomaly puzzle and world pulse outcomes`.

### Task 8: Base building and progression

**Files:**
- Create: `scripts/world/build_system.gd`
- Create: `scenes/base_hub.tscn`
- Create: `scenes/building.tscn`
- Test: `tests/test_build_system.gd`

**Interfaces:**
- `BuildSystem.try_build(slot_id: String, building_type: String, state: GameState) -> bool`.
- Building types: `extractor`, `relay`, `turret`; slot IDs are fixed by the hub scene.

- [ ] Write tests for costs, occupied slots, unknown types, unknown slots, and insufficient inventory with no partial spending.
- [ ] Confirm RED results.
- [ ] Implement three physical build pads, resource costs, building visuals, and functional effects in prototype scope.
- [ ] Run tests and base scene smoke.
- [ ] Commit as `feat: add base building and upgrade loop`.

### Task 9: Arabic/English HUD, menus, and accessibility settings

**Files:**
- Create: `scripts/ui/hud.gd`
- Create: `scripts/ui/localization.gd`
- Create: `scenes/ui/hud.tscn`
- Create: `scenes/ui/main_menu.tscn`
- Test: `tests/test_localization.gd`

**Interfaces:**
- Language values: `ar`, `en`; default `ar`.
- UI strings resolve through one localization table; layout direction updates when language changes.

- [ ] Write tests for missing translation fallback and language-direction resolution.
- [ ] Confirm RED results.
- [ ] Implement functional HUD, pause/settings, Arabic RTL and English LTR, volume/rumble and UI scale settings.
- [ ] Run tests and inspect the exported UI scene at mobile resolution.
- [ ] Commit as `feat: add bilingual mobile hud and settings`.

### Task 10: Android export pipeline and release evidence

**Files:**
- Modify: `.github/workflows/android-apk.yml`
- Create: `export_presets.cfg`
- Modify: `README.md`
- Test: CI workflow import, tests, smoke and Android export.

**Interfaces:**
- Artifact name: `AFTERZERO-Android-Prototype`.
- Package ID: `com.afterzero.game`.
- Export target: Android ARM64 debug APK.

- [ ] Configure pinned Godot 4.7.2 binary and export templates, Java 17 and Android SDK packages.
- [ ] Run headless import/parse, all tests, smoke scene, and Android export in order.
- [ ] Upload APK artifact only after all checks pass.
- [ ] Record CI run URL, commit, artifact ID, size, and expiry in release notes.
- [ ] Commit as `ci: add verified android prototype build`.

## Completion Contract

The vertical slice is complete only after Tasks 1–10 pass their own tests and the final GitHub Actions run uploads an Android ARM64 debug APK. A CI success proves import, tests, smoke execution, and packaging only; it does not prove stable frame rate on the user's phone. Device QA and release signing remain explicit follow-up gates.
