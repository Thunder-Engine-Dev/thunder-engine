extends "res://engine/scripts/nodes/effects/quality_visible.gd"

@export var dot_style: SpriteFrames
@export var dot_offset: Vector2

@onready var old_dot_style: SpriteFrames = Scenes.current_scene.dot_style
@onready var old_sprite_offset: Vector2 = Scenes.current_scene.dot_sprite_offset


func _update_visibility() -> void:
	quality = SettingsManager.settings.quality
	var is_shown: bool = (
		(maximum && quality == QUALITY.MAX) ||
		(medium && quality == QUALITY.MID) ||
		(minimum && quality == QUALITY.MIN)
	)
	var sprite_frames: SpriteFrames = dot_style if is_shown else old_dot_style
	var offset: Vector2 = dot_offset if is_shown else old_sprite_offset
	Scenes.current_scene.dot_style = sprite_frames
	Scenes.current_scene.dot_sprite_offset = offset
	
	for node in get_tree().get_nodes_in_group(&"map_dot"):
		node.sprite_frames = sprite_frames
		node.offset = offset
		node.play()
