extends Node3D

const PlayerScript = preload("res://scripts/player/player_controller.gd")
const EnemyScript = preload("res://scripts/enemies/enemy_controller.gd")
const ResourceNodeScript = preload("res://scripts/world/resource_node.gd")
const PulseCoreScript = preload("res://scripts/world/pulse_core.gd")
const TouchControlsScript = preload("res://scripts/ui/touch_controls.gd")
const HUDScript = preload("res://scripts/ui/hud.gd")

var player
var camera: Camera3D
var route_gate_collision: CollisionShape3D
var route_gate_visual: MeshInstance3D
var touch_controls
var hud
var pulse_core = PulseCoreScript.new()
var pylon_nodes: Dictionary = {}
var build_slots: Dictionary = {}
var zone_rng := RandomNumberGenerator.new()
var last_message: String = ""
var game_is_ready: bool = false

func _ready() -> void:
	zone_rng.seed = 24112026
	_create_environment()
	_create_world()
	_create_route_gate()
	_create_player()
	_create_resources()
	_create_pylons()
	_create_build_slots()
	_create_enemy(Vector3(12.0, 0.0, -5.0))
	_create_enemy(Vector3(-13.0, 0.0, -9.0))
	_create_camera()
	_create_hud()
	_load_progress()
	game_is_ready = true
	_update_hud()
	_show_message("استكشف المنطقة. اجمع الخردة، ثم فعّل الموصلات الثلاثة.")

func _create_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.012, 0.035, 0.065)
	sky_material.sky_horizon_color = Color(0.11, 0.20, 0.23)
	sky_material.ground_bottom_color = Color(0.012, 0.025, 0.035)
	sky_material.ground_horizon_color = Color(0.07, 0.13, 0.15)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.48, 0.66, 0.72)
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_color = Color(0.70, 0.86, 0.91)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 42.0
	add_child(sun)

	var key_light := OmniLight3D.new()
	key_light.position = Vector3(0.0, 8.0, 0.0)
	key_light.light_color = Color(0.12, 0.82, 0.85)
	key_light.light_energy = 1.8
	key_light.omni_range = 19.0
	add_child(key_light)

func _create_ruin(parent: Node3D, origin: Vector3, scale_factor: float, tint: Color) -> void:
	var ruin := Node3D.new()
	ruin.position = origin
	parent.add_child(ruin)
	var wall_height := 2.8 * scale_factor
	_create_box(ruin, "RuinWall", Vector3.ZERO, Vector3(4.8, wall_height, 0.55) * scale_factor, tint, Color(0.025, 0.06, 0.075))
	_create_box(ruin, "RuinBrokenTop", Vector3(-1.55 * scale_factor, wall_height * 0.56, 0.0), Vector3(1.1, 0.55, 0.8) * scale_factor, tint.lightened(0.13))
	_create_box(ruin, "RuinSupport", Vector3(2.0 * scale_factor, -0.05, 0.0), Vector3(0.55, wall_height + 0.5, 0.8) * scale_factor, tint.darkened(0.18))
	_create_box(ruin, "RuinLight", Vector3(0.0, 0.15 * scale_factor, 0.31 * scale_factor), Vector3(2.0, 0.07, 0.06) * scale_factor, Color(0.12, 0.68, 0.72), Color(0.06, 0.55, 0.62))

func _create_world() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "ZoneFloor"
	add_child(floor_body)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(52.0, 0.6, 42.0)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.3
	floor_body.add_child(floor_shape)
	_create_box(floor_body, "Ground", Vector3(0.0, -0.3, 0.0), Vector3(52.0, 0.6, 42.0), Color(0.055, 0.095, 0.11))

	var floor_material := _material(Color(0.075, 0.12, 0.14))
	for x in range(-24, 25, 4):
		for z in range(-18, 19, 4):
			var tile := MeshInstance3D.new()
			var tile_mesh := BoxMesh.new()
			tile_mesh.size = Vector3(3.92, 0.035, 3.92)
			tile.mesh = tile_mesh
			tile.position = Vector3(float(x), 0.025, float(z))
			tile.material_override = floor_material
			floor_body.add_child(tile)

	for x in range(-24, 25, 4):
		_create_box(self, "FloorGuide_%d" % x, Vector3(float(x), 0.055, 0.0), Vector3(0.035, 0.025, 37.0), Color(0.11, 0.24, 0.26), Color(0.015, 0.10, 0.12))

	for wall_data in [
		[Vector3(0.0, 1.3, -21.0), Vector3(52.0, 2.6, 0.8)],
		[Vector3(0.0, 1.3, 21.0), Vector3(52.0, 2.6, 0.8)],
		[Vector3(-26.0, 1.3, 0.0), Vector3(0.8, 2.6, 42.0)],
		[Vector3(26.0, 1.3, 0.0), Vector3(0.8, 2.6, 42.0)]
	]:
		var barrier := StaticBody3D.new()
		barrier.position = wall_data[0]
		add_child(barrier)
		var barrier_shape := CollisionShape3D.new()
		var barrier_box := BoxShape3D.new()
		barrier_box.size = wall_data[1]
		barrier_shape.shape = barrier_box
		barrier.add_child(barrier_shape)
		_create_box(barrier, "PerimeterWall", Vector3.ZERO, wall_data[1], Color(0.055, 0.105, 0.12))
		_create_box(barrier, "PerimeterLight", Vector3(0.0, 0.0, 0.42), Vector3(wall_data[1].x, 0.055, 0.04), Color(0.12, 0.65, 0.7), Color(0.04, 0.42, 0.48))

	_create_box(self, "BasePlatform", Vector3(0.0, 0.08, 0.0), Vector3(10.0, 0.3, 9.0), Color(0.12, 0.20, 0.23))
	_create_box(self, "BaseCoreHousing", Vector3(0.0, 1.2, -1.0), Vector3(3.4, 2.4, 3.4), Color(0.09, 0.17, 0.21))
	_create_box(self, "BaseCore", Vector3(0.0, 2.55, -1.0), Vector3(1.55, 1.55, 1.55), Color(0.08, 0.28, 0.33), Color(0.06, 0.78, 0.82))
	_create_box(self, "CoreCrown", Vector3(0.0, 3.48, -1.0), Vector3(0.85, 0.12, 0.85), Color(0.30, 0.95, 0.91), Color(0.25, 0.85, 0.82))

	for pillar_position in [Vector3(-4.5, 0.0, -4.0), Vector3(4.5, 0.0, -4.0), Vector3(-4.5, 0.0, 4.0), Vector3(4.5, 0.0, 4.0)]:
		var pillar := _create_box(self, "BasePillar", pillar_position + Vector3(0.0, 1.5, 0.0), Vector3(0.55, 3.0, 0.55), Color(0.12, 0.25, 0.29))
		pillar.rotation.y = 0.2

	for ruin_data in [
		[Vector3(-19.0, 1.2, -13.0), 1.2, Color(0.12, 0.19, 0.22)],
		[Vector3(19.0, 1.2, -13.0), 1.05, Color(0.11, 0.17, 0.21)],
		[Vector3(-20.0, 1.2, 11.0), 0.9, Color(0.14, 0.19, 0.22)],
		[Vector3(20.0, 1.2, 12.0), 1.15, Color(0.12, 0.18, 0.22)],
		[Vector3(-8.0, 1.2, -17.0), 0.7, Color(0.13, 0.20, 0.23)],
		[Vector3(9.0, 1.2, 16.0), 0.75, Color(0.13, 0.20, 0.23)]
	]:
		_create_ruin(self, ruin_data[0], float(ruin_data[1]), ruin_data[2])

	for index in range(18):
		var x := zone_rng.randf_range(-22.0, 22.0)
		var z := zone_rng.randf_range(-18.0, 18.0)
		if Vector2(x, z).length() < 8.0:
			continue
		var height := zone_rng.randf_range(0.35, 0.9)
		var width := zone_rng.randf_range(0.7, 1.5)
		var rock := _create_box(self, "CoverDebris_%02d" % index, Vector3(x, height * 0.5, z), Vector3(width, height, width * 1.25), Color(0.10, 0.16, 0.19))
		rock.rotation.y = zone_rng.randf_range(-PI, PI)


func _material(color: Color, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
	return material

func _create_box(parent: Node3D, name_value: String, position_value: Vector3, size: Vector3, color: Color, emission: Color = Color.BLACK) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = name_value
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position_value
	visual.material_override = _material(color, emission)
	parent.add_child(visual)
	return visual

func _create_route_gate() -> void:
	var gate := StaticBody3D.new()
	gate.name = "RefractedRouteGate"
	gate.position = Vector3(0.0, 0.0, -18.0)
	add_child(gate)

	route_gate_collision = CollisionShape3D.new()
	var gate_shape := BoxShape3D.new()
	gate_shape.size = Vector3(4.4, 2.8, 0.65)
	route_gate_collision.shape = gate_shape
	route_gate_collision.position.y = 1.4
	gate.add_child(route_gate_collision)

	route_gate_visual = _create_box(gate, "SealedGate", Vector3(0.0, 1.4, 0.0), Vector3(4.4, 2.8, 0.65), Color(0.08, 0.2, 0.23), Color(0.02, 0.12, 0.15))
	_create_box(gate, "GateLeftPillar", Vector3(-2.35, 1.5, 0.0), Vector3(0.35, 3.0, 0.5), Color(0.18, 0.53, 0.54), Color(0.05, 0.3, 0.31))
	_create_box(gate, "GateRightPillar", Vector3(2.35, 1.5, 0.0), Vector3(0.35, 3.0, 0.5), Color(0.18, 0.53, 0.54), Color(0.05, 0.3, 0.31))
	_create_box(gate, "GateLintel", Vector3(0.0, 2.95, 0.0), Vector3(5.0, 0.35, 0.5), Color(0.18, 0.53, 0.54), Color(0.05, 0.3, 0.31))

func _apply_zone_visuals() -> void:
	if route_gate_collision == null or route_gate_visual == null:
		return
	var open := bool(ZoneState.route_open)
	route_gate_collision.disabled = open
	route_gate_visual.visible = not open

func _create_player() -> void:
	player = PlayerScript.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.9, 5.0)
	add_child(player)
	player.health_changed.connect(_on_health_changed)
	player.player_died.connect(func() -> void: _show_message("أُعيدت طاقتك عند القاعدة."))

func _create_resources() -> void:
	var entries := [
		[Vector3(-7.0, 0.8, 3.0), "scrap", 7],
		[Vector3(8.0, 0.8, 5.0), "scrap", 8],
		[Vector3(-12.0, 0.8, -4.0), "flux", 3],
		[Vector3(15.0, 0.8, 8.0), "scrap", 9],
		[Vector3(5.0, 0.8, -12.0), "echo", 2],
		[Vector3(-17.0, 0.8, 8.0), "flux", 3],
		[Vector3(0.0, 0.8, -19.2), "echo", 4]
	]
	for entry in entries:
		var node = ResourceNodeScript.new()
		node.resource_id = str(entry[1])
		node.amount = int(entry[2])
		node.position = entry[0]
		add_child(node)

func _create_pylons() -> void:
	var positions := {
		"ember": Vector3(-13.0, 0.0, -12.0),
		"tide": Vector3(0.0, 0.0, -15.0),
		"void": Vector3(13.0, 0.0, -12.0)
	}
	for pylon_id: Variant in positions.keys():
		var pylon := Node3D.new()
		pylon.name = "Pylon_" + str(pylon_id)
		pylon.position = positions[pylon_id]
		pylon.add_to_group("pylons")
		pylon.set_meta("pylon_id", str(pylon_id))
		add_child(pylon)
		var visual := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.45
		mesh.bottom_radius = 0.7
		mesh.height = 2.2
		visual.mesh = mesh
		visual.position.y = 1.1
		visual.material_override = _material(Color(0.14, 0.32, 0.35), Color(0.04, 0.22, 0.26))
		pylon.add_child(visual)
		_create_box(pylon, "PylonRune", Vector3(0.0, 2.25, 0.0), Vector3(0.5, 0.12, 0.5), Color(0.25, 0.86, 0.82), Color(0.2, 0.75, 0.72))
		pylon_nodes[str(pylon_id)] = pylon

func _create_build_slots() -> void:
	var data := {
		"north": Vector3(-3.2, 0.0, -1.0),
		"east": Vector3(3.2, 0.0, -1.0),
		"south": Vector3(0.0, 0.0, 3.0)
	}
	for slot_id: Variant in data.keys():
		var pad := Node3D.new()
		pad.name = "BuildSlot_" + str(slot_id)
		pad.position = data[slot_id]
		pad.add_to_group("build_slots")
		pad.set_meta("slot_id", str(slot_id))
		add_child(pad)
		var visual := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.95
		mesh.bottom_radius = 0.95
		mesh.height = 0.16
		visual.mesh = mesh
		visual.position.y = 0.12
		visual.material_override = _material(Color(0.19, 0.31, 0.32), Color(0.025, 0.18, 0.18))
		pad.add_child(visual)
		build_slots[str(slot_id)] = pad

func _create_enemy(at_position: Vector3) -> void:
	var enemy = EnemyScript.new()
	enemy.position = at_position + Vector3(0.0, 0.75, 0.0)
	add_child(enemy)
	enemy.target = player
	enemy.defeated.connect(_on_enemy_defeated)

func _create_camera() -> void:
	camera = Camera3D.new()
	camera.name = "WorldCamera"
	camera.position = Vector3(0.0, 18.5, 15.5)
	camera.rotation_degrees.x = -49.0
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 56.0
	camera.near = 0.1
	camera.far = 90.0
	camera.current = true
	add_child(camera)

func _create_hud() -> void:
	touch_controls = TouchControlsScript.new()
	add_child(touch_controls)
	touch_controls.movement_changed.connect(_on_move_input)
	touch_controls.attack_pressed.connect(_on_attack)
	touch_controls.dash_pressed.connect(_on_dash)
	touch_controls.interact_pressed.connect(_on_interact)
	touch_controls.pause_pressed.connect(_on_pause)

	hud = HUDScript.new()
	add_child(hud)
	hud.pulse_choice_requested.connect(_on_pulse_choice)
	hud.build_requested.connect(_on_build_requested)
	hud.pause_toggled.connect(_on_pause_toggled)
	hud.language_changed.connect(_on_language_changed)
	touch_controls.set_language("ar")

func _on_move_input(value: Vector2) -> void:
	if is_instance_valid(player):
		player.set_move_intent(value)

func _on_attack() -> void:
	if is_instance_valid(player):
		player.request_attack()

func _on_dash() -> void:
	if is_instance_valid(player):
		player.request_dash()

func _on_interact() -> void:
	if not game_is_ready or not is_instance_valid(player):
		return
	if pulse_core.is_ready():
		hud.show_pulse_choices(true)
		_show_message("اختر نتيجة النبضة. سيبقى أثرها في المنطقة.")
		return

	var nearest: Node3D = null
	var nearest_distance := 3.2
	var nearest_kind := ""
	for resource: Node in get_tree().get_nodes_in_group("resource_nodes"):
		if resource is Node3D:
			var distance: float = player.global_position.distance_to((resource as Node3D).global_position)
			if distance < nearest_distance:
				nearest = resource as Node3D
				nearest_distance = distance
				nearest_kind = "resource"
	for pylon: Node in get_tree().get_nodes_in_group("pylons"):
		if pylon is Node3D:
			var distance: float = player.global_position.distance_to((pylon as Node3D).global_position)
			if distance < nearest_distance:
				nearest = pylon as Node3D
				nearest_distance = distance
				nearest_kind = "pylon"
	for slot: Node in get_tree().get_nodes_in_group("build_slots"):
		if slot is Node3D:
			var distance: float = player.global_position.distance_to((slot as Node3D).global_position)
			if distance < nearest_distance:
				nearest = slot as Node3D
				nearest_distance = distance
				nearest_kind = "build"

	if nearest == null:
		_show_message("اقترب أكثر من مورد أو موصل أو منصة بناء.")
		return

	match nearest_kind:
		"resource":
			var collected: bool = nearest.call("collect", GameState, ZoneState.resource_multiplier)
			_show_message("تم جمع المورد." if collected else "هذا المورد جُمع مسبقاً.")
			_update_hud()
			_save_progress()
		"pylon":
			var pylon_id := str(nearest.get_meta("pylon_id", ""))
			var activated: bool = pulse_core.activate_node(pylon_id)
			if activated:
				nearest.visible = false
				_show_message("الموصل %d/3 متصل." % pulse_core.progress)
			else:
				_show_message("ترتيب الموصلات غير صحيح؛ ابدأ من EMBER.")
			_update_hud()
		"build":
			var slot_id := str(nearest.get_meta("slot_id", ""))
			if BuildSystem.built_slots.has(slot_id):
				_show_message("هذه المنصة مشغولة بالفعل.")
			else:
				hud.show_build_choices(slot_id)

func _on_pulse_choice(choice: String) -> void:
	if pulse_core.resolve(choice, ZoneState, GameState):
		if BuildSystem.has_building("extractor"):
			GameState.add_resource("scrap", 6)
		if BuildSystem.has_building("relay"):
			ZoneState.stability = mini(100, ZoneState.stability + 10)
		if BuildSystem.has_building("turret"):
			ZoneState.danger = maxi(0, ZoneState.danger - 6)
		for pylon: Node3D in pylon_nodes.values():
			pylon.visible = false
		if choice == "harvest":
			_create_enemy(Vector3(-19.0, 0.0, 4.0))
		if choice == "anchor":
			for enemy: Node in get_tree().get_nodes_in_group("enemies"):
				enemy.set("move_speed", 1.55)
		_apply_zone_visuals()
		_show_message("تم تطبيق %s. حالة المنطقة تغيرت." % choice.to_upper())
		_save_progress()
	else:
		_show_message("تعذر تطبيق النبضة. تحقق من حالة النواة.")
	_update_hud()

func _on_build_requested(slot_id: String, building_type: String) -> void:
	if not BuildSystem.try_build(slot_id, building_type, GameState):
		_show_message("الموارد غير كافية أو المنصة غير صالحة.")
		return
	_create_building_visual(slot_id, building_type)
	_show_message("اكتمل البناء: " + building_type.to_upper())
	_save_progress()
	_update_hud()

func _create_building_visual(slot_id: String, building_type: String) -> void:
	if not build_slots.has(slot_id):
		return
	var pad: Node3D = build_slots[slot_id]
	var color := Color(0.28, 0.65, 0.55)
	match building_type:
		"extractor":
			color = Color(0.86, 0.58, 0.23)
		"relay":
			color = Color(0.24, 0.76, 0.82)
		"turret":
			color = Color(0.76, 0.31, 0.27)
	var building := _create_box(pad, "Building_" + building_type, Vector3(0.0, 1.05, 0.0), Vector3(1.25, 1.9, 1.25), color)
	building.rotation.y = 0.18

func _on_enemy_defeated(reward: int) -> void:
	GameState.add_resource("scrap", reward)
	_show_message("هُزم الكائن. +%d خردة" % reward)
	_update_hud()
	_save_progress()

func _on_health_changed(_current: float, _maximum: float) -> void:
	_update_hud()

func _on_pause() -> void:
	hud.toggle_pause()

func _on_pause_toggled(_value: bool) -> void:
	pass

func _on_language_changed(language: String) -> void:
	if is_instance_valid(touch_controls):
		touch_controls.set_language(language)

func _update_hud() -> void:
	if is_instance_valid(hud) and is_instance_valid(player):
		hud.update_stats(GameState.snapshot(), player.current_health, ZoneState, pulse_core.progress)

func _show_message(message: String) -> void:
	last_message = message
	if is_instance_valid(hud):
		hud.show_message(message)

func _load_progress() -> void:
	var data: Dictionary = SaveService.load_data()
	GameState.replace_resources(data["resources"])
	ZoneState.load_snapshot(data["zone_state"])
	BuildSystem.load_snapshot(data["base_buildings"])
	if ZoneState.pulse_count > 0:
		pulse_core.resolved = true
		pulse_core.progress = 3
		for pylon: Node3D in pylon_nodes.values():
			pylon.visible = false
	for slot_id: Variant in BuildSystem.built_slots.keys():
		_create_building_visual(str(slot_id), str(BuildSystem.built_slots[slot_id]))
	_apply_zone_visuals()

func _save_progress() -> void:
	var data: Dictionary = SaveService.default_data()
	data["resources"] = GameState.snapshot()
	data["zone_state"] = ZoneState.snapshot()
	data["base_buildings"] = BuildSystem.snapshot()
	data["last_pulse_choice"] = ZoneState.last_choice
	SaveService.save(data)

func _process(delta: float) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):
		return
	var target_position: Vector3 = player.global_position + Vector3(0.0, 20.0, 16.0)
	camera.global_position = camera.global_position.lerp(target_position, clampf(delta * 5.0, 0.0, 1.0))
	camera.look_at(player.global_position, Vector3.UP)
	_update_hud()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_progress()
