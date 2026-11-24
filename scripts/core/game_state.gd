extends Node

signal resources_changed(resources: Dictionary)

const RESOURCE_IDS: Array[String] = ["scrap", "flux", "echo"]
var resources: Dictionary = {"scrap": 30, "flux": 8, "echo": 0}

func add_resource(resource_id: String, amount: int) -> bool:
	if not RESOURCE_IDS.has(resource_id) or amount <= 0:
		return false
	resources[resource_id] = int(resources.get(resource_id, 0)) + amount
	resources_changed.emit(resources.duplicate(true))
	return true

func can_afford(cost: Dictionary) -> bool:
	if cost.is_empty():
		return false
	for key: Variant in cost.keys():
		var resource_id := str(key)
		var value: Variant = cost[key]
		if not RESOURCE_IDS.has(resource_id) or typeof(value) != TYPE_INT or int(value) <= 0:
			return false
		if int(resources.get(resource_id, 0)) < int(value):
			return false
	return true

func spend_resources(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for key: Variant in cost.keys():
		var resource_id := str(key)
		resources[resource_id] = int(resources[resource_id]) - int(cost[key])
	resources_changed.emit(resources.duplicate(true))
	return true

func replace_resources(values: Dictionary) -> bool:
	for resource_id in RESOURCE_IDS:
		if not values.has(resource_id) or typeof(values[resource_id]) != TYPE_INT or int(values[resource_id]) < 0:
			return false
	var next: Dictionary = {}
	for resource_id in RESOURCE_IDS:
		next[resource_id] = int(values[resource_id])
	resources = next
	resources_changed.emit(resources.duplicate(true))
	return true

func snapshot() -> Dictionary:
	return resources.duplicate(true)

func reset_state() -> void:
	resources = {"scrap": 30, "flux": 8, "echo": 0}
	resources_changed.emit(resources.duplicate(true))
