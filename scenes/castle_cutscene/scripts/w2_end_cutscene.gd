extends Node

const CASTLE_BRICK = preload("res://engine/scenes/castle_cutscene/objects/castle_brick.tscn")
const CASTLE_SMOKE = preload("res://engine/scenes/castle_cutscene/objects/castle_smoke.tscn")

const JUMP = preload("res://engine/objects/players/prefabs/sounds/jump.wav")
const BREAK = preload("res://engine/objects/bumping_blocks/_sounds/break.wav")

@onready var player: Player = Thunder._current_player
@onready var castle = $"../Castle"

@onready var castle_not_broken = $"../Castle/CastleNotBroken"
@onready var castle_slightly_broken = $"../Castle/CastleSlightlyBroken"
@onready var castle_full_broken = $"../Castle/CastleFullBroken"
@onready var castle_full_broken_deluxe = $"../Castle/CastleFullBrokenDeluxe"

@onready var castle_end_marker = $"../CastleEndMarker"
@onready var castle_pos: float = castle.position.x
@onready var marker_2d = $"../Castle/Marker2D"


var _player_speed: float = 0.0
var _moving: bool = false
var _running: bool = false
var _finished: float = 0.0

var _jump_num = 0
var _fin = false

func _ready() -> void:
	await get_parent().ready
	player = Thunder._current_player
	player.completed = true
	await get_tree().create_timer(1.5, false).timeout
	var tw = create_tween()
	tw.tween_property(player, "modulate:a", 1.0, 1.0)
	await get_tree().create_timer(1.5, false).timeout
	_moving = true


func _physics_process(delta: float) -> void:
	if _moving:
		if player.global_position.y > marker_2d.global_position.y && player.speed.y > 0:
			player.jump(-700)
			if _jump_num == 0:
				player.gravity_scale = 0.45
			else:
				player.gravity_scale = 0.6 + min(float(_jump_num) / 5.0, 2.8)
			
			var _sfx = CharacterManager.get_sound_replace(JUMP, JUMP, "jump", true)
			Audio.play_sound(_sfx, player, false)
			if _jump_num != 0:
				Audio.play_sound(BREAK, player, false)
				Thunder._current_camera.shock(0.1, Vector2(2, 2))
				for i in range(4):
					_brick_particles()
				castle.global_position.y += 5 + randi_range(0, 5)
				
				if _jump_num > 0:
					castle_not_broken.visible = false
					castle_slightly_broken.visible = true
				
				if _jump_num > 8:
					castle_slightly_broken.visible = false
					castle_full_broken.visible = true
				
				if _jump_num > 16:
					castle_full_broken.visible = false
					castle_full_broken_deluxe.visible = true
				
			_jump_num += 1
	
	if marker_2d.global_position.y >= 400 && !_fin:
		_fin = true
		run_while(_smoke_particles, 0.02)
		_running = true
	
	if _running && player.global_position.y >= 390:
		player.speed.x = _player_speed
		_player_speed = move_toward(_player_speed, 325, delta * 250)
		_finished += delta
	
		if player.is_on_wall():
			player.left_right = 1

	if _finished > 2.0 && _finished < 999:
		_finished = 1000
		Scenes.current_scene.end()


func run_while(callable: Callable, repeat_delay: float) -> void:
	callable.call()
	await get_tree().create_timer(repeat_delay, false, false, true).timeout
	run_while(callable, repeat_delay)


func _brick_particles() -> void:
	var brick = CASTLE_BRICK.instantiate()
	brick.position = marker_2d.global_position
	brick.reset_physics_interpolation()
	brick.speed = Vector2(randf_range(-6.0, 6.0), randi_range(-11, -6))
	Scenes.current_scene.add_child(brick)


func _smoke_particles() -> void:
	var smoke = CASTLE_SMOKE.instantiate()
	smoke.position = castle_end_marker.position + Vector2(randi_range(-157, 157), 16)
	smoke.reset_physics_interpolation()
	smoke.y_modifier = randi_range(-10, 10)
	smoke.rotation_speed = randi_range(-90, 90)
	Scenes.current_scene.add_child(smoke)
