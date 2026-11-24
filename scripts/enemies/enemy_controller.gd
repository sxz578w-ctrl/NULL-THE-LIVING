extends CharacterBody3D

signal defeated(reward: int)

@export var max_health: float = 72.0
@export var move_speed: float = 2.1

var current_health: float = 72.0
var target: Node3D
var attack_timer: float = 0.0
var is_defeated: bool = false

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	_build_body()

func _build_body() -> void:
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.1
	shape_node.shape = capsule
	shape_node.position.y = 0.55
	add_child(shape_node)

	var visual := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.44
	mesh.height = 1.0
	visual.mesh = mesh
	visual.position.y = 0.55
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.86, 0.29, 0.23)
	material.emission_enabled = true
	material.emission = Color(0.22, 0.035, 0.02)
	visual.material_override = material
	add_child(visual)

func apply_damage(amount: float) -> bool:
	if is_defeated or amount <= 0.0:
		return false
	current_health = maxf(0.0, current_health - amount)
	if current_health <= 0.0:
		is_defeated = true
		defeated.emit(8)
		queue_free()
		return true
	return false

func _physics_process(delta: float) -> void:
	if is_defeated or not is_instance_valid(target):
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()

	if distance > 1.35:
		var direction := offset.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		rotation.y = atan2(direction.x, direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		if attack_timer <= 0.0 and target.has_method("take_damage"):
			target.call("take_damage", 8.0)
			attack_timer = 1.25

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
