extends MenuSelection

@export var action_names: PackedStringArray = []


func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)

	var actions := _actions_to_reset()
	if SettingsManager.device_keyboard:
		_reset_map(SettingsManager.settings.controls, SettingsManager.default_settings.controls, actions)
		SettingsManager._load_keys()
	else:
		_reset_map(SettingsManager.settings.controls_joypad, SettingsManager.default_settings.controls_joypad, actions)
		SettingsManager._load_joy_controls()


func _actions_to_reset() -> PackedStringArray:
	if !action_names.is_empty():
		return action_names

	var actions: PackedStringArray = []
	for child in get_parent().get_children():
		if child == self:
			continue
		if "action_name" in child && child.action_name:
			actions.append(child.action_name)
	return actions


func _reset_map(target: Dictionary, source: Dictionary, actions: PackedStringArray) -> void:
	for action in actions:
		if !source.has(action):
			continue
		var value: Variant = source[action]
		target[action] = value.duplicate() if value is Array else value
