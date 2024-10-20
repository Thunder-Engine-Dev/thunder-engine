extends MenuSelection

@export var type: String
@onready var value: ProgressBar = $Value

var change_sound = preload("res://engine/components/hud/sounds/scoring.wav")
var _mouse_can_process: bool = false

func _ready() -> void:
	SettingsManager.mouse_released.connect(_on_mouse_released)


func _handle_select(mouse_input: bool = false) -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)
	
	$Value.value = SettingsManager.settings[type] * 10
	
	if !focused || !get_parent().focused: return
	var old_value = SettingsManager.settings[type]
	
	if Input.is_action_just_pressed("ui_right"):
		SettingsManager.settings[type] = clamp(old_value + 0.1, 0, 1)
		_toggled_option(old_value, SettingsManager.settings[type])
		
	if Input.is_action_just_pressed("ui_left"):
		SettingsManager.settings[type] = clamp(old_value - 0.1, 0, 1)
		_toggled_option(old_value, SettingsManager.settings[type])
	
	if !_mouse_can_process: return
	
	var rect: Rect2 = value.get_global_rect()
	rect.size.x += 48
	if rect.has_point(value.get_global_mouse_position()) && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		SettingsManager.settings[type] = clamp(
			round((value.get_global_mouse_position().x - rect.position.x) / 10.0) / 10.0,
			0,
			1
		)
		_toggled_option(old_value, SettingsManager.settings[type])


func _toggled_option(old_val, new_val) -> void:
	if old_val == new_val: return
	Audio.play_1d_sound(change_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
	SettingsManager._process_settings()
	

func _on_mouse_released(index: MouseButton) -> void:
	if index != MOUSE_BUTTON_LEFT: return
	
	_mouse_can_process = get_parent().focused
	
