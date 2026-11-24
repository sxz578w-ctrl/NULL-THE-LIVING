extends CanvasLayer

signal movement_changed(value: Vector2)
signal attack_pressed
signal dash_pressed
signal interact_pressed
signal pause_pressed

var touch_index: int = -1
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_value: Vector2 = Vector2.ZERO
var screen_size: Vector2 = Vector2(1280.0, 720.0)
var action_buttons: Dictionary = {}
var pause_button: Button
var current_language: String = "ar"

func _ready() -> void:
	layer = 20
	screen_size = get_viewport().get_visible_rect().size
	_create_joystick_hint()
	_create_button("attack", Vector2(-112.0, -108.0), attack_pressed.emit)
	_create_button("dash", Vector2(-222.0, -70.0), dash_pressed.emit)
	_create_button("interact", Vector2(-112.0, -220.0), interact_pressed.emit)
	_create_pause_button()
	set_language(current_language)

func _create_joystick_hint() -> void:
	var panel := Panel.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 34.0
	panel.offset_top = -194.0
	panel.offset_right = 194.0
	panel.offset_bottom = -34.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.13, 0.17, 0.25)
	style.border_color = Color(0.25, 0.78, 0.75, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(80)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

func _create_button(role: String, offset: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(94.0, 76.0)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = offset.x
	button.offset_top = offset.y
	button.offset_right = offset.x + 94.0
	button.offset_bottom = offset.y + 76.0
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.92, 0.97, 0.98))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.13, 0.17, 0.91)
	style.border_color = Color(0.25, 0.78, 0.75, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	button.add_theme_stylebox_override("normal", style)
	add_child(button)
	action_buttons[role] = button
	button.pressed.connect(callback)

func _create_pause_button() -> void:
	pause_button = Button.new()
	pause_button.anchor_left = 1.0
	pause_button.anchor_right = 1.0
	pause_button.anchor_top = 0.0
	pause_button.anchor_bottom = 0.0
	pause_button.offset_left = -66.0
	pause_button.offset_top = 22.0
	pause_button.offset_right = -20.0
	pause_button.offset_bottom = 68.0
	pause_button.add_theme_font_size_override("font_size", 22)
	add_child(pause_button)
	pause_button.pressed.connect(pause_pressed.emit)

func set_language(language: String) -> void:
	current_language = language
	var labels := {
		"ar": {"attack": "هجوم", "dash": "اندفاع", "interact": "تفاعل", "pause": "Ⅱ"},
		"en": {"attack": "ATTACK", "dash": "DASH", "interact": "USE", "pause": "Ⅱ"}
	}
	var chosen: Dictionary = labels.get(current_language, labels["ar"])
	for role: Variant in action_buttons.keys():
		var button: Button = action_buttons[role]
		button.text = str(chosen[role])
		button.layout_direction = Control.LAYOUT_DIRECTION_RTL if current_language == "ar" else Control.LAYOUT_DIRECTION_LTR
	pause_button.text = str(chosen["pause"])

func _input(event: InputEvent) -> void:
	screen_size = get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch_index == -1 and touch.position.x < screen_size.x * 0.43 and touch.position.y > screen_size.y * 0.35:
			touch_index = touch.index
			joystick_origin = touch.position
			joystick_value = Vector2.ZERO
			movement_changed.emit(joystick_value)
		elif not touch.pressed and touch.index == touch_index:
			touch_index = -1
			joystick_value = Vector2.ZERO
			movement_changed.emit(joystick_value)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == touch_index:
			var delta := drag.position - joystick_origin
			joystick_value = (delta / 76.0).limit_length(1.0)
			movement_changed.emit(joystick_value)

func _process(_delta: float) -> void:
	if touch_index == -1:
		var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		movement_changed.emit(keyboard)
