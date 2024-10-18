extends MenuSelection

const toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")
const DOUBLE_POS = 114
const TRIPLE_POS = 190

@onready var _value: TextureRect = $HBoxContainer/Value
@onready var _buffer: TextureRect = $HBoxContainer/Buffer
@onready var _off: TextureRect = $HBoxContainer/OFF
var _saved_value: int

func _ready() -> void:
	SettingsManager.settings_updated.connect(set.bind(&"_saved_value", SettingsManager.settings.vsync))

func _handle_select(mouse_input: bool = false) -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)
	_value.texture.region.position.y = DOUBLE_POS if int(SettingsManager.settings.vsync) == 1 else TRIPLE_POS
	_buffer.texture.region.position.y = 0 if int(SettingsManager.settings.vsync) == 1 else 35
	
	_value.visible  = SettingsManager.settings.vsync
	_buffer.visible = SettingsManager.settings.vsync
	_off.visible    = !SettingsManager.settings.vsync
	
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right"):
		var old_value := int(SettingsManager.settings.vsync)
		SettingsManager.settings.vsync = clamp(old_value + 1, 0, 2)
		_toggled_option(old_value, SettingsManager.settings.vsync)
		
	if Input.is_action_just_pressed("ui_left"):
		var old_value := int(SettingsManager.settings.vsync)
		SettingsManager.settings.vsync = clamp(old_value - 1, 0, 2)
		_toggled_option(old_value, SettingsManager.settings.vsync)


func _toggled_option(old_val, new_val) -> void:
	if old_val == new_val: return
	Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
	SettingsManager.request_restart = (
		new_val > 0 &&
		new_val != _saved_value
	)
	SettingsManager._process_settings()
