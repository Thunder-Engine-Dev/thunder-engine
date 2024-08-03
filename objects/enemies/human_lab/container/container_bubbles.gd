@tool
extends Sprite2D

@export var sprite: Texture2D

@onready var sprite_2d: Sprite2D = $Node2D/Sprite2D

func _ready() -> void:
	sprite_2d.texture = sprite
