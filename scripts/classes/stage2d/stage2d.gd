# Base stage class
@tool
@icon("./icon.svg")
extends Node2D
class_name Stage2D

func _ready() -> void:
	Thunder._current_stage = self


func restart() -> void:
	get_tree().reload_current_scene()
