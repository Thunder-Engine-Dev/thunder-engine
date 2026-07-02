extends Projectile

const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")

@onready var vision: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var attack: ShapeCast2D = $Attack

func _ready() -> void:
	super()
	if speed.x < 0 && sprite_node:
		sprite_node.rotation_speed = -sprite_node.rotation_speed
	
	if sprite_node:
		attack.set_deferred(&"enabled", false)
		var tw = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tw.tween_property(sprite_node, "scale", Vector2.ONE, 0.05)
		tw.tween_callback(func():
			if is_instance_valid(attack):
				attack.set_deferred(&"enabled", true)
		)

func explode():
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()

func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 2048):
			queue_free()
		return
	Data.add_score(200)
	ScoreText.new(str(200), self)
	queue_free()

func _physics_process(delta: float) -> void:
	super(delta)
	var cam = Thunder._current_camera
	if !Thunder.view.screen_top(point_light_2d.global_position, 0, false):
		point_light_2d.global_position.y = cam.get_screen_center_position().y - (cam.get_viewport_rect().size.y / 2)
		point_light_2d.reset_physics_interpolation()
		point_light_2d.color.a = 1
	else:
		point_light_2d.position.y = 0
		if speed.y > 20:
			if point_light_2d.color.a > 0:
				point_light_2d.color.a = move_toward(point_light_2d.color.a, 0, delta * 8)
			else:
				point_light_2d.enabled = false
