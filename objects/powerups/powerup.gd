extends GravityBody2D
class_name Powerup

@export_group("PowerupSettings")
@export var slide: bool = true
@export var set_player_state: PlayerStateData
@export var force_powerup_state: bool = false
@export var appear_distance: float = 32
@export var appear_speed: float = 0.5
@export var score: int = 1000


@export_group("SFX")
@export_subgroup("Sounds")
@export var appearing_sound: AudioStream = preload("res://engine/objects/bumping_blocks/_sounds/appear.wav")
@export var pickup_powerup_sound: AudioStream = preload("res://engine/objects/mario/sounds/powerup.wav")
@export var pickup_neutral_sound: AudioStream = preload("res://engine/objects/mario/sounds/powerup.wav")
@export_subgroup("Sound Settings")
@export var sound_pitch: float = 1.0

@onready var body: Area2D = $Body


func _from_bumping_block() -> void:
	Audio.play_sound(appearing_sound, self)

func _physics_process(delta: float) -> void:
	if !appear_distance:
		motion_process(Thunder.get_delta(delta), slide)
		z_index = 0
	else:
		appear_process(Thunder.get_delta(delta))
		z_index = -99
	
	if body.overlaps_body(Thunder._current_player):
		collect()


func appear_process(delta: float) -> void:
	appear_distance = max(appear_distance - appear_speed * delta, 0)
	position -= Vector2(0, appear_speed).rotated(global_rotation) * delta


func collect() -> void:
	_change_state_logic(force_powerup_state)
	
	if score > 0:
		ScoreText.new(str(score), self)
		Data.values.score += score
	
	queue_free()

func _change_state_logic(force_powerup: bool) -> void:
	if force_powerup:
		if set_player_state.state_name != Thunder._current_player_state.state_name:
			Thunder._current_player.powerup(set_player_state)
			Audio.play_sound(pickup_powerup_sound, self, true, {pitch = sound_pitch})
		else:
			Audio.play_sound(pickup_neutral_sound, self, true, {pitch = sound_pitch})
		return
	
	if (
		set_player_state.player_power > Thunder._current_player_state.player_power || (
			set_player_state.state_name != Thunder._current_player_state.state_name && 
			set_player_state.player_power == Thunder._current_player_state.player_power
		)
	):
		if Thunder._current_player_state.player_power < set_player_state.player_power - 1:
			Thunder._current_player.powerup(set_player_state.powerdown_state)
		else:
			Thunder._current_player.powerup(set_player_state)
		Audio.play_sound(pickup_powerup_sound, self, true, {pitch = sound_pitch})
	else:
		Audio.play_sound(pickup_neutral_sound, self, true, {pitch = sound_pitch})
