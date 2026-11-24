extends SceneTree

const TouchDNA = preload("res://scripts/core/touch_dna.gd")
const GameRules = preload("res://scripts/core/game_rules.gd")
const GameCatalog = preload("res://scripts/core/game_catalog.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_tap_classification()
	_test_swipe_classification()
	_test_loop_classification()
	_test_pulse_train_classification()
	_test_sequence_changes_touch_identity()
	_test_simplified_gestures_accept_small_loop()
	_test_campaign_first_mission()
	_test_transfer_requires_two_steps()
	_test_final_mission_sequence()
	_test_survival_loop_is_stronger()
	_test_survival_repetition_has_diminishing_returns()
	_test_catalog_has_six_missions()
	_test_low_confidence_rejected()
	_test_low_sample_curve_confidence()
	_test_noise_route_blocking_is_scoped()
	_test_hush_loop_accepts_tracking_shift()
	print("NULL TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + message)
	else:
		failed += 1
		push_error("FAIL: " + message)

func _test_tap_classification() -> void:
	var result := TouchDNA.classify([Vector2(0.5, 0.5)], 0.12, [], ["SEED"])
	_check(result["shape"] == "tap", "single point classifies as tap")

func _test_swipe_classification() -> void:
	var result := TouchDNA.classify([Vector2(0.2, 0.34), Vector2(0.79, 0.35)], 0.4, [], ["LUMA", "RELAY"])
	_check(result["shape"] == "swipe", "straight travel classifies as swipe")

func _test_loop_classification() -> void:
	var points := [Vector2(0.5, 0.30), Vector2(0.66, 0.47), Vector2(0.5, 0.64), Vector2(0.34, 0.47), Vector2(0.5, 0.30)]
	var result := TouchDNA.classify(points, 1.0, [], ["SEED"])
	_check(result["shape"] == "loop", "closed path classifies as loop")
	_check(result["loop_center"].distance_to(Vector2(0.5, 0.47)) < 0.02, "loop center is stable")

func _test_pulse_train_classification() -> void:
	var result := TouchDNA.classify([Vector2(0.78, 0.69)], 0.1, [0.31, 0.28], ["ECHO"])
	_check(result["tempo"] == "pulse_train", "three quick taps classify as pulse train")

func _test_sequence_changes_touch_identity() -> void:
	var points := [Vector2(0.2, 0.3), Vector2(0.8, 0.3)]
	var left_to_right := TouchDNA.classify(points, 0.3, [], ["LUMA", "RELAY"])
	var free_path := TouchDNA.classify(points, 0.3, [], [])
	_check(left_to_right["id"] != free_path["id"], "target sequence contributes to touch signature identity")

func _test_simplified_gestures_accept_small_loop() -> void:
	var points := [Vector2(0.5, 0.43), Vector2(0.54, 0.47), Vector2(0.5, 0.51), Vector2(0.46, 0.47), Vector2(0.5, 0.43)]
	var strict := TouchDNA.classify(points, 0.8, [], ["SEED"], false)
	var simplified := TouchDNA.classify(points, 0.8, [], ["SEED"], true)
	_check(strict["shape"] != "loop" and simplified["shape"] == "loop", "simplified gestures accept a smaller loop")

func _test_campaign_first_mission() -> void:
	var signature := {"shape": "swipe", "tempo": "single", "loop_center": Vector2.ZERO}
	var result := GameRules.apply_mission_gesture(0, {}, signature, "LUMA", "RELAY")
	_check(result["accepted"] and result["completed"], "first mission accepts LUMA-to-RELAY swipe")

func _test_transfer_requires_two_steps() -> void:
	var first := GameRules.apply_mission_gesture(3, {}, {"shape": "swipe", "tempo": "single", "loop_center": Vector2.ZERO}, "LUMA", "RELAY")
	_check(first["accepted"] and not first["completed"], "transfer arms after first step only")
	var second := GameRules.apply_mission_gesture(3, first["progress"], {"shape": "tap", "tempo": "single", "loop_center": Vector2.ZERO}, "ECHO", "ECHO")
	_check(second["completed"], "transfer completes only after ECHO tap")

func _test_final_mission_sequence() -> void:
	var progress := {}
	var path := GameRules.apply_mission_gesture(5, progress, {"shape": "swipe", "tempo": "single", "loop_center": Vector2.ZERO}, "LUMA", "RELAY")
	var orbit := GameRules.apply_mission_gesture(5, path["progress"], {"shape": "loop", "tempo": "single", "loop_center": Vector2(0.5, 0.47)}, "SEED", "SEED")
	var pulses := GameRules.apply_mission_gesture(5, orbit["progress"], {"shape": "tap", "tempo": "pulse_train", "loop_center": Vector2.ZERO}, "ECHO", "ECHO")
	_check(path["accepted"] and orbit["accepted"] and pulses["completed"], "final gate requires the full ordered sequence")

func _test_survival_loop_is_stronger() -> void:
	var loop_effect := GameRules.survival_effect({"shape": "loop", "tempo": "single"})
	var tap_effect := GameRules.survival_effect({"shape": "tap", "tempo": "single"})
	_check(loop_effect["score"] > tap_effect["score"] and loop_effect["danger_reduction"] > tap_effect["danger_reduction"], "loop has higher survival value than tap")

func _test_survival_repetition_has_diminishing_returns() -> void:
	var signature := {"shape": "loop", "tempo": "single"}
	var first := GameRules.survival_effect(signature, 0)
	var repeated := GameRules.survival_effect(signature, 3)
	_check(first["score"] > repeated["score"] and first["danger_reduction"] > repeated["danger_reduction"], "repeating the same survival signature loses effectiveness")

func _test_catalog_has_six_missions() -> void:
	_check(GameCatalog.MISSIONS.size() == 6, "campaign catalog contains six missions")

func _test_low_confidence_rejected() -> void:
	var signature := {"shape": "swipe", "tempo": "single", "loop_center": Vector2.ZERO, "confidence": "low"}
	var result := GameRules.apply_mission_gesture(0, {}, signature, "LUMA", "RELAY")
	_check(not result["accepted"] and not result["completed"], "low-confidence gestures cannot complete a mission")

func _test_noise_route_blocking_is_scoped() -> void:
	_check(GameRules.is_route_blocked(3, 70.0), "high noise blocks the route in late story stages")
	_check(not GameRules.is_route_blocked(1, 90.0), "early story stages do not receive route blocking")
	_check(not GameRules.is_route_blocked(4, 90.0), "HUSH trap stage remains completable under high noise")

func _test_low_sample_curve_confidence() -> void:
	var points := [Vector2(0.10, 0.10), Vector2(0.16, 0.16), Vector2(0.10, 0.16)]
	var result := TouchDNA.classify(points, 0.18, [], ["LUMA"])
	_check(result["shape"] == "curve" and result["confidence"] == "low", "short ambiguous curves receive low confidence")

func _test_hush_loop_accepts_tracking_shift() -> void:
	var progress := {"baited": true}
	var signature := {"shape": "loop", "tempo": "single", "loop_center": Vector2(0.5, 0.52)}
	var result := GameRules.apply_mission_gesture(4, progress, signature, "HUSH", "HUSH")
	_check(result["completed"], "HUSH loop remains completable after its visual tracking shift")
