@icon("res://engine/scenes/map/textures/icons/branch.svg")
@tool
extends Node2D

signal changed

var dots: Array

func _ready() -> void:
	if is_in_group("map_branch"):
		add_to_group("map_branch")
	
	set_notify_transform(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		changed.emit()

