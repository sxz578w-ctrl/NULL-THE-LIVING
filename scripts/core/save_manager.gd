extends Node

const SAVE_PATH := "user://null_save_v1.json"
const DEFAULT_SETTINGS := {"reduced_motion":false,"sound_enabled":true,"haptics_enabled":false,"simplified_gestures":false,"high_contrast":false,"large_ui":false}
const DEFAULT_DATA := {"unlocked_mission":0,"completed_missions":[],"resonance":0,"discoveries":[],"species_memory":{"LUMA":[],"VEYL":[],"ECHO":[]},"best_survival":0,"best_daily":0,"daily_claimed":"","settings":DEFAULT_SETTINGS}
var data: Dictionary = {}

func _ready() -> void:
	load_data()

func load_data() -> void:
	data = DEFAULT_DATA.duplicate(true)
	if FileAccess.file_exists(SAVE_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if parsed is Dictionary:
			for key in DEFAULT_DATA.keys():
				if parsed.has(key):
					data[key] = parsed[key]
	_save_shape_repair()

func _save_shape_repair() -> void:
	data["unlocked_mission"] = clampi(int(data.get("unlocked_mission",0)),0,5)
	data["completed_missions"] = _sanitize_int_array(data.get("completed_missions",[]),0,5)
	var sequential_unlocked := 0
	for index in range(6):
		if data["completed_missions"].has(index):
			sequential_unlocked = mini(index + 1, 5)
		else:
			break
	data["unlocked_mission"] = sequential_unlocked
	data["resonance"] = maxi(0,int(data.get("resonance",0)))
	data["best_survival"] = maxi(0,int(data.get("best_survival",0)))
	data["best_daily"] = maxi(0,int(data.get("best_daily",0)))
	if not (data.get("daily_claimed","") is String):
		data["daily_claimed"] = ""
	var raw_discoveries: Variant = data.get("discoveries",[])
	var clean_discoveries: Array[Dictionary] = []
	if raw_discoveries is Array:
		for item in raw_discoveries:
			if item is Dictionary and str(item.get("id","")) != "":
				clean_discoveries.append(item.duplicate(true))
				if clean_discoveries.size() >= 300:
					break
	data["discoveries"] = clean_discoveries
	var raw_memory: Variant = data.get("species_memory",{})
	var clean_memory := {"LUMA":[],"VEYL":[],"ECHO":[]}
	if raw_memory is Dictionary:
		for species_id in clean_memory.keys():
			var items: Variant = raw_memory.get(species_id,[])
			if items is Array:
				var seen_ids: Array[String] = []
				for item in items:
					if item is Dictionary and str(item.get("id","")) != "":
						var memory_id := str(item.get("id",""))
						if not seen_ids.has(memory_id):
							seen_ids.append(memory_id)
							clean_memory[species_id].append(item.duplicate(true))
				while clean_memory[species_id].size() > 5:
					clean_memory[species_id].pop_front()
	data["species_memory"] = clean_memory
	var raw_settings: Variant = data.get("settings",{})
	var clean_settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
	if raw_settings is Dictionary:
		for key in DEFAULT_SETTINGS.keys():
			if raw_settings.has(key) and typeof(raw_settings[key]) == TYPE_BOOL:
				clean_settings[key] = raw_settings[key]
	data["settings"] = clean_settings

func _sanitize_int_array(value: Variant, minimum: int, maximum: int) -> Array[int]:
	var result: Array[int] = []
	if not (value is Array):
		return result
	for item in value:
		if typeof(item) == TYPE_INT or typeof(item) == TYPE_FLOAT:
			var number := int(item)
			if number >= minimum and number <= maximum and not result.has(number):
				result.append(number)
	return result

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file == null:
		push_error("NULL save: unable to open save file.")
		return
	file.store_string(JSON.stringify(data,"\t"))
	file.close()

func complete_mission(index: int,reward: int) -> void:
	if index < 0 or index > 5 or index > int(data.get("unlocked_mission",0)):
		return
	var completed: Array = data.get("completed_missions",[])
	if not completed.has(index):
		completed.append(index)
		data["resonance"] = int(data.get("resonance",0)) + maxi(0,reward)
	data["completed_missions"] = completed
	data["unlocked_mission"] = max(int(data.get("unlocked_mission",0)),min(index + 1,5))
	save_data()

func record_discovery(signature: Dictionary) -> bool:
	var discoveries: Array = data.get("discoveries",[])
	var signature_id := str(signature.get("id","unknown"))
	if signature_id == "unknown" or signature_id == "":
		return false
	for item in discoveries:
		if str(item.get("id","")) == signature_id:
			return false
	var entry := {"id":signature_id,"shape":str(signature.get("shape","tap")),"tempo":str(signature.get("tempo","single")),"direction":str(signature.get("direction","none")),"date":Time.get_date_string_from_system()}
	discoveries.append(entry)
	while discoveries.size() > 300:
		discoveries.pop_front()
	data["discoveries"] = discoveries
	save_data()
	return true

func remember_species(species_id: String,signature: Dictionary) -> int:
	if not data["species_memory"].has(species_id):
		return 0
	var memory: Array = data["species_memory"][species_id]
	var entry := {"id":str(signature.get("id","unknown")),"shape":str(signature.get("shape","tap")),"tempo":str(signature.get("tempo","single")),"direction":str(signature.get("direction","none"))}
	var already_known := false
	for existing in memory:
		if str(existing.get("id","")) == entry["id"]:
			already_known = true
			break
	if entry["id"] != "unknown" and not already_known:
		memory.append(entry)
		while memory.size() > 5:
			memory.pop_front()
	data["species_memory"][species_id] = memory
	save_data()
	return memory.size()

func record_survival(score: int) -> void:
	data["best_survival"] = max(int(data.get("best_survival",0)),maxi(0,score))
	save_data()

func record_daily(score: int) -> void:
	data["best_daily"] = max(int(data.get("best_daily",0)),maxi(0,score))
	data["daily_claimed"] = Time.get_date_string_from_system()
	save_data()

func get_setting(key: String,fallback: Variant = false) -> Variant:
	return data.get("settings",{}).get(key,fallback)

func set_setting(key: String,value: Variant) -> void:
	if not DEFAULT_SETTINGS.has(key) or typeof(value) != TYPE_BOOL:
		return
	var settings: Dictionary = data.get("settings",{})
	settings[key] = value
	data["settings"] = settings
	save_data()
