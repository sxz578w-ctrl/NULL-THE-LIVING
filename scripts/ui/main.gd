extends Control

const GameScreenScene = preload("res://scripts/ui/game_screen.gd")
const GameCatalogScript = preload("res://scripts/core/game_catalog.gd")

var current_game: NullGameScreen

func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	_build_home()

func _clear_screen() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _add_backdrop(use_key_art: bool = true) -> void:
	var base := ColorRect.new()
	base.color = Color(0.012, 0.018, 0.052, 1)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	if use_key_art:
		var art := TextureRect.new()
		art.texture = load("res://assets/null_backdrop.svg")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.modulate = Color(0.72, 0.80, 1.0, 0.52)
		add_child(art)
	var overlay := ColorRect.new()
	overlay.color = Color(0.012, 0.018, 0.06, 0.46)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

func _new_page(title_text: String) -> VBoxContainer:
	_add_backdrop()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	var heading := Label.new()
	heading.text = title_text
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	heading.add_theme_font_size_override("font_size", 30)
	page.add_child(heading)
	return page

func _build_home() -> void:
	_clear_screen()
	var page := _new_page("NULL")
	var tagline := Label.new()
	tagline.text = "THE LIVING TOUCH  •  العالم الذي يتعلم من طريقة لمسك له"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.add_theme_color_override("font_color", Color(0.62, 0.82, 1.0))
	tagline.add_theme_font_size_override("font_size", 15)
	page.add_child(tagline)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(spacer)
	var summary := Label.new()
	summary.text = "الرنين %d   •   الاكتشافات %d" % [int(SaveManager.data.get("resonance", 0)), SaveManager.data.get("discoveries", []).size()]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_color_override("font_color", Color(0.76, 0.78, 0.95))
	page.add_child(summary)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(buttons)
	buttons.add_child(_main_button("ابدأ الرحلة", _build_level_select, true))
	buttons.add_child(_main_button("طريقة اللعب", _build_tutorial))
	buttons.add_child(_main_button("البقاء", func(): _open_game("survival", 0)))
	buttons.add_child(_main_button("تحدي اليوم", _start_daily))
	buttons.add_child(_main_button("مختبر التطور", func(): _open_game("lab", 0)))
	buttons.add_child(_main_button("سجل الاكتشافات", _build_journal))
	buttons.add_child(_main_button("الإعدادات", _build_settings))
	var spacer_bottom := Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(spacer_bottom)
	var footer := Label.new()
	footer.text = "نسخة لعب محلية 0.1  •  لا تحتاج اتصالاً بالإنترنت"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color(0.59, 0.65, 0.82, 0.88))
	footer.add_theme_font_size_override("font_size", 12)
	page.add_child(footer)

func _build_tutorial() -> void:
	_clear_screen()
	var page := _new_page("كيف تلعب NULL؟")
	var intro := Label.new()
	intro.text = "لا توجد أزرار هجوم أو قفز. إصبعك يرسم الإشارات، والعالم يفسرها حسب شكلها ومدتها وإيقاعها."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color", Color(0.78, 0.87, 1.0))
	page.add_child(intro)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var lessons := VBoxContainer.new()
	lessons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lessons.add_theme_constant_override("separation", 9)
	scroll.add_child(lessons)
	var entries := [
		{"name":"TAP — نبضة","detail":"انقر مرة واحدة لإرسال إشارة قصيرة إلى الكائن الموجود تحت إصبعك."},
		{"name":"ANCHOR — تثبيت","detail":"اضغط مطولاً دون سحب واضح. استخدمها لتثبيت DECOY في مهمة HUSH."},
		{"name":"SWIPE — مسار","detail":"ابدأ فوق LUMA واسحب بخط واضح حتى RELAY ليرسم الكائن مساراً ضوئياً."},
		{"name":"CURVE — منحنى","detail":"اسحب في مسار منحني مفتوح. يضيف المختبر نمطاً مختلفاً إلى ذاكرة الكائن."},
		{"name":"LOOP — مدار","detail":"ارسم حلقة مغلقة حول SEED. VEYL يحولها إلى مجال حماية."},
		{"name":"PULSE TRAIN — قطار نبضات","detail":"انقر ECHO ثلاث مرات بسرعة. الإيقاع المتتابع يوقظ الإشارة."}
	]
	for entry in entries:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.07, 0.17, 0.96)))
		lessons.add_child(card)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 4)
		card.add_child(content)
		var heading := Label.new()
		heading.text = str(entry["name"])
		heading.add_theme_color_override("font_color", Color(0.58, 0.82, 1.0))
		heading.add_theme_font_size_override("font_size", 17)
		content.add_child(heading)
		var detail := Label.new()
		detail.text = str(entry["detail"])
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_color_override("font_color", Color(0.86, 0.89, 0.98))
		content.add_child(detail)
	var objective := Label.new()
	objective.text = "الترتيب في المرحلة الأخيرة: LUMA → RELAY، ثم مدار حول SEED، ثم ثلاث نقرات على ECHO. كل مرحلة تفتح بعد إكمال السابقة."
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_color_override("font_color", Color(1.0, 0.78, 0.45))
	lessons.add_child(objective)
	page.add_child(_main_button("العودة إلى القائمة", _build_home, true))

func _build_level_select() -> void:
	_clear_screen()
	var page := _new_page("رحلة الأحواض")
	var info := Label.new()
	info.text = "كل موطن يفتح بعد إكمال الذي قبله. اختر مرحلة متاحة."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", Color(0.70, 0.82, 1.0))
	page.add_child(info)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	var unlocked := int(SaveManager.data.get("unlocked_mission", 0))
	var completed: Array = SaveManager.data.get("completed_missions", [])
	for i in GameCatalogScript.MISSIONS.size():
		var mission: Dictionary = GameCatalogScript.MISSIONS[i]
		var is_unlocked := i <= unlocked
		var prefix := "✓  " if completed.has(i) else ("◈  " if is_unlocked else "🔒  ")
		var button := _main_button(prefix + str(i + 1) + ". " + str(mission["title"]), _open_game.bind("story", i), false, is_unlocked)
		list.add_child(button)
	list.add_child(_main_button("عودة للقائمة", _build_home))

func _start_daily() -> void:
	var date_string := Time.get_date_string_from_system()
	var index := GameCatalogScript.daily_mission_index(date_string)
	_open_game("daily", index)

func _build_journal() -> void:
	_clear_screen()
	var page := _new_page("سجل الاكتشافات")
	var discoveries: Array = SaveManager.data.get("discoveries", [])
	var counter := Label.new()
	counter.text = "اكتشفت %d بصمة مختلفة. هذا السجل محفوظ على جهازك فقط." % discoveries.size()
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	counter.add_theme_color_override("font_color", Color(0.72, 0.86, 1.0))
	page.add_child(counter)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	if discoveries.is_empty():
		var empty := Label.new()
		empty.text = "لا توجد اكتشافات بعد. ادخل المختبر أو العب أول مهمة لتسجيل بصمتك الأولى."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(empty)
	else:
		for item in discoveries:
			var row := PanelContainer.new()
			row.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.08, 0.18, 0.95)))
			var label := Label.new()
			label.text = "%s\n%s • %s • %s" % [str(item.get("id", "")), str(item.get("shape", "")), str(item.get("tempo", "")), str(item.get("date", ""))]
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_color_override("font_color", Color(0.86, 0.9, 1.0))
			row.add_child(label)
			list.add_child(row)
	var last: Dictionary = discoveries[discoveries.size() - 1] if not discoveries.is_empty() else {}
	var share := _main_button("نسخ رمز آخر اكتشاف", func():
		if not last.is_empty():
			DisplayServer.clipboard_set("NULL|%s|%s|%s" % [str(last.get("shape", "")), str(last.get("tempo", "")), str(last.get("direction", ""))])
			counter.text = "نُسخ الرمز. أرسله لصديق ليستورده في سجل الاكتشافات."
	)
	share.disabled = discoveries.is_empty()
	page.add_child(share)
	var import_input := LineEdit.new()
	import_input.placeholder_text = "ألصق رمز اكتشاف من لاعب آخر"
	import_input.clear_button_enabled = true
	page.add_child(import_input)
	page.add_child(_main_button("استيراد الرمز", func(): _import_discovery(import_input, counter)))
	page.add_child(_main_button("عودة للقائمة", _build_home))

func _import_discovery(input: LineEdit, message_label: Label) -> void:
	var parts := input.text.strip_edges().split("|")
	if parts.size() != 4 or parts[0] != "NULL":
		message_label.text = "الرمز غير صالح. الصيغة المطلوبة: NULL|shape|tempo|direction"
		return
	var valid_shapes := ["tap", "anchor", "swipe", "curve", "loop"]
	var valid_tempos := ["single", "double", "pulse_train"]
	var valid_directions := ["none", "left", "right", "up", "down"]
	if not valid_shapes.has(parts[1]) or not valid_tempos.has(parts[2]) or not valid_directions.has(parts[3]):
		message_label.text = "الرمز يحتوي على قيمة غير معروفة أو إصدار غير متوافق."
		return
	var signature := {"id":"%s-short-%s-%s" % [parts[1], parts[2], parts[3]],"shape":parts[1],"tempo":parts[2],"direction":parts[3]}
	var imported := SaveManager.record_discovery(signature)
	message_label.text = "أُضيف الاكتشاف إلى سجلك." if imported else "هذا الاكتشاف موجود في سجلك بالفعل."
	input.clear()

func _build_settings() -> void:
	_clear_screen()
	var page := _new_page("الإعدادات")
	var description := Label.new()
	description.text = "إعدادات وصول وتحكم محلية. لا توجد حسابات أو تتبّع أو خدمات مدفوعة."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color(0.72, 0.84, 1.0))
	page.add_child(description)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var settings_list := VBoxContainer.new()
	settings_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_list.add_theme_constant_override("separation", 12)
	scroll.add_child(settings_list)
	_add_setting_toggle(settings_list, "تقليل الحركة والمؤثرات", "reduced_motion")
	_add_setting_toggle(settings_list, "الصوت مفعّل", "sound_enabled")
	_add_setting_toggle(settings_list, "الاهتزاز عند اللمس", "haptics_enabled")
	_add_setting_toggle(settings_list, "الإيماءات المبسطة", "simplified_gestures")
	_add_setting_toggle(settings_list, "تباين بصري مرتفع", "high_contrast")
	_add_setting_toggle(settings_list, "تكبير أزرار الواجهة", "large_ui")
	var note := Label.new()
	note.text = "الإيماءات المبسطة توسّع هامش قبول المدار. التباين المرتفع يضيف حدوداً مضيئة، وتكبير الواجهة يزيد أحجام الأزرار. الاهتزاز يعمل على الأجهزة المحمولة المدعومة فقط."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color(0.62, 0.68, 0.84))
	settings_list.add_child(note)
	page.add_child(_main_button("عودة للقائمة", _build_home))

func _add_setting_toggle(parent: VBoxContainer, label_text: String, setting_key: String) -> void:
	var checkbox := CheckBox.new()
	checkbox.text = label_text
	checkbox.button_pressed = bool(SaveManager.get_setting(setting_key, false))
	checkbox.custom_minimum_size = Vector2(0, 52)
	checkbox.add_theme_font_size_override("font_size", 16 if bool(SaveManager.get_setting("large_ui", false)) else 14)
	checkbox.toggled.connect(func(value: bool):
		SaveManager.set_setting(setting_key, value)
	)
	parent.add_child(checkbox)

func _open_game(p_mode: String, p_stage_index: int) -> void:
	_clear_screen()
	current_game = GameScreenScene.new()
	current_game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_game.configure(p_mode, p_stage_index)
	current_game.exit_requested.connect(_build_home)
	current_game.restart_requested.connect(_open_game)
	add_child(current_game)

func _main_button(label_text: String, callback: Callable, emphasized: bool = false, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = label_text
	var ui_scale := 1.18 if bool(SaveManager.get_setting("large_ui", false)) else 1.0
	button.custom_minimum_size = Vector2(0, 64 * ui_scale)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = not enabled
	button.add_theme_font_size_override("font_size", int(round(18 * ui_scale)))
	button.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.55, 0.67))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.06, 0.11, 0.25, 0.95) if emphasized else Color(0.045, 0.07, 0.17, 0.96)))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.12, 0.19, 0.38, 1)))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.18, 0.12, 0.38, 1)))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.04, 0.045, 0.09, 0.86)))
	button.pressed.connect(callback)
	return button

func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.25, 0.45, 0.9, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(17)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	return style
