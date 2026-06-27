extends Sprite2D

@export var custom_texture_name: String = "map_icon"

func _ready() -> void:
	texture = CharacterManager.get_misc_texture(custom_texture_name)
