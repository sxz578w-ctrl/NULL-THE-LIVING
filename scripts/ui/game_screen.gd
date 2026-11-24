extends Control
class_name NullGameScreen

signal exit_requested
signal restart_requested(mode: String, stage_index: int)

var mode := "story"
var stage_index := 0
var mission_data: Dictionary = {}
var progress: Dictionary = {}
var world: NullWorldView
var title_label: Label
var mode_label: Label
var status_label: Label
var goal_label: Label
var stats_label: Label
var hint_label: Label
var selected_species := "LUMA"
var elapsed := 0.0
var remaining := 90.0
var danger := 12.0
var shield := 0.0
var lives := 3
var survival_score := 0
var daily_score := 0
var last_survival_signature := ""
var survival_repeat_count := 0
var noise_meter := 0
var audio_player: AudioStreamPlayer
var paused := false
var run_finished := false
var overlay: Control
var pause_overlay: Control
var pause_button: Button
var noise_bar: ProgressBar
var meter_label: Label
var time_since_gesture := 0.0
var noise_decay_accumulator := 0.0

func configure(p_mode: String, p_stage_index: int = 0) -> void:
	mode = p_mode
	stage_index = p_stage_index
	if mode == "story" or mode == "daily":
		mission_data = GameCatalog.mission(stage_index)
	elif mode == "survival":
		mission_data = {"title":"بروتوكول البقاء","goal":"بدّل أنماطك قبل أن يصل الخطر إلى أقصاه. المدار والتثبيت يمنحانك وقتاً للحركة."}
	else:
		mission_data = {"title":"مختبر التفاعل","goal":"جرّب إيماءات مختلفة وعلّم الكائن المحدد."}

func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	progress = {}
	_build_screen()
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

func _process(delta: float) -> void:
	if paused or run_finished:
		return
	if (mode == "story" or mode == "daily") and stage_index >= 3 and noise_meter > 0:
		time_since_gesture += delta
		if time_since_gesture >= 2.5:
			noise_decay_accumulator += delta * 6.0
			var decay_points := int(noise_decay_accumulator)
			if decay_points > 0:
				noise_decay_accumulator -= float(decay_points)
				noise_meter = maxi(0, noise_meter - decay_points)
				world.set_noise(float(noise_meter))
				world.set_hush_visible(stage_index == 4 or noise_meter >= 35)
				noise_bar.value = noise_meter
				stats_label.text = "الضوضاء %d%%   •   أهدئ الإشارة بالانتظار" % noise_meter
	if mode == "survival":
		elapsed += delta
		remaining = maxf(0.0, 90.0 - elapsed)
		shield = maxf(0.0, shield - delta)
		danger = minf(100.0, danger + delta * (1.5 if shield > 0.0 else 4.2))
		if danger >= 100.0:
			lives -= 1
			danger = 48.0 if lives > 0 else 100.0
			if lives <= 0:
				_finish_survival(false)
				return
		if remaining <= 0.0:
			_finish_survival(true)
			return
		world.set_danger(danger)
		noise_bar.value = danger
		stats_label.text = "الوقت %02d:%02d   •   النبض %d   •   النقاط %d" % [int(int(remaining) / 60.0), int(remaining) % 60, lives, survival_score]
	elif mode == "daily":
		elapsed += delta

func _build_screen() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/null_backdrop.svg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.modulate = Color(0.42, 0.50, 0.85, 0.42)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.012, 0.018, 0.052, 0.56)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)
	var back := _small_button("رجوع")
	back.pressed.connect(_on_exit)
	header.add_child(back)
	title_label = Label.new()
	title_label.text = str(mission_data.get("title", "NULL"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(0.84, 0.9, 1.0))
	title_label.add_theme_font_size_override("font_size", 25)
	header.add_child(title_label)
	pause_button = _small_button("إيقاف")
	pause_button.pressed.connect(_toggle_pause)
	header.add_child(pause_button)

	mode_label = Label.new()
	mode_label.text = _mode_description()
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.add_theme_color_override("font_color", Color(0.47, 0.75, 1.0))
	mode_label.add_theme_font_size_override("font_size", 14)
	layout.add_child(mode_label)

	stats_label = Label.new()
	stats_label.text = _initial_stats()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_color_override("font_color", Color(0.76, 0.82, 0.96))
	stats_label.add_theme_font_size_override("font_size", 15)
	layout.add_child(stats_label)
	meter_label = Label.new()
	meter_label.text = "مؤشر الخطر" if mode == "survival" else ("تطور الكائن المختار" if mode == "lab" else "مؤشر الضوضاء")
	meter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meter_label.add_theme_font_size_override("font_size", 11)
	meter_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.92))
	layout.add_child(meter_label)
	noise_bar = ProgressBar.new()
	noise_bar.min_value = 0.0
	noise_bar.max_value = 100.0
	noise_bar.value = 0.0
	noise_bar.show_percentage = false
	noise_bar.custom_minimum_size = Vector2(0, 9)
	noise_bar.add_theme_stylebox_override("background", _meter_style(Color(0.03, 0.04, 0.09, 0.9)))
	noise_bar.add_theme_stylebox_override("fill", _meter_style(Color(0.18, 0.68, 0.94, 0.9)))
	layout.add_child(noise_bar)

	var world_slot := Control.new()
	world_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world_slot.custom_minimum_size = Vector2(0, 520)
	layout.add_child(world_slot)
	world = NullWorldView.new()
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world.gesture_created.connect(_on_gesture_created)
	world_slot.add_child(world)
	world.set_hush_visible(mode == "survival" or ((mode == "story" or mode == "daily") and stage_index == 4))
	world.set_noise(float(noise_meter))
	if mode == "survival":
		noise_bar.value = danger
	if mode == "lab":
		for species_id in ["LUMA", "VEYL", "ECHO"]:
			var memory: Array = SaveManager.data.get("species_memory", {}).get(species_id, [])
			world.set_species_evolution(species_id, memory.size())
		world.set_species_selected(selected_species)
		var selected_memory: Array = SaveManager.data.get("species_memory", {}).get(selected_species, [])
		stats_label.text = "الكائن المحدد: %s   •   البصمات الفريدة: %d / 5" % [selected_species, selected_memory.size()]
		noise_bar.value = float(selected_memory.size()) * 20.0

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.055, 0.13, 0.96)))
	layout.add_child(panel)
	var bottom := VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	panel.add_child(bottom)
	goal_label = Label.new()
	goal_label.text = str(mission_data.get("goal", ""))
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_color_override("font_color", Color(0.94, 0.93, 1.0))
	goal_label.add_theme_font_size_override("font_size", 17)
	bottom.add_child(goal_label)
	status_label = Label.new()
	status_label.text = "المس الشاشة وجرّب إشارة. راقب كيف يستجيب العالم."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0.45, 0.88, 0.95))
	status_label.add_theme_font_size_override("font_size", 14)
	bottom.add_child(status_label)
	if mode == "lab":
		status_label.text = "اجمع بصمات مختلفة لتفتح طبقات تطور جديدة للكائن. ابدأ اللمسة فوق الكائن المختار."
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	bottom.add_child(actions)
	var hint := _small_button("تلميح")
	hint.pressed.connect(_show_hint)
	actions.add_child(hint)
	var restart := _small_button("إعادة")
	restart.pressed.connect(_restart)
	actions.add_child(restart)
	if mode == "lab":
		for species_id in ["LUMA", "VEYL", "ECHO"]:
			var species_button := _small_button(species_id)
			species_button.pressed.connect(_select_species.bind(species_id))
			actions.add_child(species_button)

func _mode_description() -> String:
	match mode:
		"story": return "رحلة الأحواض  •  المرحلة %d / 6" % (stage_index + 1)
		"survival": return "البقاء  •  حافظ على توازن الإشارات لمدة 90 ثانية"
		"daily": return "تجربة اليوم  •  لغز محلي يتغير كل يوم"
		"lab": return "مختبر التطور  •  ذاكرة سلوكية محلية"
	return "NULL — THE LIVING TOUCH"

func _initial_stats() -> String:
	if mode == "survival":
		return "الوقت 01:30   •   النبض 3   •   النقاط 0"
	if mode == "lab":
		return "الكائن المحدد: LUMA   •   البصمات المحفوظة: 0"
	return "الضوضاء 0%   •   الاكتشافات محفوظة محلياً"

func _on_gesture_created(signature: Dictionary, start_target: String, end_target: String) -> void:
	if paused or run_finished:
		return
	if str(signature.get("confidence", "high")) == "low":
		status_label.text = "الإشارة غير واضحة. حاول بحركة أبطأ وأكثر وضوحاً."
		return
	if (mode == "story" or mode == "daily") and GameRules.is_route_blocked(stage_index, float(noise_meter)) and (start_target == "LUMA" or end_target == "RELAY"):
		time_since_gesture = 0.0
		noise_decay_accumulator = 0.0
		status_label.text = "HUSH قطع مسار RELAY بسبب الضوضاء. ارفع إصبعك وانتظر حتى تهدأ الإشارة."
		return
	if mode == "lab":
		var required_target := {"LUMA":"LUMA","VEYL":"SEED","ECHO":"ECHO"}.get(selected_species, "")
		if start_target != required_target:
			status_label.text = "ابدأ اللمسة على %s حتى يتعلم الكائن بصمتك." % required_target
			return
	time_since_gesture = 0.0
	noise_decay_accumulator = 0.0
	var is_new := SaveManager.record_discovery(signature)
	var description := TouchDNA.describe(signature)
	_play_gesture_tone(signature)
	if mode == "story" or mode == "daily":
		var result := GameRules.apply_mission_gesture(stage_index, progress, signature, start_target, end_target)
		progress = result["progress"]
		status_label.text = str(result["message"]) + "\n" + description
		if bool(result["accepted"]):
			if stage_index == 0 or stage_index == 3 or stage_index == 5:
				world.set_node_active("RELAY", true)
			if stage_index == 1 or (stage_index == 5 and bool(progress.get("path", false))):
				world.set_node_active("SEED", true)
			if stage_index == 2 or (stage_index == 3 and bool(progress.get("transfer_armed", false))):
				world.set_node_active("ECHO", true)
			if stage_index == 4:
				world.set_node_active("DECOY" if bool(progress.get("baited", false)) else "HUSH", true)
		if bool(result["accepted"]):
			if bool(result["completed"]):
				_complete_mission()
			else:
				noise_meter = maxi(0, noise_meter - 12)
		elif is_new:
			noise_meter = mini(100, noise_meter + 3)
			status_label.text += "\nاكتشاف جديد: " + str(signature.get("id", ""))
		else:
			noise_meter = mini(100, noise_meter + 7)
		world.set_noise(float(noise_meter))
		world.set_hush_visible(stage_index == 4 or (stage_index >= 3 and noise_meter >= 35))
		noise_bar.value = noise_meter
		stats_label.text = "الضوضاء %d%%   •   البصمة: %s" % [noise_meter, str(signature.get("id", ""))]
	elif mode == "survival":
		var signature_id := str(signature.get("id", ""))
		if signature_id == last_survival_signature:
			survival_repeat_count += 1
		else:
			survival_repeat_count = 0
			last_survival_signature = signature_id
		var effect := GameRules.survival_effect(signature, survival_repeat_count)
		survival_score += int(effect["score"])
		danger = maxf(0.0, danger - float(effect["danger_reduction"]))
		shield = maxf(shield, float(effect["shield_seconds"]))
		world.add_shield(shield)
		world.set_danger(danger)
		noise_bar.value = danger
		var effectiveness := int(round(float(effect["effectiveness"]) * 100.0))
		status_label.text = "امتص العالم الإشارة. الفعالية الحالية %d%% — غيّر نمطك لاستعادة قوتها. %s" % [effectiveness, description]
		stats_label.text = "الوقت %02d:%02d   •   النبض %d   •   النقاط %d" % [int(int(remaining) / 60.0), int(remaining) % 60, lives, survival_score]
	elif mode == "lab":
		var memory_count := SaveManager.remember_species(selected_species, signature)
		world.set_species_evolution(selected_species, memory_count)
		world.set_species_selected(selected_species)
		var evolution_label := "بداية التكيّف" if memory_count < 3 else ("طور متقدم" if memory_count < 5 else "طور مكتمل")
		status_label.text = "%s تعلم بصمة: %s — %s" % [selected_species, description, evolution_label]
		stats_label.text = "الكائن المحدد: %s   •   البصمات الفريدة: %d / 5" % [selected_species, memory_count]
		noise_bar.value = float(memory_count) * 20.0
		meter_label.text = "تطور الكائن المختار — %d / 5" % memory_count
	world.queue_redraw()

func _complete_mission() -> void:
	if run_finished:
		return
	run_finished = true
	world.set_node_active("GATE", true)
	if mode == "story":
		SaveManager.complete_mission(stage_index, int(mission_data.get("reward", 20)))
		_show_result(true, "اكتملت المرحلة", "استعاد هذا الموطن نبضه. أصبحت المرحلة التالية متاحة.", stage_index < 5)
	else:
		daily_score += int(mission_data.get("reward", 20))
		SaveManager.record_daily(daily_score)
		_show_result(true, "اكتمل تحدي اليوم", "أنجزت لغز اليوم. تقدمك محفوظ على هذا الجهاز.", false)

func _finish_survival(won: bool) -> void:
	if run_finished:
		return
	run_finished = true
	SaveManager.record_survival(survival_score)
	_show_result(won, "انتهت جولة البقاء", "النقاط: %d  •  أفضل نتيجة: %d" % [survival_score, int(SaveManager.data.get("best_survival", 0))], false)

func _show_result(success: bool, heading: String, body: String, has_next: bool) -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.008, 0.03, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	overlay = shade
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(size.x * 0.84, size.y * 0.30)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.06, 0.16, 1)))
	center.add_child(card)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	card.add_child(content)
	var title := Label.new()
	title.text = heading
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0) if success else Color(1.0, 0.55, 0.72))
	title.add_theme_font_size_override("font_size", 27)
	content.add_child(title)
	var detail := Label.new()
	detail.text = body
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_color_override("font_color", Color(0.83, 0.86, 0.97))
	content.add_child(detail)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	var menu_button := _small_button("القائمة")
	menu_button.pressed.connect(_on_exit)
	buttons.add_child(menu_button)
	var retry_button := _small_button("إعادة اللعب")
	retry_button.pressed.connect(_restart)
	buttons.add_child(retry_button)
	if has_next:
		var next_button := _small_button("التالي")
		next_button.pressed.connect(_next_mission)
		buttons.add_child(next_button)

func _show_hint() -> void:
	if mode == "story" or mode == "daily":
		status_label.text = str(mission_data.get("hint", "راقب الكائنات وجرب إيماءة أخرى."))
		if stage_index >= 3:
			status_label.text += " عندما يظهر HUSH، توقف قليلاً حتى تهدأ الضوضاء."
	elif mode == "survival":
		status_label.text = "المدار يخفض الخطر أكثر، والتثبيت يمنح حماية قصيرة. تكرار البصمة نفسها يقلل فعاليتها."
	else:
		status_label.text = "اختر كائناً، ثم ابدأ الإيماءة فوقه مباشرة. اجمع خمس بصمات فريدة لتصل إلى طوره الكامل."

func _select_species(species_id: String) -> void:
	selected_species = species_id
	var memory: Array = SaveManager.data.get("species_memory", {}).get(selected_species, [])
	world.set_species_evolution(selected_species, memory.size())
	world.set_species_selected(selected_species)
	stats_label.text = "الكائن المحدد: %s   •   البصمات الفريدة: %d / 5" % [selected_species, memory.size()]
	noise_bar.value = float(memory.size()) * 20.0
	meter_label.text = "تطور الكائن المختار — %d / 5" % memory.size()
	var target_label := "SEED" if selected_species == "VEYL" else selected_species
	status_label.text = "ابدأ اللمسة فوق %s. كل بصمة فريدة تضيف طبقة تطور مرئية." % target_label

func _toggle_pause() -> void:
	if run_finished:
		return
	paused = not paused
	if paused:
		status_label.text = "اللعبة متوقفة مؤقتاً."
		pause_button.text = "متابعة"
		_show_pause_overlay()
	else:
		status_label.text = "استمر في التجربة. راقب استجابة الكائنات."
		pause_button.text = "إيقاف"
		_hide_pause_overlay()

func _show_pause_overlay() -> void:
	if pause_overlay != null:
		return
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.008, 0.03, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	pause_overlay = shade
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(size.x * 0.78, size.y * 0.24)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.055, 0.15, 1.0)))
	center.add_child(card)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	card.add_child(content)
	var heading := Label.new()
	heading.text = "توقّف الرنين"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color(0.83, 0.91, 1.0))
	content.add_child(heading)
	var resume := _small_button("متابعة اللعب")
	resume.pressed.connect(_toggle_pause)
	content.add_child(resume)
	var menu := _small_button("العودة للقائمة")
	menu.pressed.connect(_on_exit)
	content.add_child(menu)

func _hide_pause_overlay() -> void:
	if pause_overlay != null and is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
	pause_overlay = null

func _restart() -> void:
	restart_requested.emit(mode, stage_index)

func _next_mission() -> void:
	restart_requested.emit("story", min(stage_index + 1, 5))

func _on_exit() -> void:
	exit_requested.emit()

func _play_gesture_tone(signature: Dictionary) -> void:
	if bool(SaveManager.get_setting("haptics_enabled", false)) and (OS.has_feature("android") or OS.has_feature("ios")):
		Input.vibrate_handheld(35)
	if not bool(SaveManager.get_setting("sound_enabled", true)) or audio_player == null:
		return
	var shape := str(signature.get("shape", "tap"))
	var frequency := 440.0
	match shape:
		"anchor": frequency = 260.0
		"swipe": frequency = 520.0
		"curve": frequency = 390.0
		"loop": frequency = 660.0
		"tap": frequency = 480.0
	audio_player.stream = _make_tone(frequency, 0.10)
	audio_player.volume_db = -18.0
	audio_player.play()

func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var bytes := PackedByteArray()
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var envelope := pow(1.0 - float(i) / float(sample_count), 2.2)
		var sample := int(sin(TAU * frequency * t) * envelope * 7800.0)
		bytes.append(sample & 0xff)
		bytes.append((sample >> 8) & 0xff)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream

func _small_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	var ui_scale := 1.18 if bool(SaveManager.get_setting("large_ui", false)) else 1.0
	button.custom_minimum_size = Vector2(100, 54 * ui_scale)
	button.add_theme_font_size_override("font_size", int(round(15 * ui_scale)))
	button.add_theme_color_override("font_color", Color(0.91, 0.94, 1.0))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.10, 0.13, 0.27, 0.96)))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.17, 0.20, 0.39, 1.0)))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.20, 0.13, 0.40, 1.0)))
	return button

func _meter_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style

func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.24, 0.42, 0.84, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
