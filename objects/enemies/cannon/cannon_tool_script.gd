@tool
extends Node

var par: Node2D


func _ready() -> void:
	if !Engine.is_editor_hint():
		queue_free()
		return
	
	par = get_parent()
	par.property_list_changed.connect(print.bind("Test!"))
