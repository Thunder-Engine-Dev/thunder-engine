extends MenuSelection

var device: bool = true # True is Keyboard, False is Joypad
@onready var value = $Value
var changing: bool = false

const toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")


func _handle_select() -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)
	
	if !get_parent().focused: return
	
	if device:
		value.texture.region.position.y = 60
	else:
		value.texture.region.position.y = 30
	
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("ui_left"):
		device = !device
		get_tree().call_group(&"_control_select_key", &"_toggle_device")
		Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
