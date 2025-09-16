extends Label

@export var action: String = "m_jump"
@onready var _template: String = text

func _ready() -> void:
	update_text()
	SettingsManager.settings_saved.connect(update_text)


func update_text() -> void:
	var _events: Array[InputEvent] = InputMap.action_get_events(action)
	var _event: String = "buttons on keyboard"
	var _temp: String
	for i in _events:
		if i is InputEventKey:
			_temp = i.as_text().get_slice(' (', 0) + ' button'
			#if SettingsManager.device_keyboard:
			_event = _temp
			break
		#elif i is InputEventJoypadButton:
		#	_temp = "Joy " + str(i.button_index)
		if _temp: _event = _temp
	
	text = _template % [_event]
