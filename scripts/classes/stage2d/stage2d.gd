@tool
@icon("./icon.svg")
extends Node2D
class_name Stage2D

## Base stage/scene class[br]
## When the instance of the class gets notified with [member Node._ready], the instance
## will automatically call [method Scenes.register] to make [member Scenes.current_scene] work decently

func _ready() -> void:
	if !Engine.is_editor_hint():
		Scenes.load_scene(self)


## Fast method to call [method Scenes.reload_current_scene] in [Stage2D] and its extended classes
func restart() -> void:
	Scenes.reload_current_scene()
