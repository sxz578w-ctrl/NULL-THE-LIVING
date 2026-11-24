extends CanvasLayer

signal pulse_choice_requested(choice: String)
signal build_requested(slot_id: String, building_type: String)
signal language_changed(language: String)
signal pause_toggled(paused: bool)

var status_label: Label
var stats_label: Label
var health_bar: ProgressBar
var objective_label: Label
var title_label: Label
var language_button: Button
var choice_panel: PanelContainer
var choice_box: VBoxContainer
var pause_panel: PanelContainer
var paused: bool = false
var current_language: String = "ar"
var active_slot: String = ""
var last_resources: Dictionary = {"scrap": 30, "flux": 8, "echo": 0}
var last_health: float = 100.0
var last_zone: Dictionary = {"stability": 45, "danger": 55}
var last_puzzle_progress: int = 0

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	TranslationServer.set_locale(current_language)
	_build_hud()

func _panel_style(panel: PanelContainer, color: Color = Color(0.04, 0.08, 0.11, 0.94)) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.22, 0.72, 0.7, 0.82)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(20.0, 18.0)
	top_panel.custom_minimum_size = Vector2(390.0, 112.0)
	_panel_style(top_panel)
	root.add_child(top_panel)

	var stack := VBoxContainer.new()
	top_panel.add_child(stack)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.26, 0.84, 0.8))
	stack.add_child(title_label)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 15)
	stack.add_child(stats_label)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(320.0, 10.0)
	health_bar.min_value = 0.0
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.show_percentage = false
	stack.add_child(health_bar)

	objective_label = Label.new()
	objective_label.position = Vector2(440.0, 30.0)
	objective_label.custom_minimum_size = Vector2(430.0, 44.0)
	objective_label.add_theme_font_size_override("font_size", 17)
	objective_label.add_theme_color_override("font_color", Color(0.86, 0.94, 0.93))
	root.add_child(objective_label)

	language_button = Button.new()
	language_button.position = Vector2(1135.0, 22.0)
	language_button.custom_minimum_size = Vector2(110.0, 48.0)
	root.add_child(language_button)
	language_button.pressed.connect(_toggle_language)

	choice_panel = PanelContainer.new()
	choice_panel.anchor_left = 0.5
	choice_panel.anchor_right = 0.5
	choice_panel.anchor_top = 0.5
	choice_panel.anchor_bottom = 0.5
	choice_panel.offset_left = -205.0
	choice_panel.offset_top = -150.0
	choice_panel.offset_right = 205.0
	choice_panel.offset_bottom = 150.0
	_panel_style(choice_panel, Color(0.025, 0.05, 0.07, 0.97))
	root.add_child(choice_panel)
	choice_box = VBoxContainer.new()
	choice_panel.add_child(choice_box)
	choice_panel.visible = false

	status_label = Label.new()
	status_label.anchor_left = 0.0
	status_label.anchor_right = 0.0
	status_label.anchor_top = 1.0
	status_label.anchor_bottom = 1.0
	status_label.offset_left = 240.0
	status_label.offset_top = -74.0
	status_label.offset_right = 740.0
	status_label.offset_bottom = -25.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.93))
	root.add_child(status_label)

	pause_panel = PanelContainer.new()
	pause_panel.anchor_left = 0.5
	pause_panel.anchor_right = 0.5
	pause_panel.anchor_top = 0.5
	pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -150.0
	pause_panel.offset_top = -100.0
	pause_panel.offset_right = 150.0
	pause_panel.offset_bottom = 100.0
	_panel_style(pause_panel)
	root.add_child(pause_panel)
	var pause_box := VBoxContainer.new()
	pause_panel.add_child(pause_box)
	var pause_title := Label.new()
	pause_title.name = "PauseTitle"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_box.add_child(pause_title)
	var resume := Button.new()
	resume.name = "ResumeButton"
	pause_box.add_child(resume)
	resume.pressed.connect(func() -> void: set_paused(false))
	var pause_language := Button.new()
	pause_language.text = "AR / EN"
	pause_box.add_child(pause_language)
	pause_language.pressed.connect(_toggle_language)
	pause_panel.visible = false

	_apply_language()

func update_stats(resources: Dictionary, health: float, zone: Node, puzzle_progress: int) -> void:
	last_resources = resources.duplicate(true)
	last_health = health
	last_zone = {"stability": int(zone.get("stability")), "danger": int(zone.get("danger"))}
	last_puzzle_progress = puzzle_progress
	_refresh_stats()

func _refresh_stats() -> void:
	if stats_label == null:
		return
	if current_language == "ar":
		stats_label.text = "خردة %d   طاقة %d   صدى %d   صحة %d%%" % [
			int(last_resources.get("scrap", 0)),
			int(last_resources.get("flux", 0)),
			int(last_resources.get("echo", 0)),
			roundi(last_health)
		]
		objective_label.text = "استقرار %d   خطر %d   النواة %d/3" % [
			int(last_zone.get("stability", 0)),
			int(last_zone.get("danger", 0)),
			last_puzzle_progress
		]
	else:
		stats_label.text = "SCRAP %d   FLUX %d   ECHO %d   HP %d%%" % [
			int(last_resources.get("scrap", 0)),
			int(last_resources.get("flux", 0)),
			int(last_resources.get("echo", 0)),
			roundi(last_health)
		]
		objective_label.text = "STABILITY %d   DANGER %d   CORE %d/3" % [
			int(last_zone.get("stability", 0)),
			int(last_zone.get("danger", 0)),
			last_puzzle_progress
		]
	health_bar.value = clampf(last_health, 0.0, 100.0)

func show_message(message: String) -> void:
	if status_label != null:
		status_label.text = message

func show_pulse_choices(visible: bool) -> void:
	_clear_choice_panel()
	choice_panel.visible = visible
	if not visible:
		return
	var title := Label.new()
	title.text = "نبضة العالم — اختر مصير المنطقة" if current_language == "ar" else "WORLD PULSE — Choose this zone's future"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_box.add_child(title)
	if current_language == "ar":
		_add_choice_button("تثبيت المنطقة — ANCHOR", "anchor")
		_add_choice_button("حصاد الموارد — HARVEST", "harvest")
		_add_choice_button("فتح مسار — REFRACT", "refract")
	else:
		_add_choice_button("ANCHOR — Stabilize zone", "anchor")
		_add_choice_button("HARVEST — High resource yield", "harvest")
		_add_choice_button("REFRACT — Open a new route", "refract")

func show_build_choices(slot_id: String) -> void:
	active_slot = slot_id
	_clear_choice_panel()
	choice_panel.visible = true
	var title := Label.new()
	title.text = ("منصة البناء: " if current_language == "ar" else "BUILD SLOT: ") + slot_id.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_box.add_child(title)
	if current_language == "ar":
		_add_build_button("مستخلص — 12 خردة + 2 طاقة", "extractor")
		_add_build_button("مرحل — 15 خردة + 2 صدى", "relay")
		_add_build_button("برج دفاع — 18 خردة + 4 طاقة", "turret")
		_add_cancel_button("إلغاء")
	else:
		_add_build_button("EXTRACTOR | 12 SCRAP + 2 FLUX", "extractor")
		_add_build_button("RELAY | 15 SCRAP + 2 ECHO", "relay")
		_add_build_button("TURRET | 18 SCRAP + 4 FLUX", "turret")
		_add_cancel_button("CANCEL")

func _clear_choice_panel() -> void:
	for child in choice_box.get_children():
		child.queue_free()

func _add_choice_button(text_value: String, choice: String) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(350.0, 48.0)
	choice_box.add_child(button)
	button.pressed.connect(func() -> void:
		choice_panel.visible = false
		pulse_choice_requested.emit(choice)
	)

func _add_build_button(text_value: String, building_type: String) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(350.0, 46.0)
	choice_box.add_child(button)
	button.pressed.connect(func() -> void:
		choice_panel.visible = false
		build_requested.emit(active_slot, building_type)
	)

func _add_cancel_button(text_value: String) -> void:
	var button := Button.new()
	button.text = text_value
	choice_box.add_child(button)
	button.pressed.connect(func() -> void: choice_panel.visible = false)

func toggle_pause() -> void:
	set_paused(not paused)

func set_paused(value: bool) -> void:
	paused = value
	get_tree().paused = value
	if pause_panel != null:
		pause_panel.visible = value
		var title := pause_panel.find_child("PauseTitle", true, false) as Label
		var resume := pause_panel.find_child("ResumeButton", true, false) as Button
		if title != null:
			title.text = "متوقف مؤقتاً" if current_language == "ar" else "PAUSED"
		if resume != null:
			resume.text = "متابعة" if current_language == "ar" else "RESUME"
	pause_toggled.emit(value)

func set_language(language: String) -> void:
	if not ["ar", "en"].has(language):
		return
	current_language = language
	TranslationServer.set_locale(language)
	_apply_language()
	_refresh_stats()
	language_changed.emit(language)

func _apply_language() -> void:
	if title_label == null:
		return
	var direction := Control.LAYOUT_DIRECTION_RTL if current_language == "ar" else Control.LAYOUT_DIRECTION_LTR
	if title_label.get_parent() != null:
		(title_label.get_parent() as Control).layout_direction = direction
	title_label.layout_direction = direction
	title_label.text = "AFTERZERO  //  القطاع 01" if current_language == "ar" else "AFTERZERO  //  SECTOR 01"
	language_button.text = "العربية" if current_language == "ar" else "ENGLISH"
	objective_label.layout_direction = direction
	stats_label.layout_direction = direction
	status_label.layout_direction = direction
	var pause_title := pause_panel.find_child("PauseTitle", true, false) as Label
	var resume := pause_panel.find_child("ResumeButton", true, false) as Button
	if pause_title != null:
		pause_title.text = "متوقف مؤقتاً" if current_language == "ar" else "PAUSED"
	if resume != null:
		resume.text = "متابعة" if current_language == "ar" else "RESUME"

func _toggle_language() -> void:
	set_language("en" if current_language == "ar" else "ar")
