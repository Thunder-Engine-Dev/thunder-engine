extends Node2D

@export_category("Lakitu")
@export var movement_area: Rect2
@export var draw_area_rect: bool
@export var respawn_delay: float = 6
@export_group("Physics")
@export var hovering_margin: float = 50
@export var hovering_range: float = 100
@export var chasing_speed: float = 450
@export var hovering_speed: float = 100
@export_enum("Left:-1", "Right:1") var leaving_direction: int = -1
@export_group("Attack")
@export var pitched: InstanceNode2D
@export var pitching_interval_min: float = 4
@export var pitching_interval_max: float = 5
@export var sounds: Array[AudioStream] = [
	preload("res://engine/objects/enemies/lakitus/sounds/lakitu_mek.ogg"),
	preload("res://engine/objects/enemies/lakitus/sounds/lakitu_myu.ogg"),
	preload("res://engine/objects/enemies/lakitus/sounds/lakitu_rek.ogg")
]

var speed: float

var _movement: bool:
	set(to):
		if _movement == to:
			return
		_movement = to
		if _movement && timer_pitching.is_stopped():
			timer_pitching.start()
		elif !timer_pitching.is_stopped():
			timer_pitching.stop()

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var timer_pitching: Timer = $Pitching
@onready var visible_on_screen_enabler_2d: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D


func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	if !player:
		_movement = false
		visible_on_screen_enabler_2d.process_mode = Node.PROCESS_MODE_INHERIT
	elif movement_area && !movement_area.has_point(player.global_position):
		_movement = false
		visible_on_screen_enabler_2d.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		_movement = true
		visible_on_screen_enabler_2d.process_mode = Node.PROCESS_MODE_DISABLED
	
	if _movement:
		_movement_process(delta, player)
	else:
		_leaving_process(delta)
	
	global_position += Vector2.RIGHT.rotated(global_rotation) * speed * delta


func _movement_process(delta: float, player: Player) -> void:
	if !player:
		return
	
	var trans: Transform2D = global_transform.affine_inverse()
	var pposx: float = trans.basis_xform(player.global_position).x
	var posx: float = trans.basis_xform(global_position).x
	var dir: int = sign(pposx - posx)
	
	if posx > pposx + hovering_margin || posx < pposx - hovering_margin:
		speed = move_toward(speed, chasing_speed * dir, 5)
	elif posx < pposx + hovering_range && posx > pposx - hovering_range && ((speed < -100 && player.direction > 0) || (speed > 100 && player.direction < 0)):
		speed = move_toward(speed, hovering_speed * player.direction, 10)
	
	timer_pitching.paused = !Thunder.view.is_getting_closer(self, -32)


func _leaving_process(delta: float) -> void:
	if !Thunder.view.is_getting_closer(self, leaving_direction * 128):
		speed = move_toward(speed, 100 * leaving_direction, 50)
	else:
		speed = 0


func _pitch() -> void:
	if pitched:
		NodeCreator.prepare_ins_2d(pitched, self).create_2d().execute_instance_script()
	Audio.play_sound(sounds.pick_random(), self)


func _on_animation_timeout() -> void:
	var animation: int = randi_range(0,4)
	if sprite.animation != &"pitch":
		match animation:
			1:
				sprite.play(&"blink1")
			2:
				sprite.play(&"blink2")


func _on_animation_finished() -> void:
	if sprite.animation in [&"blink1", &"blink2"]:
		sprite.play(&"default")


func _on_pitching() -> void:
	sprite.play(&"pitch")
	await sprite.animation_finished
	if sprite.animation == &"pitch":
		await get_tree().create_timer(0.4, false).timeout
		sprite.play_backwards(&"pitch")
		await sprite.animation_finished
		sprite.play(&"default")
		_pitch()
		timer_pitching.start(randf_range(pitching_interval_min, pitching_interval_max))
