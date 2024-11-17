extends Label

@export var value_name: String

func _ready() -> void:
	assert(value_name in Data.values, "Value " + value_name + " does not exist in Data.values dictionary.")
	_update_text.call_deferred()


func _physics_process(delta) -> void:
	_update_text()


func _update_text() -> void:
	var value = Data.values[value_name]
	var character: String = SkinsManager.current_skin.left(15)
	if character.is_empty():
		character = SettingsManager.settings.character
	text = "%s ~ %s" % [character, value]
