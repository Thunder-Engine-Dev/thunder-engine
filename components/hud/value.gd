extends Label

var value_template: String
@export var value_name: String
@export var floor_value: bool = false

func _ready() -> void:
	value_template = text
	assert(value_name in Data.values, "Value " + value_name + " does not exist in Data.values dictionary.")
	_update_text.call_deferred()


func _physics_process(delta) -> void:
	_update_text()


func _update_text() -> void:
	var value = Data.values[value_name] if !floor_value else floor(Data.values[value_name])
	text = value_template % value
