extends Area3D

@export var resource_id: String = "scrap"
@export var amount: int = 6

var collected: bool = false

func _ready() -> void:
	add_to_group("resource_nodes")
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	collision.shape = sphere
	add_child(collision)

	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 1.1
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.24, 0.78, 0.78)
	material.emission_enabled = true
	material.emission = Color(0.05, 0.38, 0.4)
	visual.material_override = material
	add_child(visual)

func collect(state: Node, multiplier: float = 1.0) -> bool:
	if collected or amount <= 0:
		return false
	var reward := maxi(1, roundi(float(amount) * clampf(multiplier, 0.5, 2.0)))
	if not bool(state.call("add_resource", resource_id, reward)):
		return false
	collected = true
	queue_free()
	return true
