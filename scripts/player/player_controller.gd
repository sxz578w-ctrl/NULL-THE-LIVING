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

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	_build_body()

func _build_body() -> void:
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.45
	shape_node.shape = capsule
	shape_node.position.y = 0.72
	add_child(shape_node)

	var visual := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.38
	mesh.height = 1.35
	visual.mesh = mesh
	visual.position.y = 0.72
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.22, 0.82, 0.77)
	material.metallic = 0.25
	material.roughness = 0.36
	visual.material_override = material
	add_child(visual)

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
	var nearest_distance := 2.3
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

func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		player_died.emit()
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
