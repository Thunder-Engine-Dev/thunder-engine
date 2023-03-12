extends Label

var value_template: String
@export var value_name: String

func _ready() -> void:
	value_template = text
	assert(value_name in Data.values, "Value " + value_name + " does not exist in Data.values dictionary.")
	_update_text()


func _physics_process(delta) -> void:
	_update_text()


func _update_text() -> void:
	text = value_template % Data.values[value_name]
