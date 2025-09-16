extends Node

const CASTLE_SMOKE = preload("res://engine/scenes/castle_cutscene/objects/castle_smoke_w6.tscn")
const BE_HAPPY = preload("res://engine/objects/bosses/bowser/sounds/bowser_died.wav")
const PIPEC = preload("res://engine/objects/players/prefabs/sounds/pipe_cutscene.wav")
const CASTLE_PIPE_SUCK = preload("res://engine/scenes/castle_cutscene/sounds/castle_pipe_suck.wav")

@onready var player: Player = Thunder._current_player
@onready var castle = $"../Castle"
@onready var castle_end_marker = $"../CastleEndMarker"
@onready var castle_pos: Vector2 = castle.position

var _player_speed: float = 0.0
var _moving: bool = false
var _destroying: bool = false
var _finished: float = 0.0

func _ready() -> void:
	await get_parent().ready
	player = Thunder._current_player
	player.completed = true
	
	await get_tree().create_timer(0.5, false).timeout
	var tw = create_tween()
	tw.tween_property(player, "modulate:a", 1.0, 1.0)
	
	await get_tree().create_timer(0.5, false).timeout
	_moving = true
	await get_tree().create_timer(2.5, false).timeout
	
	Audio.play_1d_sound(CASTLE_PIPE_SUCK)
	run_while(_smoke_particles, 0.1)
	var amplitude = Vector2(3, 3)
	tw = create_tween().set_loops()
	tw.tween_callback(
		func() -> void:
			castle.offset = Vector2(
				randf_range(-amplitude.x, amplitude.x),
				randf_range(-amplitude.y, amplitude.y)
			)
	).set_delay(0.01)
	
	await get_tree().create_timer(3, false, false, true).timeout
	Audio.play_1d_sound(CASTLE_PIPE_SUCK)
	#var _sfx = CharacterManager.get_sound_replace(BE_HAPPY, BE_HAPPY, "bowser_be_happy", false)
	Audio.play_1d_sound(BE_HAPPY)
	tw.stop()
	castle.offset = Vector2.ZERO
	tw = create_tween().set_trans(Tween.TRANS_SPRING)
	tw.tween_property(castle, "scale:x", 0.18, 0.8).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(2, false).timeout
	
	var _sfx = CharacterManager.get_sound_replace(PIPEC, PIPEC, "pipe_cutscene", false)
	Audio.play_1d_sound(_sfx)
	tw = create_tween()
	tw.tween_property(castle, "position:y", 608.0, 2.5)


func _physics_process(delta: float) -> void:
	if _moving:
		player.speed.x = _player_speed
		_player_speed = move_toward(_player_speed, 300, delta * 250)
	
		if player.is_on_wall():
			player.left_right = 1
	
	if _destroying:
		castle.position.y += delta * 50
	if castle.position.y > castle_end_marker.position.y:
		_finished += delta
	if _finished > 2.0 && _finished < 999:
		_finished = 1000
		Scenes.current_scene.end()


func run_while(callable: Callable, repeat_delay: float) -> void:
	if _finished: return
	callable.call()
	await get_tree().create_timer(repeat_delay, false, false, true).timeout
	run_while(callable, repeat_delay)


func _smoke_particles() -> void:
	var smoke = CASTLE_SMOKE.instantiate()
	Scenes.current_scene.add_child(smoke)
