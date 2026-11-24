extends Node

const BUILD_COSTS := {
	"extractor": {"scrap": 12, "flux": 2},
	"relay": {"scrap": 15, "echo": 2},
	"turret": {"scrap": 18, "flux": 4}
}
const VALID_SLOTS: Array[String] = ["north", "east", "south"]
var built_slots: Dictionary = {}

func try_build(slot_id: String, building_type: String, state: Node) -> bool:
	if not VALID_SLOTS.has(slot_id) or built_slots.has(slot_id):
		return false
	if not BUILD_COSTS.has(building_type):
		return false
	var cost: Dictionary = BUILD_COSTS[building_type]
	if not state.can_afford(cost):
		return false
	if not state.spend_resources(cost):
		return false
	built_slots[slot_id] = building_type
	return true

func snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot_id: Variant in built_slots.keys():
		result.append({"slot_id": str(slot_id), "building_type": str(built_slots[slot_id])})
	return result

func load_snapshot(items: Array) -> void:
	built_slots.clear()
	for item: Variant in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var slot_id := str(item.get("slot_id", ""))
		var building_type := str(item.get("building_type", ""))
		if VALID_SLOTS.has(slot_id) and BUILD_COSTS.has(building_type) and not built_slots.has(slot_id):
			built_slots[slot_id] = building_type
