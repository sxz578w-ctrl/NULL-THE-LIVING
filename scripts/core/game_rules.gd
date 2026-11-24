extends RefCounted
class_name GameRules

const SEED_CENTER := Vector2(0.50, 0.47)
const HUSH_CENTER := Vector2(0.50, 0.76)
const HUSH_LOOP_TOLERANCE := 0.27

static func apply_mission_gesture(stage_index: int, old_progress: Dictionary, signature: Dictionary, start_target: String, end_target: String) -> Dictionary:
	var progress := old_progress.duplicate(true)
	var changed := false
	var message := "لم تتطابق الإشارة مع المطلوب. جرّب شكلاً أو ترتيباً مختلفاً."
	var shape := str(signature.get("shape", "tap"))
	var tempo := str(signature.get("tempo", "single"))
	var center: Vector2 = signature.get("loop_center", Vector2.ZERO)
	if str(signature.get("confidence", "high")) == "low":
		return {"progress":progress,"accepted":false,"completed":false,"message":"الإشارة غير واضحة بما يكفي. أعدها بحركة أبطأ أو أوضح."}
	match stage_index:
		0:
			if shape == "swipe" and start_target == "LUMA" and end_target == "RELAY":
				progress["done"] = true
				changed = true
				message = "نجح LUMA في تتبع المسار. البوابة تستجيب!"
		1:
			if shape == "loop" and center.distance_to(SEED_CENTER) <= 0.21:
				progress["done"] = true
				changed = true
				message = "تكوّن مدار VEYL حول النواة. الحماية اكتملت!"
		2:
			if tempo == "pulse_train" and start_target == "ECHO":
				progress["done"] = true
				changed = true
				message = "التقط ECHO الإيقاع وأعاد الإشارة ثلاث مرات!"
		3:
			if not bool(progress.get("transfer_armed", false)) and shape == "swipe" and start_target == "LUMA" and end_target == "RELAY":
				progress["transfer_armed"] = true
				changed = true
				message = "حُفظت البصمة في RELAY. انقر ECHO لنقلها."
			elif bool(progress.get("transfer_armed", false)) and shape == "tap" and start_target == "ECHO":
				progress["done"] = true
				changed = true
				message = "نُقلت البصمة بنجاح. كائنان يتشاركان سلوكاً واحداً!"
		4:
			if not bool(progress.get("baited", false)) and shape == "anchor" and start_target == "DECOY":
				progress["baited"] = true
				changed = true
				message = "ثبتّ الطُعم. HUSH بدأ يتبعه. أحط به بمدار."
			elif bool(progress.get("baited", false)) and shape == "loop" and center.distance_to(HUSH_CENTER) <= HUSH_LOOP_TOLERANCE:
				progress["done"] = true
				changed = true
				message = "أُغلق المدار حول HUSH. الخطر أصبح محاصراً!"
		5:
			if shape == "swipe" and start_target == "LUMA" and end_target == "RELAY" and not bool(progress.get("path", false)):
				progress["path"] = true
				changed = true
				message = "1/3 — المسار استقر. الآن اصنع المدار حول SEED."
			elif shape == "loop" and center.distance_to(SEED_CENTER) <= 0.21 and bool(progress.get("path", false)) and not bool(progress.get("orbit", false)):
				progress["orbit"] = true
				changed = true
				message = "2/3 — المدار جاهز. أكمل الإيقاع على ECHO."
			elif tempo == "pulse_train" and start_target == "ECHO" and bool(progress.get("orbit", false)):
				progress["done"] = true
				changed = true
				message = "3/3 — اكتمل الرنين! البوابة فتحت."
			else:
				message = "اتبع ترتيب الإشارات: LUMA ثم SEED ثم ECHO."
	return {"progress":progress,"accepted":changed,"completed":bool(progress.get("done", false)),"message":message}

static func is_route_blocked(stage_index: int, noise_value: float) -> bool:
	return stage_index >= 3 and stage_index != 4 and noise_value >= 65.0

static func survival_effect(signature: Dictionary, repeat_count: int = 0) -> Dictionary:
	var shape := str(signature.get("shape", "tap"))
	var tempo := str(signature.get("tempo", "single"))
	var points := 1
	var danger_reduction := 5.0
	var shield_seconds := 0.0
	match shape:
		"anchor":
			points = 2
			danger_reduction = 18.0
			shield_seconds = 1.5
		"swipe":
			points = 3
			danger_reduction = 12.0
		"curve":
			points = 2
			danger_reduction = 10.0
		"loop":
			points = 4
			danger_reduction = 24.0
			shield_seconds = 4.0
		"tap":
			points = 1
	if tempo == "pulse_train":
		points += 3
		danger_reduction += 8.0
	var repeat_factor := maxf(0.40, 1.0 - float(clampi(repeat_count, 0, 4)) * 0.18)
	return {"score":maxi(1, roundi(float(points) * repeat_factor)),"danger_reduction":danger_reduction * repeat_factor,"shield_seconds":shield_seconds * maxf(0.5, repeat_factor),"effectiveness":repeat_factor}
