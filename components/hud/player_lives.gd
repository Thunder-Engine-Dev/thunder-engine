extends Label

@export var value_name: String

func _ready() -> void:
	assert(value_name in Data.values, "Value " + value_name + " does not exist in Data.values dictionary.")
	_update_text.call_deferred()


func _physics_process(delta) -> void:
	_update_text()


func _update_text() -> void:
	var value = Data.values[value_name]
	text = "%s ~ %s" % [CharacterManager.get_character_display_name(), value]
