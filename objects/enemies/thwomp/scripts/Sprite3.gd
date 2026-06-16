extends AnimatedSprite2D

@onready var spr: AnimatedSprite2D = $".." as AnimatedSprite2D

func _on_sprite_frame_changed() -> void:
	#frame = spr.frame
	pass


func _on_sprite_animation_changed() -> void:
	animation = spr.animation
