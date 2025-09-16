extends MenuSelection

const DEFAULT_SCORING = preload("res://engine/components/hud/sounds/scoring.wav")

@export var type: String
@export var change_sound := DEFAULT_SCORING
@onready var value: ProgressBar = $Value

var _mouse_can_process: bool = false
var selector_repeat_timer: float

func _ready() -> void:
	SettingsManager.mouse_released.connect(_on_mouse_released)


func _handle_select(mouse_input: bool = false) -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)
	
	$Value.value = SettingsManager.settings[type] * 10
	
	if !focused || !get_parent().focused: return
	if selector_repeat_timer > 0: selector_repeat_timer -= delta
	var old_value = SettingsManager.settings[type]
	
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

func _input(event: InputEvent) -> void:
	if !focused || !get_parent().focused: return
	if !event.is_pressed(): return
	if event.is_echo():
		if selector_repeat_timer > 0:
			return
		else:
			selector_repeat_timer = 0.06
	
	var old_value = SettingsManager.settings[type]
	if event.is_action("ui_right"):
		SettingsManager.settings[type] = clampf(old_value + 0.1, 0.0, 1.0)
		_toggled_option(old_value, SettingsManager.settings[type])
		
	if event.is_action("ui_left"):
		SettingsManager.settings[type] = clampf(old_value - 0.1, 0.0, 1.0)
		_toggled_option(old_value, SettingsManager.settings[type])


func _toggled_option(old_val, new_val) -> void:
	if old_val == new_val: return
	var _sfx = CharacterManager.get_sound_replace(change_sound, DEFAULT_SCORING, "menu_select_short", false)
	Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })
	SettingsManager._process_settings()
	

func _on_mouse_released(index: MouseButton) -> void:
	if index != MOUSE_BUTTON_LEFT: return
	
	_mouse_can_process = get_parent().focused
	
