extends SceneTree

const GameStateScript = preload("res://scripts/core/game_state.gd")
const ZoneStateScript = preload("res://scripts/world/zone_state.gd")
const SaveServiceScript = preload("res://scripts/core/save_service.gd")
const BuildSystemScript = preload("res://scripts/core/build_system.gd")
const PulseCoreScript = preload("res://scripts/world/pulse_core.gd")

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _run() -> void:
	var config_text := FileAccess.get_file_as_string("res://project.godot")
	_check(config_text.contains('config/name="AFTERZERO"'), "project identity is AFTERZERO")
	_check(config_text.contains('run/main_scene="res://scenes/main.tscn"'), "main scene is configured")

	var state = GameStateScript.new()
	root.add_child(state)
	_check(state.add_resource("scrap", 10), "known resource can be added")
	_check(not state.add_resource("credits", 10), "unknown resource is rejected")
	_check(not state.add_resource("flux", 0), "zero resource is rejected")
	_check(not state.add_resource("echo", -1), "negative resource is rejected")
	_check(state.spend_resources({"scrap": 5, "flux": 2}), "multi-resource cost is spent atomically")
	var before: Dictionary = state.snapshot()
	_check(not state.spend_resources({"scrap": 999, "flux": 1}), "insufficient cost is rejected")
	_check(state.snapshot() == before, "failed cost does not partially spend")

	var zone = ZoneStateScript.new()
	root.add_child(zone)
	var initial_danger: int = zone.danger
	_check(zone.apply_pulse("anchor", "test-activation"), "anchor pulse applies once")
	_check(zone.danger < initial_danger, "anchor reduces danger")
	_check(not zone.apply_pulse("harvest", "test-activation"), "activation cannot be reused")
	_check(not zone.apply_pulse("unknown", "other-activation"), "unknown choice is rejected")

	var puzzle = PulseCoreScript.new()
	_check(not puzzle.resolve("anchor", zone, state), "puzzle cannot resolve before completion")
	_check(puzzle.activate_node("ember"), "first pylon is accepted")
	_check(not puzzle.activate_node("void"), "wrong pylon order is rejected")
	_check(puzzle.progress == 0, "wrong pylon resets the sequence")
	_check(puzzle.activate_node("ember"), "sequence can restart")
	_check(puzzle.activate_node("tide"), "second pylon is accepted")
	_check(puzzle.activate_node("void"), "third pylon is accepted")
	_check(puzzle.resolve("refract", zone, state), "completed puzzle resolves")
	_check(not puzzle.resolve("harvest", zone, state), "resolved puzzle cannot award twice")
	_check(zone.route_open, "refract opens the route")

	var build_system = BuildSystemScript.new()
	root.add_child(build_system)
	_check(build_system.try_build("north", "extractor", state), "extractor builds with resources")
	var after_build: Dictionary = state.snapshot()
	_check(not build_system.try_build("north", "turret", state), "occupied slot rejects another building")
	_check(state.snapshot() == after_build, "occupied slot does not spend resources")
	_check(not build_system.try_build("west", "relay", state), "unknown slot is rejected")
	_check(not build_system.try_build("east", "unknown", state), "unknown building is rejected")

	var save_service = SaveServiceScript.new()
	root.add_child(save_service)
	var save_data: Dictionary = save_service.default_data()
	_check(save_service.validate(save_data), "default save passes schema validation")
	_check(not save_service.validate({"schema_version": 99}), "unknown schema is rejected")
	var bad_data: Dictionary = save_data.duplicate(true)
	bad_data["resources"]["scrap"] = -4
	_check(not save_service.validate(bad_data), "negative saved resources are rejected")
	var test_path := "user://afterzero_ci_test.json"
	_check(save_service.save(save_data, test_path), "valid save is written")
	var loaded: Dictionary = save_service.load_data(test_path)
	_check(int(loaded.get("schema_version", -1)) == 1, "saved data round-trips")
	_check(save_service.delete_save(test_path), "test save is removed")

	print("AFTERZERO TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
