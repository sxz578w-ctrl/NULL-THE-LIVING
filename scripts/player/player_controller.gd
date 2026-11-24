extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal player_died

@export var move_speed: float = 5.2
@export var max_health: float = 100.0

var current_health: float = 100.0
var move_intent: Vector2 = Vector2.ZERO
var dash_cooldown: float = 0.0
var dash_time: float = 0.0
var attack_cooldown: float = 0.0
var facing: Vector3 = Vector3.FORWARD
var spawn_position: Vector3 = Vector3.ZERO
var visual_root: Node3D

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	spawn_position = global_position
	_build_body()

func _part(parent: Node3D, part_name: String, mesh: PrimitiveMesh, position_value: Vector3, color: Color, emission: Color = Color.BLACK) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	visual.mesh = mesh
	visual.position = position_value
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.48
	material.roughness = 0.31
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
	visual.material_override = material
	parent.add_child(visual)
	return visual

func _build_body() -> void:
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.55
	shape_node.shape = capsule
	shape_node.position.y = 0.78
	add_child(shape_node)

	visual_root = Node3D.new()
	visual_root.name = "PlayerVisual"
	add_child(visual_root)

	var torso := CapsuleMesh.new()
	torso.radius = 0.34
	torso.height = 1.12
	_part(visual_root, "PlayerArmor", torso, Vector3(0.0, 0.88, 0.0), Color(0.10, 0.28, 0.34))
	var chest := BoxMesh.new()
	chest.size = Vector3(0.48, 0.46, 0.18)
	_part(visual_root, "ChestPlate", chest, Vector3(0.0, 1.02, -0.27), Color(0.20, 0.49, 0.54))
	var core := SphereMesh.new()
	core.radius = 0.17
	core.height = 0.34
	_part(visual_root, "PlayerCore", core, Vector3(0.0, 1.04, -0.39), Color(0.25, 0.95, 0.91), Color(0.10, 0.78, 0.74))
	var head := SphereMesh.new()
	head.radius = 0.25
	head.height = 0.48
	_part(visual_root, "PlayerHead", head, Vector3(0.0, 1.62, 0.0), Color(0.17, 0.34, 0.39))
	var visor := BoxMesh.new()
	visor.size = Vector3(0.32, 0.10, 0.08)
	_part(visual_root, "PlayerVisor", visor, Vector3(0.0, 1.66, -0.22), Color(0.15, 0.91, 1.0), Color(0.08, 0.62, 0.92))
	var shoulder := SphereMesh.new()
	shoulder.radius = 0.19
	shoulder.height = 0.34
	_part(visual_root, "LeftShoulder", shoulder, Vector3(-0.42, 1.18, 0.0), Color(0.12, 0.42, 0.49))
	_part(visual_root, "RightShoulder", shoulder, Vector3(0.42, 1.18, 0.0), Color(0.12, 0.42, 0.49))
	var arm := CapsuleMesh.new()
	arm.radius = 0.105
	arm.height = 0.62
	_part(visual_root, "LeftArm", arm, Vector3(-0.46, 0.78, -0.02), Color(0.08, 0.21, 0.27))
	_part(visual_root, "RightArm", arm, Vector3(0.46, 0.78, -0.02), Color(0.08, 0.21, 0.27))
	var leg := CapsuleMesh.new()
	leg.radius = 0.13
	leg.height = 0.56
	_part(visual_root, "LeftLeg", leg, Vector3(-0.19, 0.27, 0.0), Color(0.055, 0.13, 0.18))
	_part(visual_root, "RightLeg", leg, Vector3(0.19, 0.27, 0.0), Color(0.055, 0.13, 0.18))

func set_move_intent(value: Vector2) -> void:
	move_intent = value.limit_length(1.0)

func request_dash() -> void:
	if dash_cooldown <= 0.0:
		dash_time = 0.16
		dash_cooldown = 1.0

func request_attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.42
	var nearest: Node3D = null
	var nearest_distance := 2.8
	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or not (candidate is Node3D):
			continue
		var enemy := candidate as Node3D
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	if nearest != null and nearest.has_method("apply_damage"):
		nearest.call("apply_damage", 36.0)
		_spawn_hit_flash(nearest.global_position)

func _spawn_hit_flash(at_position: Vector3) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var flash := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.34
	mesh.height = 0.68
	flash.mesh = mesh
	flash.global_position = at_position + Vector3(0.0, 0.7, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.30, 0.94, 1.0, 0.8)
	material.emission_enabled = true
	material.emission = Color(0.15, 0.8, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = material
	scene.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector3(2.4, 2.4, 2.4), 0.16)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.16)
	tween.tween_callback(flash.queue_free)

func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		player_died.emit()
		global_position = spawn_position
		velocity = Vector3.ZERO
		current_health = max_health
		health_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dash_time = maxf(0.0, dash_time - delta)

	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input_vector := keyboard if keyboard.length() > 0.1 else move_intent
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
		rotation.y = atan2(facing.x, facing.z)

	var speed := move_speed * (2.3 if dash_time > 0.0 else 1.0)
	if direction.length() > 0.05:
		velocity.x = direction.normalized().x * speed
		velocity.z = direction.normalized().z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
