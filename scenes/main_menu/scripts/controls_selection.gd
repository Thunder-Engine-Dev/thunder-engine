extends MenuSelection

@export var action_name: String
@export var enable_cancel: bool = true
@onready var value: Label = $Value
@onready var icon: TextureRect = $Icon

var changing: bool = false

const change_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

func _ready() -> void:
	icon.texture.region.size = Vector2(32, 32)


func _physics_process(delta: float) -> void:
	super(delta)

	if get_parent().focused:
		_text_process()

	if !focused:
		changing = false


func _handle_select(mouse_input: bool = false) -> void:
	if !changing:
		changing = true
		icon.visible = false
		get_parent().focused = false
		value.text = "..."
		super(mouse_input)


func _text_process() -> void:
	if changing:
		value.text = "..."
		return

	if SettingsManager.device_keyboard:
		value.text = SettingsManager.settings.controls[action_name]
		icon.visible = false
		return

	if _device_check(["xbox", "xinput"]):
		_gamepad_icon_logic(
			preload("res://engine/scenes/main_menu/textures/gamepad_icons/xbox_icons.png"),
			15
		)
	elif _device_check(["ps3", "ps4", "ps5", "dualshock", "playstation 3", "playstation 4", "playstation 5"]):
		_gamepad_icon_logic(
			preload("res://engine/scenes/main_menu/textures/gamepad_icons/ps_icons.png"),
			20,
			[-1, 5, 16, 17, 18, 19, 48, 50]
		)
	#elif _device_check(["nintendo switch"]):
	#	_gamepad_icon_logic(
	#		preload("res://engine/scenes/main_menu/textures/gamepad_icons/switch_icons.png"),
	#		15
	#	)
	else:
		icon.visible = false
		value.text = "Joy " + str(SettingsManager.settings.controls_joypad[action_name])


func _device_check(arr: Array[String]) -> bool:
	for i in len(arr):
		if arr[i] in SettingsManager.device_name.to_lower():
			return true
	return false


func _gamepad_icon_logic(texture: Texture2D, max_icons: int = 15, icon_exceptions: Array[int] = [-1, 48, 50]) -> void:
	var icon_index: int = SettingsManager.settings.controls_joypad[action_name]
	if (icon_index > max_icons && icon_index < 40) || icon_index > 51 || icon_index in icon_exceptions:
		icon.visible = false
		value.text = "Joy " + str(icon_index)
		if icon_index == -1:
			value.text = "Joy Unknown"
		return
	value.text = ""
	icon.texture.atlas = texture
	var icon_unit: int = icon_index * 32
	icon.texture.region.position.x = wrapi(icon_unit, 0, 320)
	icon.texture.region.position.y = floor(icon_index / 10.0) * 32
	icon.visible = true


func _input(event) -> void:
	if !changing:
		return

	if event is InputEventKey && event.pressed && !event.echo:
		if SettingsManager.device_keyboard && (!event.is_action('ui_cancel') || !enable_cancel):
			var scancode = event.as_text()
			SettingsManager.settings.controls[action_name] = scancode
			SettingsManager._load_keys()
			Audio.play_1d_sound(change_sound, true, { "ignore_pause": true, "bus": "1D Sound" })

		_after_change()
	elif event is InputEventJoypadButton && event.is_pressed():
		if !SettingsManager.device_keyboard:
			SettingsManager.settings.controls_joypad[action_name] = event.button_index
			SettingsManager._load_keys()
			Audio.play_1d_sound(change_sound, true, { "ignore_pause": true, "bus": "1D Sound" })

		_after_change()
	elif event is InputEventJoypadMotion && abs(event.axis_value) >= 0.5 && !SettingsManager.device_keyboard:
		SettingsManager.settings.controls_joypad[action_name] = 40 + (event.axis * 2) + (0 if signf(event.axis_value) < 0 else 1)
		SettingsManager._load_keys()
		Audio.play_1d_sound(change_sound, true, { "ignore_pause": true, "bus": "1D Sound" })

		_after_change()


func _after_change() -> void:
	changing = false

	# should be changed, crutch.
	await get_tree().physics_frame
	await get_tree().physics_frame

	get_parent().focused = true
