from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def test_afterzero_project_has_android_first_godot_configuration():
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    assert 'config/name="AFTERZERO"' in project
    assert 'run/main_scene="res://scenes/main.tscn"' in project
    assert 'window/handheld/orientation=0' in project
    assert 'renderer/rendering_method="gl_compatibility"' in project

def test_afterzero_design_and_plan_exist():
    assert (ROOT / "docs/superpowers/specs/2026-11-24-afterzero-design.md").is_file()
    assert (ROOT / "docs/superpowers/plans/2026-11-24-afterzero-foundation.md").is_file()

def test_core_logic_modules_exist():
    required = [
        "scripts/core/game_state.gd",
        "scripts/core/save_service.gd",
        "scripts/core/build_system.gd",
        "scripts/world/zone_state.gd",
        "scripts/world/pulse_core.gd",
        "tests/run_tests.gd",
        "scripts/main.gd",
        "scripts/player/player_controller.gd",
        "scripts/enemies/enemy_controller.gd",
        "scripts/world/resource_node.gd",
        "scripts/ui/hud.gd",
        "scripts/ui/touch_controls.gd",
        ".github/workflows/android-apk.yml",
        "export_presets.cfg",
    ]
    for relative_path in required:
        assert (ROOT / relative_path).is_file(), relative_path
