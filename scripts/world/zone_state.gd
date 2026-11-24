extends Node

var stability: int = 45
var danger: int = 55
var route_open: bool = false
var pulse_count: int = 0
var resource_multiplier: float = 1.0
var last_choice: String = "none"
var applied_activations: Dictionary = {}

func apply_pulse(choice: String, activation_id: String) -> bool:
	if activation_id.is_empty() or applied_activations.has(activation_id):
		return false
	if not ["anchor", "harvest", "refract"].has(choice):
		return false
	match choice:
		"anchor":
			stability = mini(100, stability + 25)
			danger = maxi(0, danger - 25)
			resource_multiplier = 1.0
		"harvest":
			stability = maxi(0, stability - 10)
			danger = mini(100, danger + 25)
			resource_multiplier = 1.75
		"refract":
			stability = maxi(0, stability - 5)
			danger = mini(100, danger + 10)
			route_open = true
			resource_multiplier = 1.15
	last_choice = choice
	pulse_count += 1
	applied_activations[activation_id] = true
	return true

func snapshot() -> Dictionary:
	return {
		"stability": stability,
		"danger": danger,
		"route_open": route_open,
		"pulse_count": pulse_count,
		"resource_multiplier": resource_multiplier,
		"last_choice": last_choice,
		"applied_activations": applied_activations.duplicate(true)
	}

func load_snapshot(data: Dictionary) -> bool:
	if typeof(data.get("stability")) != TYPE_INT or typeof(data.get("danger")) != TYPE_INT:
		return false
	var new_stability := int(data["stability"])
	var new_danger := int(data["danger"])
	if new_stability < 0 or new_stability > 100 or new_danger < 0 or new_danger > 100:
		return false
	if typeof(data.get("route_open")) != TYPE_BOOL or typeof(data.get("pulse_count")) != TYPE_INT:
		return false
	if int(data["pulse_count"]) < 0:
		return false
	var choice := str(data.get("last_choice", "none"))
	if not ["none", "anchor", "harvest", "refract"].has(choice):
		return false
	stability = new_stability
	danger = new_danger
	route_open = bool(data["route_open"])
	pulse_count = int(data["pulse_count"])
	last_choice = choice
	resource_multiplier = clampf(float(data.get("resource_multiplier", 1.0)), 0.5, 2.0)
	var activations: Variant = data.get("applied_activations", {})
	applied_activations = activations.duplicate(true) if typeof(activations) == TYPE_DICTIONARY else {}
	return true
