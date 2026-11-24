extends SceneTree

func _initialize() -> void:
	var config_text := FileAccess.get_file_as_string("res://project.godot")
	if not config_text.contains('config/name="AFTERZERO"'):
		push_error("RED: project identity is still the old NULL project")
		quit(1)
		return

	if not config_text.contains('run/main_scene="res://scenes/main.tscn"'):
		push_error("RED: AFTERZERO main scene is not configured")
		quit(1)
		return

	print("PASS: AFTERZERO project identity and main scene configuration")
	quit(0)
