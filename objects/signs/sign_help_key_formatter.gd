extends Label
## DEPRECATED
## Formats a single [code]%s[/code] in [member text] with the current binding.[br]
## Prefer [InputRichTextLabel] for new UI — it supports multiple actions and gamepad icons.

@export var action: String = "m_jump"
@onready var _template: String = text

func _ready() -> void:
	Thunder._connect(SettingsManager.settings_saved, update_text)
	Thunder._connect(SettingsManager.settings_updated, update_text)
	Thunder._connect(SettingsManager.settings_loaded, update_text)
	Thunder._connect(SettingsManager.device_changed, update_text.unbind(1))
	Thunder._connect(Input.joy_connection_changed, update_text.unbind(2))
	update_text()


func update_text() -> void:
	if !"%s" in _template:
		return
	
	var _event := Thunder.input.get_input_plain_text(action)
	if SettingsManager.device_keyboard && !_event.to_lower().ends_with("button"):
		_event += " button"
	text = _template.replace("%s", _event)
