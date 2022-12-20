# Base level node

@tool
extends Stage2D
class_name Level
@icon("./icon.svg")

func _ready() -> void:
	if Engine.is_editor_hint(): prepare_template()


# Adding neccessary nodes to our level scene
func prepare_template() -> void:
	var tilemap = TileMap.new()
	add_child(tilemap)
