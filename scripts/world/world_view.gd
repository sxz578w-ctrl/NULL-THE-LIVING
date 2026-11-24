extends Control
class_name NullWorldView

signal gesture_created(signature: Dictionary, start_target: String, end_target: String)

var draw_points: Array[Vector2] = []
var tap_stamps: Array[int] = []
var is_drawing := false
var touch_started_at := 0
var start_target := ""
var target_sequence: Array[String] = []
var pulse_time := 0.0
var seed_travel := 0.0
var danger := 0.0
var noise := 0.0
var hush_visible := false
var shield_time := 0.0
var completed_nodes: Dictionary = {}
var evolution_levels: Dictionary = {}
var selected_species_node := "LUMA"
var random := RandomNumberGenerator.new()
var stars: Array[Vector3] = []
var environment_seed := 11

const BIOME_TEXTURE: Texture2D = preload("res://assets/null_backdrop.svg")
const TARGETS := {
	"LUMA": Vector2(0.20, 0.34),
	"SEED": Vector2(0.50, 0.47),
	"RELAY": Vector2(0.79, 0.35),
	"ECHO": Vector2(0.78, 0.69),
	"DECOY": Vector2(0.20, 0.73),
	"HUSH": Vector2(0.50, 0.76),
	"GATE": Vector2(0.50, 0.15)
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	random.seed = environment_seed
	for i in 90:
		stars.append(Vector3(random.randf(), random.randf(), random.randf_range(0.4, 1.0)))
	queue_redraw()

func _process(delta: float) -> void:
	var motion_scale := 0.0 if bool(SaveManager.get_setting("reduced_motion", false)) else 1.0
	pulse_time += delta * motion_scale
	if bool(completed_nodes.get("GATE", false)):
		seed_travel = move_toward(seed_travel, 1.0, delta * 0.55)
	shield_time = maxf(0.0, shield_time - delta)
	queue_redraw()

func set_danger(value: float) -> void:
	danger = clampf(value, 0.0, 100.0)
	queue_redraw()

func set_noise(value: float) -> void:
	noise = clampf(value, 0.0, 100.0)
	queue_redraw()

func set_hush_visible(value: bool) -> void:
	hush_visible = value
	queue_redraw()

func add_shield(seconds: float) -> void:
	shield_time = maxf(shield_time, seconds)
	queue_redraw()

func set_node_active(node_id: String, active: bool = true) -> void:
	completed_nodes[node_id] = active
	queue_redraw()

func set_species_evolution(species_id: String, memory_count: int) -> void:
	var node_id := "SEED" if species_id == "VEYL" else species_id
	if not ["LUMA", "SEED", "ECHO"].has(node_id):
		return
	var level := 0
	if memory_count >= 1:
		level = 1
	if memory_count >= 3:
		level = 2
	if memory_count >= 5:
		level = 3
	evolution_levels[node_id] = level
	completed_nodes[node_id] = level > 0
	queue_redraw()

func set_species_selected(species_id: String) -> void:
	selected_species_node = "SEED" if species_id == "VEYL" else species_id
	queue_redraw()

func target_position(target_id: String) -> Vector2:
	if not TARGETS.has(target_id):
		return Vector2(-1000, -1000)
	var normalized: Vector2 = TARGETS[target_id]
	if target_id == "HUSH":
		normalized.y = lerpf(0.76, 0.52, maxf(danger, noise) / 100.0)
	return normalized * size

func target_at(local_position: Vector2) -> String:
	var radius := minf(size.x, size.y) * 0.105
	var best_target := ""
	var best_distance := radius
	for key in TARGETS.keys():
		if str(key) == "HUSH" and not hush_visible:
			continue
		var distance := local_position.distance_to(target_position(str(key)))
		if distance <= best_distance:
			best_distance = distance
			best_target = str(key)
	return best_target

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_stroke(event.position)
		else:
			_end_stroke(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		_move_stroke(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_stroke(event.position)
		else:
			_end_stroke(event.position)
		accept_event()
	elif event is InputEventMouseMotion and is_drawing and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_stroke(event.position)
		accept_event()

func _begin_stroke(position: Vector2) -> void:
	if is_drawing:
		return
	is_drawing = true
	draw_points.clear()
	target_sequence.clear()
	draw_points.append(_normalized(position))
	touch_started_at = Time.get_ticks_msec()
	start_target = target_at(position)
	_record_target(start_target)
	queue_redraw()

func _move_stroke(position: Vector2) -> void:
	if not is_drawing:
		return
	var p := _normalized(position)
	if draw_points.is_empty() or draw_points[draw_points.size() - 1].distance_to(p) >= 0.006:
		draw_points.append(p)
	_record_target(target_at(position))
	queue_redraw()

func _end_stroke(position: Vector2) -> void:
	if not is_drawing:
		return
	_move_stroke(position)
	is_drawing = false
	var duration := maxf(0.0, float(Time.get_ticks_msec() - touch_started_at) / 1000.0)
	var end_target := target_at(position)
	_record_target(end_target)
	var intervals: Array[float] = []
	var is_short_echo_tap := draw_points.size() <= 2 and duration < TouchDNA.ANCHOR_MIN_SECONDS and start_target == "ECHO"
	if is_short_echo_tap:
		var now := Time.get_ticks_msec()
		tap_stamps.append(now)
		while not tap_stamps.is_empty() and now - tap_stamps[0] > 1350:
			tap_stamps.pop_front()
		for i in range(1, tap_stamps.size()):
			intervals.append(float(tap_stamps[i] - tap_stamps[i - 1]) / 1000.0)
	else:
		tap_stamps.clear()
	var signature := TouchDNA.classify(draw_points.duplicate(), duration, intervals, target_sequence.duplicate(), bool(SaveManager.get_setting("simplified_gestures", false)))
	if signature.get("shape", "") == "loop":
		add_shield(3.0)
	gesture_created.emit(signature, start_target, end_target)
	draw_points.clear()
	target_sequence.clear()
	queue_redraw()

func _record_target(target_id: String) -> void:
	if target_id != "" and (target_sequence.is_empty() or target_sequence[target_sequence.size() - 1] != target_id):
		target_sequence.append(target_id)

func _normalized(position: Vector2) -> Vector2:
	return Vector2(clampf(position.x / maxf(size.x, 1.0), 0.0, 1.0), clampf(position.y / maxf(size.y, 1.0), 0.0, 1.0))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.018, 0.025, 0.075, 1.0))
	_draw_background()
	_draw_platforms()
	_draw_gate()
	_draw_targets()
	_draw_threat()
	_draw_trail()
	_draw_status_rings()

func _draw_background() -> void:
	draw_texture_rect(BIOME_TEXTURE, Rect2(Vector2.ZERO, size), false, Color(0.62, 0.72, 1.0, 0.60))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.006, 0.012, 0.045, 0.58))
	for i in 18:
		var y := size.y * float(i) / 18.0
		var color := Color(0.025, 0.04, 0.12).lerp(Color(0.06, 0.018, 0.11), float(i) / 18.0)
		draw_rect(Rect2(0, y, size.x, size.y / 18.0 + 2), color)
	for star in stars:
		var p := Vector2(star.x * size.x, star.y * size.y)
		var radius := 0.8 + star.z * 1.4
		draw_circle(p, radius, Color(0.55, 0.75, 1.0, 0.22 + star.z * 0.25))
	var haze := Color(0.12, 0.22, 0.58, 0.08)
	draw_circle(Vector2(size.x * 0.52, size.y * 0.42), minf(size.x, size.y) * 0.44, haze)
	draw_circle(Vector2(size.x * 0.82, size.y * 0.72), minf(size.x, size.y) * 0.22, Color(0.52, 0.08, 0.75, 0.07))

func _draw_platforms() -> void:
	var s := size
	var platforms := [
		[Vector2(0.00, 0.57), Vector2(0.18, 0.48), Vector2(0.38, 0.54), Vector2(0.31, 0.66), Vector2(0.07, 0.67)],
		[Vector2(0.55, 0.55), Vector2(0.78, 0.46), Vector2(0.98, 0.54), Vector2(0.88, 0.65), Vector2(0.61, 0.65)],
		[Vector2(0.27, 0.87), Vector2(0.46, 0.81), Vector2(0.65, 0.87), Vector2(0.56, 0.96), Vector2(0.34, 0.96)]
	]
	var colors := [Color(0.045, 0.09, 0.18), Color(0.055, 0.075, 0.20), Color(0.09, 0.04, 0.18)]
	for i in platforms.size():
		var polygon := PackedVector2Array()
		for point in platforms[i]:
			polygon.append(Vector2(point) * s)
		draw_colored_polygon(polygon, colors[i])
		for j in range(polygon.size()):
			draw_line(polygon[j], polygon[(j + 1) % polygon.size()], Color(0.18, 0.48, 0.85, 0.38), 2.0, true)
		var center := Vector2.ZERO
		for point in polygon:
			center += point
		center /= float(polygon.size())
		for k in 6:
			var x := center.x - 65 + float(k) * 24
			var y := center.y - 8 + sin(pulse_time * 1.2 + float(k)) * 3.0
			draw_line(Vector2(x, y), Vector2(x + 8, y - 10), Color(0.22, 0.68, 0.94, 0.42), 2.0, true)

func _draw_gate() -> void:
	var p := target_position("GATE")
	var pulse := 1.0 + sin(pulse_time * 1.7) * 0.06
	var radius := minf(size.x, size.y) * 0.09 * pulse
	var gate_open := bool(completed_nodes.get("GATE", false))
	var gate_tint := Color(0.44, 1.0, 0.86, 0.85) if gate_open else Color(0.24, 0.55, 1.0, 0.18)
	draw_arc(p, radius, 0, TAU, 72, gate_tint, 12 if gate_open else 8, true)
	draw_arc(p, radius * 0.72, 0, TAU, 72, Color(0.56, 0.27, 1.0, 0.72 if gate_open else 0.48), 4, true)
	draw_arc(p, radius * 0.52, 0, TAU, 72, Color(0.72, 0.87, 1.0, 0.95 if gate_open else 0.8), 2, true)
	draw_circle(p, 5.0, Color(0.8, 0.92, 1.0, 0.95))
	if gate_open:
		for ray_index in 8:
			var angle := TAU * float(ray_index) / 8.0 + pulse_time * 0.15
			var start := p + Vector2(cos(angle), sin(angle)) * radius * 1.12
			var finish := p + Vector2(cos(angle), sin(angle)) * radius * 1.62
			draw_line(start, finish, Color(0.42, 1.0, 0.82, 0.75), 2.0, true)

func _draw_targets() -> void:
	_draw_creature("LUMA", Color(0.15, 0.84, 1.0), 1.0)
	_draw_creature("SEED", Color(1.0, 0.65, 0.24), 1.15)
	_draw_creature("RELAY", Color(0.35, 0.71, 1.0), 0.92)
	_draw_creature("ECHO", Color(0.78, 0.34, 1.0), 1.05)
	_draw_creature("DECOY", Color(0.25, 0.69, 0.83), 0.83)
	if hush_visible:
		_draw_creature("HUSH", Color(0.84, 0.21, 0.66), 1.0)

func _draw_creature(target_id: String, tint: Color, scale_factor: float) -> void:
	var p := target_position(target_id)
	if target_id == "SEED" and bool(completed_nodes.get("GATE", false)):
		p = p.lerp(target_position("GATE"), seed_travel)
	var base := minf(size.x, size.y) * 0.032 * scale_factor
	var active := bool(completed_nodes.get(target_id, false))
	var wobble := sin(pulse_time * 2.1 + p.x * 0.03) * base * 0.12
	var color := tint.lightened(0.25) if active else tint
	var level := int(evolution_levels.get(target_id, 0))
	draw_circle(p, base * (2.5 + float(level) * 0.35), Color(color.r, color.g, color.b, 0.07 + float(level) * 0.025))
	draw_arc(p, base * (1.85 + wobble / maxf(base, 1.0)), 0, TAU, 40, Color(color.r, color.g, color.b, 0.55), 2.2, true)
	for ring_index in level:
		var ring_radius := base * (2.55 + float(ring_index) * 0.58)
		draw_arc(p, ring_radius, pulse_time * (0.22 + float(ring_index) * 0.08), TAU + pulse_time * (0.22 + float(ring_index) * 0.08), 48, Color(color.r, color.g, color.b, 0.62 - float(ring_index) * 0.10), 2.0 + float(level - ring_index) * 0.6, true)
		var petal_count := 4 + ring_index * 2
		for petal_index in petal_count:
			var angle := TAU * float(petal_index) / float(petal_count) + pulse_time * 0.16
			var petal_position := p + Vector2(cos(angle), sin(angle)) * ring_radius
			draw_circle(petal_position, maxf(2.5, base * 0.12), Color(color.r, color.g, color.b, 0.78))
	if bool(SaveManager.get_setting("high_contrast", false)):
		draw_arc(p, base * 2.95, 0, TAU, 44, Color(1.0, 1.0, 1.0, 0.95), 3.2, true)
	if selected_species_node == target_id:
		draw_arc(p, base * 3.35, 0, TAU, 52, Color(1.0, 0.93, 0.66, 0.95), 3.2, true)
	if target_id == "SEED":
		var diamond := PackedVector2Array([p + Vector2(0, -base), p + Vector2(base * 0.78, 0), p + Vector2(0, base), p + Vector2(-base * 0.78, 0)])
		draw_colored_polygon(diamond, color)
		draw_circle(p, base * 0.28, Color(1, 0.94, 0.74))
	elif target_id == "HUSH":
		draw_circle(p, base * 0.78, Color(0.09, 0.035, 0.16, 1))
		for j in 8:
			var a := TAU * float(j) / 8.0
			var tip := p + Vector2(cos(a), sin(a)) * base * 1.25
			draw_line(p, tip, color, 2.4, true)
	else:
		draw_circle(p, base * 0.78, color)
		draw_circle(p + Vector2(-base * 0.20, -base * 0.12), base * 0.13, Color(0.04, 0.08, 0.17, 0.9))
		draw_circle(p + Vector2(base * 0.20, -base * 0.12), base * 0.13, Color(0.04, 0.08, 0.17, 0.9))
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, p + Vector2(-45, base * 2.5 + 18), target_id, HORIZONTAL_ALIGNMENT_CENTER, 90, 12, Color(0.78, 0.87, 1.0, 0.86))

func _draw_threat() -> void:
	if shield_time > 0.0:
		var seed_pos := target_position("SEED")
		draw_arc(seed_pos, minf(size.x, size.y) * (0.16 + sin(pulse_time * 4.0) * 0.005), 0, TAU, 60, Color(0.58, 0.38, 1.0, 0.62), 5, true)
	if hush_visible:
		var hush_pos := target_position("HUSH")
		var pressure := maxf(danger, noise)
		var threat_color := Color(0.92, 0.18, 0.55, clampf(pressure / 100.0, 0.12, 0.86))
		draw_arc(hush_pos, minf(size.x, size.y) * (0.07 + pressure * 0.00035), pulse_time, pulse_time + PI * 1.65, 28, threat_color, 3.0, true)

func _draw_trail() -> void:
	if draw_points.size() < 2:
		return
	var screen_points := PackedVector2Array()
	for point in draw_points:
		screen_points.append(Vector2(point.x * size.x, point.y * size.y))
	draw_polyline(screen_points, Color(0.16, 0.85, 1.0, 0.24), 13.0, true)
	draw_polyline(screen_points, Color(0.62, 0.93, 1.0, 0.95), 4.0, true)

func _draw_status_rings() -> void:
	if danger > 0.0:
		var p := Vector2(size.x * 0.5, size.y * 0.94)
		draw_arc(p, size.x * 0.12, PI, PI + TAU * danger / 100.0, 36, Color(1.0, 0.25, 0.56, 0.82), 3.0, true)
