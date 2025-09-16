extends PointLight2D

@export var final_value: float = 1.0
@export var duration: float = 0.2
@export var stage2d_vis_controlled: bool = true

func _ready() -> void:
	if stage2d_vis_controlled:
		add_to_group(&"stage2d_ctrl_light")
		if !Scenes.current_scene.get(&"is_lighting_visible"):
			hide()
			texture_scale = final_value
			return
	texture_scale = 0.01
	create_tween().tween_property(self, ^"texture_scale", final_value, duration)
