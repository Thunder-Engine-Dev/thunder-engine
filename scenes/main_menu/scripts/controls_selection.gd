extends MenuSelection

@export var action_name: String
@export var enable_cancel: bool = true
@onready var value = $Value
var changing: bool = false

const change_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")


func _physics_process(delta: float) -> void:
	super(delta)
	
	if !changing:
		value.text = SettingsManager.settings.controls[action_name]
	else:
		value.text = "..."
	
	if !focused:
		changing = false


func _handle_select() -> void:
	if !changing:
		changing = true
		get_parent().focused = false
		super()


func _input(event) -> void:
	if event is InputEventKey && event.pressed && changing && !event.echo:
		if !event.is_action('ui_cancel') || !enable_cancel:
			var scancode = event.as_text()
			SettingsManager.settings.controls[action_name] = scancode
			SettingsManager._load_keys()
			Audio.play_1d_sound(change_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
		changing = false
		
		# should be changed, crutch.
		await get_tree().physics_frame
		await get_tree().physics_frame
		
		get_parent().focused = true
