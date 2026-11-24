from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_project_entrypoints_and_autoload_exist():
    project = read("project.godot")
    assert 'run/main_scene="res://scenes/main.tscn"' in project
    assert 'SaveManager="*res://scripts/core/save_manager.gd"' in project
    assert (ROOT / "scenes/main.tscn").is_file()


def test_all_res_references_exist():
    sources = list(ROOT.rglob("*.gd")) + list(ROOT.rglob("*.tscn")) + [ROOT / "project.godot"]
    missing = []
    for source in sources:
        text = source.read_text(encoding="utf-8")
        for ref in re.findall(r"res://[A-Za-z0-9_./-]+", text):
            if not (ROOT / ref.removeprefix("res://")).exists():
                missing.append((str(source.relative_to(ROOT)), ref))
    assert not missing, f"Missing resources: {missing}"


def test_project_uses_mobile_safe_renderer_and_identity():
    project = read("project.godot")
    assert "gl_compatibility" in project
    assert "window/handheld/orientation=1" in project
    assert 'config/icon="res://assets/null_icon.svg"' in project
    assert "com.nullgame.thelivingtouch" in read("export_presets.cfg")


def test_all_six_campaign_missions_are_present():
    catalog = read("scripts/core/game_catalog.gd")
    for mission_id in ["first_pulse", "veyl_orbit", "echo_signal", "transfer", "hush_trap", "resonance_gate"]:
        assert re.search(r'"id"\s*:\s*"' + re.escape(mission_id) + r'"', catalog)
    assert catalog.count('"id"') >= 6


def test_three_species_are_declared():
    catalog = read("scripts/core/game_catalog.gd")
    for species in ["LUMA", "VEYL", "ECHO"]:
        assert re.search(r'"id"\s*:\s*"' + species + r'"', catalog)


def test_four_game_modes_are_wired():
    main = read("scripts/ui/main.gd")
    screen = read("scripts/ui/game_screen.gd")
    for mode in ["story", "survival", "daily", "lab"]:
        assert f'"{mode}"' in main
        assert f'"{mode}"' in screen


def test_core_system_files_are_present():
    for path in [
        "scripts/core/touch_dna.gd",
        "scripts/core/game_rules.gd",
        "scripts/core/save_manager.gd",
        "scripts/world/world_view.gd",
        "scripts/ui/game_screen.gd",
        "scripts/ui/main.gd",
    ]:
        assert (ROOT / path).is_file()


def test_visual_svg_assets_are_present():
    for asset in ["null_icon.svg", "null_backdrop.svg"]:
        path = ROOT / "assets" / asset
        assert path.exists() and path.stat().st_size > 100


def test_tutorial_and_pause_flow_are_wired():
    main = read("scripts/ui/main.gd")
    screen = read("scripts/ui/game_screen.gd")
    assert "func _build_tutorial()" in main
    assert "func _show_pause_overlay()" in screen
    assert "func _hide_pause_overlay()" in screen


def test_evolution_memory_is_persisted_and_rendered():
    save_manager = read("scripts/core/save_manager.gd")
    world = read("scripts/world/world_view.gd")
    screen = read("scripts/ui/game_screen.gd")
    assert "func remember_species" in save_manager
    assert "func set_species_evolution" in world
    assert "world.set_species_evolution" in screen


def test_survival_repeat_diminishing_returns_are_wired():
    rules = read("scripts/core/game_rules.gd")
    screen = read("scripts/ui/game_screen.gd")
    assert "repeat_count" in rules
    assert "survival_repeat_count" in screen


def test_settings_and_save_repair_are_wired():
    save_manager = read("scripts/core/save_manager.gd")
    for setting in ["reduced_motion", "sound_enabled", "haptics_enabled", "simplified_gestures", "high_contrast", "large_ui"]:
        assert setting in save_manager
    assert "_save_shape_repair()" in save_manager
    assert "_sanitize_int_array" in save_manager


def test_touch_confidence_and_noise_controls_are_wired():
    dna = read("scripts/core/touch_dna.gd")
    rules = read("scripts/core/game_rules.gd")
    world = read("scripts/world/world_view.gd")
    screen = read("scripts/ui/game_screen.gd")
    assert '"confidence"' in dna
    assert 'str(signature.get("confidence", "high")) == "low"' in rules
    assert "func set_noise" in world
    assert "func is_route_blocked" in rules
    assert "time_since_gesture" in screen


def test_no_mixed_tab_space_indentation():
    for path in ROOT.rglob("*.gd"):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            assert not re.match(r"^\t+ +", line), f"Mixed indentation at {path}:{line_number}"


def test_critical_mission_and_survival_test_runner_exists():
    runner = read("tests/test_runner.gd")
    for test_name in [
        "_test_campaign_first_mission",
        "_test_transfer_requires_two_steps",
        "_test_final_mission_sequence",
        "_test_survival_loop_is_stronger",
        "_test_low_confidence_rejected",
        "_test_noise_route_blocking_is_scoped",
    ]:
        assert test_name in runner
