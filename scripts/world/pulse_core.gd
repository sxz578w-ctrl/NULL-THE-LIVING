extends RefCounted

const SEQUENCE: Array[String] = ["ember", "tide", "void"]
var progress: int = 0
var resolved: bool = false

func activate_node(node_id: String) -> bool:
	if resolved or progress >= SEQUENCE.size():
		return false
	if node_id == SEQUENCE[progress]:
		progress += 1
		return true
	progress = 1 if node_id == SEQUENCE[0] else 0
	return false

func is_ready() -> bool:
	return progress == SEQUENCE.size() and not resolved

func resolve(choice: String, zone: Node, state: Node) -> bool:
	if not is_ready() or not ["anchor", "harvest", "refract"].has(choice):
		return false
	var next_id := "pulse_" + str(int(zone.get("pulse_count")) + 1)
	if not bool(zone.call("apply_pulse", choice, next_id)):
		return false
	match choice:
		"anchor":
			state.call("add_resource", "scrap", 5)
			state.call("add_resource", "echo", 2)
		"harvest":
			state.call("add_resource", "scrap", 18)
			state.call("add_resource", "flux", 4)
		"refract":
			state.call("add_resource", "echo", 5)
			state.call("add_resource", "flux", 2)
	resolved = true
	return true
