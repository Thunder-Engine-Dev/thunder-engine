extends "res://engine/objects/bumping_blocks/message_block/message_block.gd"

signal choice_accepted
signal choice_canceled

@onready var text_2: Label = $CanvasLayer/Box/Texture/Text2
@onready var init_text := text_2.text


func _ready() -> void:
	if !"%s" in init_text: return
	Thunder._connect(SettingsManager.settings_saved, _set_text)
	_set_text()

func _set_text() -> void:
	var accept := SettingsManager.get_key_label(&"ui_accept")
	var cancel := SettingsManager.get_key_label(&"ui_cancel")
	text_2.text = init_text % [accept, cancel]


func _physics_process(delta: float) -> void:
	if !activated: return
	if !get_tree().paused:
		get_tree().paused = true
	if Input.is_action_just_pressed(&"ui_cancel"):
		hide_message()
		activated = false
		choice_canceled.emit()
		return
	if Input.is_action_just_pressed(&"ui_accept"):
		hide_message()
		activated = false
		choice_accepted.emit()
