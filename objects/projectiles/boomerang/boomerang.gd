extends Projectile

const enemy_mode_texture = preload("res://engine/objects/projectiles/boomerang/textures/boomerang_enemy.png")
const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")

@export_range(0, 20, 0.1, "hide_slider", "suffix:s") var trail_emitting_interval: float = 0.4

var flag: bool = false

@onready var vision: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var area_2d: Area2D = $Area2D


func _ready() -> void:
	add_to_group(&"end_level_sequence")
	await get_tree().physics_frame
	dir = sign(speed.x)
	
	if belongs_to == Data.PROJECTILE_BELONGS.ENEMY:
		if !vision.is_on_screen():
			queue_free()
			return
		vision.screen_exited.connect(queue_free)
		
	if sprite_node is Sprite2D:
		sprite_node.texture = sprite_node.texture if belongs_to == Data.PROJECTILE_BELONGS.PLAYER else enemy_mode_texture

func _physics_process(delta: float) -> void:
	super(delta)
	delta = Thunder.get_delta(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 12 * dir * delta
	
	if !flag:
		if speed.y < 200:
			speed.y += 15 * delta
		else:
			flag = true
			if !vision.is_on_screen():
				queue_free()
				return
			vision.screen_exited.connect(queue_free)
	else:
		if belongs_to == Data.PROJECTILE_BELONGS.PLAYER:
			for i in area_2d.get_overlapping_bodies():
				if i is Player:
					queue_free()
					return
		
		speed.y = move_toward(speed.y, 0, 12.5 * delta)
	
	speed.x = move_toward(speed.x, -500 * dir, 10 * delta)


func explode():
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()

func expand_vision(_scale: Vector2) -> void:
	await ready
	if vision: vision.scale = _scale

func make_trail() -> void:
	var trail := sprite_node.duplicate() as Sprite2D
	(func() -> void:
		add_sibling(trail)
		get_parent().move_child(trail, get_index() - 1)
		trail.modulate.a = 0.75
		trail.global_transform = sprite_node.global_transform
	).call_deferred()
	
	var tw := trail.create_tween()
	tw.tween_property(trail, ^"modulate:a", 0.0, 0.5)
	tw.finished.connect(trail.queue_free)


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 96):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 200
	ScoreText.new(str(200), self)
	queue_free()
