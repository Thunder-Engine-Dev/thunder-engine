extends Node2D

@export
var dot_style: SpriteFrames
@export
var player: NodePath

var to_level: String

func get_first_marker_space() -> MarkerSpace:
	var children = get_children()
	for child in children:
		if child is MarkerSpace:
			return child
	
	return null
