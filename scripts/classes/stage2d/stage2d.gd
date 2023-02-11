# Base stage class
@tool
@icon("./icon.svg")
extends Node2D
class_name Stage2D

func _ready() -> void:
	if !Engine.is_editor_hint():
		Scenes.register(self)


func restart() -> void:
	Scenes.reload_current_scene()
