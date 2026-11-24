extends Node

const SAVE_PATH := "user://afterzero_save_v1.json"
const SCHEMA_VERSION := 1

func default_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"resources": {"scrap": 30, "flux": 8, "echo": 0},
		"zone_state": {
			"stability": 45,
			"danger": 55,
			"route_open": false,
			"pulse_count": 0,
			"resource_multiplier": 1.0,
			"last_choice": "none",
			"applied_activations": {}
		},
		"base_buildings": [],
		"last_pulse_choice": "none"
	}

func validate(data: Dictionary) -> bool:
	if typeof(data.get("schema_version")) != TYPE_INT or int(data["schema_version"]) != SCHEMA_VERSION:
		return false
	if typeof(data.get("resources")) != TYPE_DICTIONARY or typeof(data.get("zone_state")) != TYPE_DICTIONARY:
		return false
	var resources: Dictionary = data["resources"]
	for key in ["scrap", "flux", "echo"]:
		if typeof(resources.get(key)) != TYPE_INT or int(resources[key]) < 0:
			return false
	var zone: Dictionary = data["zone_state"]
	for key in ["stability", "danger", "pulse_count"]:
		if typeof(zone.get(key)) != TYPE_INT:
			return false
	if int(zone["stability"]) < 0 or int(zone["stability"]) > 100:
		return false
	if int(zone["danger"]) < 0 or int(zone["danger"]) > 100 or int(zone["pulse_count"]) < 0:
		return false
	if typeof(zone.get("route_open")) != TYPE_BOOL:
		return false
	if typeof(data.get("base_buildings")) != TYPE_ARRAY:
		return false
	for building: Variant in data["base_buildings"]:
		if typeof(building) != TYPE_DICTIONARY or not building.has("slot_id") or not building.has("building_type"):
			return false
	if not ["none", "anchor", "harvest", "refract"].has(str(data.get("last_pulse_choice", "none"))):
		return false
	return true

func save(data: Dictionary, path: String = SAVE_PATH) -> bool:
	if not validate(data):
		return false
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var absolute_temp := ProjectSettings.globalize_path(temporary_path)
	var absolute_target := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		if DirAccess.remove_absolute(absolute_target) != OK:
			DirAccess.remove_absolute(absolute_temp)
			return false
	return DirAccess.rename_absolute(absolute_temp, absolute_target) == OK

func load_data(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return default_data()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return default_data()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_data()
	var data: Dictionary = parsed
	if not validate(data):
		return default_data()
	return data.duplicate(true)

func delete_save(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
