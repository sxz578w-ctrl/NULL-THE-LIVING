extends RefCounted
class_name TouchDNA

const LOOP_CLOSE_RATIO := 0.18
const LOOP_MIN_PATH := 0.27
const SWIPE_MIN_DISTANCE := 0.16
const ANCHOR_MIN_SECONDS := 0.68

static func classify(points: Array, duration: float, tap_intervals: Array, sequence: Array, simplified_gestures: bool = false) -> Dictionary:
	var path_length := 0.0
	var net := Vector2.ZERO
	var loop_center := Vector2.ZERO
	if not points.is_empty():
		for point in points:
			if point is Vector2:
				loop_center += point
		loop_center /= float(points.size())
	if points.size() >= 2:
		for i in range(1, points.size()):
			path_length += points[i - 1].distance_to(points[i])
		net = points[points.size() - 1] - points[0]
	var net_distance := net.length()
	var loop_min_path := LOOP_MIN_PATH * (0.78 if simplified_gestures else 1.0)
	var loop_close_ratio := LOOP_CLOSE_RATIO * (1.35 if simplified_gestures else 1.0)
	var shape := "tap"
	if duration >= ANCHOR_MIN_SECONDS and net_distance <= 0.10 and path_length <= 0.20:
		shape = "anchor"
	elif points.size() >= 4 and path_length >= loop_min_path and net_distance <= min(loop_close_ratio, path_length * 0.30):
		shape = "loop"
	elif net_distance >= SWIPE_MIN_DISTANCE and path_length / maxf(net_distance, 0.001) <= 1.45:
		shape = "swipe"
	elif path_length >= 0.12:
		shape = "curve"
	var tempo := "single"
	var interval_total := 0.0
	for gap in tap_intervals:
		interval_total += float(gap)
	if tap_intervals.size() >= 2 and interval_total <= 1.20:
		tempo = "pulse_train"
	elif tap_intervals.size() == 1 and interval_total <= 0.52:
		tempo = "double"
	var direction := "none"
	if net_distance >= 0.08:
		if absf(net.x) > absf(net.y):
			direction = "right" if net.x > 0.0 else "left"
		else:
			direction = "down" if net.y > 0.0 else "up"
	var clean_sequence: Array[String] = []
	for item in sequence:
		var target := str(item)
		if target != "" and (clean_sequence.is_empty() or clean_sequence[clean_sequence.size() - 1] != target):
			clean_sequence.append(target)
	var confidence := "high"
	if shape == "curve" and points.size() < 4:
		confidence = "low"
	elif shape == "loop" and points.size() < 5:
		confidence = "medium"
	elif duration < 0.045 and shape == "swipe" and points.size() < 3:
		confidence = "low"
	elif shape == "tap":
		confidence = "medium"
	var strength := clampf((duration * 0.45) + (path_length * 1.2), 0.0, 1.0)
	var sequence_code := "free"
	if not clean_sequence.is_empty():
		sequence_code = clean_sequence[0]
		for sequence_index in range(1, clean_sequence.size()):
			sequence_code += "-" + clean_sequence[sequence_index]
	var signature_id := "%s-%s-%s-%s-%s" % [shape, "long" if duration >= ANCHOR_MIN_SECONDS else "short", tempo, direction, sequence_code]
	return {"id":signature_id,"shape":shape,"duration":duration,"path_length":path_length,"net_distance":net_distance,"tempo":tempo,"direction":direction,"sequence":clean_sequence,"confidence":confidence,"strength":strength,"loop_center":loop_center,"points_count":points.size()}

static func describe(signature: Dictionary) -> String:
	var shape_names := {"tap":"نبضة","anchor":"تثبيت","swipe":"مسار","curve":"منحنى","loop":"مدار"}
	var tempo_names := {"single":"مفرد","double":"مزدوج","pulse_train":"قطار نبضات"}
	return "%s • %s • %s" % [shape_names.get(signature.get("shape","tap"),"إشارة"),tempo_names.get(signature.get("tempo","single"),"إيقاع"),str(signature.get("direction","none"))]
