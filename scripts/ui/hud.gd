extends CanvasLayer

signal pulse_choice_requested(choice: String)
signal build_requested(slot_id: String, building_type: String)
signal language_changed(language: String)
signal pause_toggled(paused: bool)

var status_label: Label
var stats_label: Label
var objective_label: Label
var choice_panel: PanelContainer
var choice_box: VBoxContainer
var paused: bool = false
var current_language: String = "ar"
var active_slot: String = ""

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	top_panel.custom_minimum_size = Vector2(390.0, 94.0)
	_panel_style(top_panel)
	root.add_child(top_panel)

	var stack := VBoxContainer.new()
	top_panel.add_child(stack)
	var title := Label.new()
	title.text = "AFTERZERO  //  SECTOR 01"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.26, 0.84, 0.8))
	stack.add_child(title)

	stats_label = Label.new()
	stats_label.text = "SCRAP 30   FLUX 8   ECHO 0"
	stats_label.add_theme_font_size_override("font_size", 16)
	stack.add_child(stats_label)

	objective_label = Label.new()
	objective_label.text = "الهدف: اجمع الموارد وافحص موصلات النواة"
	objective_label.add_theme_font_size_override("font_size", 17)
	objective_label.position = Vector2(430.0, 26.0)
	objective_label.custom_minimum_size = Vector2(450.0, 44.0)
	root.add_child(objective_label)

	var lang_button := Button.new()
	lang_button.text = "AR / EN"
	lang_button.position = Vector2(1135.0, 22.0)
	lang_button.custom_minimum_size = Vector2(110.0, 48.0)
	root.add_child(lang_button)
	lang_button.pressed.connect(_toggle_language)

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

	var pause_panel := PanelContainer.new()
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
	pause_title.text = "PAUSED / متوقف"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_box.add_child(pause_title)
	var resume := Button.new()
	resume.text = "RESUME / متابعة"
	pause_box.add_child(resume)
	resume.pressed.connect(func() -> void: set_paused(false))
	var language := Button.new()
	language.text = "AR / EN"
	pause_box.add_child(language)
	language.pressed.connect(_toggle_language)
	pause_panel.visible = false
	set_meta("pause_panel", pause_panel)

func update_stats(resources: Dictionary, health: float, zone: Node, puzzle_progress: int) -> void:
	if stats_label == null:
		return
	var prefix := "SCRAP %d   FLUX %d   ECHO %d" % [
		int(resources.get("scrap", 0)),
		int(resources.get("flux", 0)),
		int(resources.get("echo", 0))
	]
	stats_label.text = prefix + "   HP %d%%" % roundi(health)
	var pulse_text := "STABILITY %d   DANGER %d   CORE %d/3" % [
		int(zone.stability), int(zone.danger), puzzle_progress
	]
	objective_label.text = pulse_text if current_language == "en" else "استقرار %d   خطر %d   النواة %d/3" % [
		int(zone.stability), int(zone.danger), puzzle_progress
	]

func show_message(message: String) -> void:
	if status_label != null:
		status_label.text = message

func show_pulse_choices(visible: bool) -> void:
	_clear_choice_panel()
	choice_panel.visible = visible
	if not visible:
		return
	var title := Label.new()
	title.text = "WORLD PULSE  /  اختر مصير المنطقة"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_box.add_child(title)
	_add_choice_button("ANCHOR — تثبيت المنطقة", "anchor")
	_add_choice_button("HARVEST — حصاد الموارد", "harvest")
	_add_choice_button("REFRACT — فتح مسار جديد", "refract")

func show_build_choices(slot_id: String) -> void:
	active_slot = slot_id
	_clear_choice_panel()
	choice_panel.visible = true
	var title := Label.new()
	title.text = "BUILD SLOT: " + slot_id.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_box.add_child(title)
	_add_build_button("EXTRACTOR  |  12 SCRAP + 2 FLUX", "extractor")
	_add_build_button("RELAY  |  15 SCRAP + 2 ECHO", "relay")
	_add_build_button("TURRET  |  18 SCRAP + 4 FLUX", "turret")
	_add_cancel_button()

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

func _add_cancel_button() -> void:
	var button := Button.new()
	button.text = "CANCEL / إلغاء"
	choice_box.add_child(button)
	button.pressed.connect(func() -> void: choice_panel.visible = false)

func toggle_pause() -> void:
	set_paused(not paused)

func set_paused(value: bool) -> void:
	paused = value
	get_tree().paused = value
	var pause_panel := get_meta("pause_panel") as PanelContainer
	if pause_panel != null:
		pause_panel.visible = value
	pause_toggled.emit(value)

func _toggle_language() -> void:
	current_language = "en" if current_language == "ar" else "ar"
	language_changed.emit(current_language)
