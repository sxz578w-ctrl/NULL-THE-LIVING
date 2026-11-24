extends CharacterBody3D

signal defeated(reward: int)

@export var max_health: float = 72.0
@export var move_speed: float = 2.1

var current_health: float = 72.0
var target: Node3D
var attack_timer: float = 0.0
var is_defeated: bool = false
var visual_root: Node3D
var damage_flash: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	_build_body()

func _part(parent: Node3D, part_name: String, mesh: PrimitiveMesh, position_value: Vector3, color: Color, emission: Color = Color.BLACK) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	visual.mesh = mesh
	visual.position = position_value
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.62
	material.roughness = 0.28
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
	visual.material_override = material
	parent.add_child(visual)
	return visual

func _build_body() -> void:
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.35
	shape_node.shape = capsule
	shape_node.position.y = 0.68
	add_child(shape_node)

	visual_root = Node3D.new()
	visual_root.name = "EnemyVisual"
	add_child(visual_root)

	var torso := BoxMesh.new()
	torso.size = Vector3(0.82, 0.92, 0.58)
	_part(visual_root, "EnemyArmor", torso, Vector3(0.0, 0.78, 0.0), Color(0.25, 0.12, 0.15))
	var chest := BoxMesh.new()
	chest.size = Vector3(0.56, 0.34, 0.18)
	_part(visual_root, "EnemyChestPlate", chest, Vector3(0.0, 0.88, -0.32), Color(0.57, 0.19, 0.18))
	var core := SphereMesh.new()
	core.radius = 0.16
	core.height = 0.32
	_part(visual_root, "EnemyCore", core, Vector3(0.0, 0.88, -0.43), Color(1.0, 0.32, 0.17), Color(0.95, 0.10, 0.025))
	var head := BoxMesh.new()
	head.size = Vector3(0.48, 0.42, 0.46)
	_part(visual_root, "EnemyHead", head, Vector3(0.0, 1.48, 0.0), Color(0.20, 0.23, 0.27))
	var eye := BoxMesh.new()
	eye.size = Vector3(0.32, 0.075, 0.06)
	_part(visual_root, "EnemyEye", eye, Vector3(0.0, 1.52, -0.25), Color(1.0, 0.24, 0.12), Color(0.9, 0.07, 0.02))
	var arm := BoxMesh.new()
	arm.size = Vector3(0.24, 0.72, 0.28)
	_part(visual_root, "EnemyLeftArm", arm, Vector3(-0.55, 0.72, 0.0), Color(0.28, 0.15, 0.17))
	_part(visual_root, "EnemyRightArm", arm, Vector3(0.55, 0.72, 0.0), Color(0.28, 0.15, 0.17))
	var leg := BoxMesh.new()
	leg.size = Vector3(0.27, 0.55, 0.32)
	_part(visual_root, "EnemyLeftLeg", leg, Vector3(-0.22, 0.20, 0.0), Color(0.12, 0.14, 0.18))
	_part(visual_root, "EnemyRightLeg", leg, Vector3(0.22, 0.20, 0.0), Color(0.12, 0.14, 0.18))

func apply_damage(amount: float) -> bool:
	if is_defeated or amount <= 0.0:
		return false
	current_health = maxf(0.0, current_health - amount)
	damage_flash = 0.12
	if current_health <= 0.0:
		is_defeated = true
		_spawn_death_burst()
		defeated.emit(8)
		queue_free()
		return true
	return false

func _spawn_death_burst() -> void:
	var burst := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.38
	mesh.height = 0.76
	burst.mesh = mesh
	burst.global_position = global_position + Vector3(0.0, 0.75, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.26, 0.12, 0.85)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.12, 0.025)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	burst.material_override = material
	var effect_parent: Node = get_tree().current_scene
	if effect_parent == null:
		effect_parent = get_parent()
	if effect_parent == null:
		burst.queue_free()
		return
	effect_parent.add_child(burst)
	var tween := create_tween()
	tween.tween_property(burst, "scale", Vector3(3.0, 3.0, 3.0), 0.22)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.22)
	tween.tween_callback(burst.queue_free)

func _physics_process(delta: float) -> void:
	if is_defeated or not is_instance_valid(target):
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	damage_flash = maxf(0.0, damage_flash - delta)
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()

	if distance > 1.45:
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

	if visual_root != null:
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.025
		visual_root.scale = Vector3.ONE * pulse
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
