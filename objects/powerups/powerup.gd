extends GravityBody2D
class_name Powerup

const DEFAULT_APPEARING_SOUND = preload("res://engine/objects/bumping_blocks/_sounds/appear.wav")
const DEFAULT_POWERUP_SOUND = preload("res://engine/objects/players/prefabs/sounds/powerup.wav")
const DEFAULT_NEUTRAL_SOUND = preload("res://engine/objects/players/prefabs/sounds/powerup.wav")

signal collected
signal collected_changed_suit

@export_group("Powerup Settings")
@export var slide: bool = true
@export var to_suit: String = "super"
@export var force_powerup_state: bool = false
@export var appear_distance: float = 32
@export var appear_speed: float = 0.5
@export var appear_visible: float = 27
@export var appear_collectable: float = 20
@export var score: int = 1000


@export_group("Supply Behavior")
@export var supply_behavior: bool = false
@export var supply_modify_lives: int = 0


@export_group("SFX")
@export_subgroup("Sounds")
@export var appearing_sound: AudioStream = DEFAULT_APPEARING_SOUND
@export var pickup_powerup_sound: AudioStream = DEFAULT_POWERUP_SOUND
@export var pickup_neutral_sound: AudioStream = DEFAULT_NEUTRAL_SOUND
@export_subgroup("Sound Settings")
@export var sound_pitch: float = 1.0

@onready var body: Area2D = $Body

var one_overlap: bool = false
var can_collect: bool = true

func _ready() -> void:
	super()
	if appear_distance && !supply_behavior:
		appear_process(0)

func _from_bumping_block() -> void:
	var sfx = CharacterManager.get_sound_replace(appearing_sound, DEFAULT_APPEARING_SOUND, "block_appear", false)
	Audio.play_sound(sfx, self)

func _physics_process(delta: float) -> void:
	if !supply_behavior:
		if !appear_distance:
			motion_process(delta, slide)
			modulate.a = 1
			can_collect = true
		else:
			appear_process(Thunder.get_delta(delta))

	var player: Player = Thunder._current_player
	if !player: return
	var overlaps: bool = body.overlaps_body(player)
	if supply_behavior && SettingsManager.get_tweak(&"revamp_item_shop", false):
		if overlaps && Input.is_action_just_pressed(&"m_up"):
			collect()
		return
	
	if !can_collect:
		return
	if overlaps && !one_overlap:
		collect()
	if !overlaps && one_overlap:
		one_overlap = false


func appear_process(delta: float) -> void:
	if delta:
		appear_distance = max(appear_distance - appear_speed * delta, 0)
	can_collect = appear_distance <= appear_collectable
	modulate.a = 0.01 if (appear_distance > appear_visible) else 1.0
	if delta:
		position -= Vector2(0, appear_speed).rotated(global_rotation) * delta


func collect() -> void:
	_change_state_logic(force_powerup_state)

	if supply_behavior:
		Data.values.lives = ProjectSettings.get("application/thunder_settings/player/default_lives") + supply_modify_lives
		one_overlap = true
		return

	if score > 0:
		ScoreText.new(str(score), self)
		Data.add_score(score)

	queue_free()


func _change_state_logic(force_powerup: bool) -> void:
	var player: Player = Thunder._current_player
	var to: PlayerSuit = CharacterManager.get_suit(to_suit)
	if !to: return
	
	var powerup_sfx: AudioStream
	var neutral_sfx := CharacterManager.get_sound_replace(pickup_neutral_sound, DEFAULT_NEUTRAL_SOUND, "powerup_no_transform", true)
	
	if force_powerup:
		if to.name != Thunder._current_player_state.name:
			player.change_suit(to)
			powerup_sfx = CharacterManager.get_sound_replace(pickup_powerup_sound, pickup_powerup_sound, "powerup", true)
			Audio.play_sound(powerup_sfx, self, false, {pitch = sound_pitch, ignore_pause = true})
			collected_changed_suit.emit()
		elif !supply_behavior:
			Audio.play_sound(neutral_sfx, self, false, {pitch = sound_pitch})
		collected.emit()
		return

	if (
		to.type > Thunder._current_player_state.type || (
			to.name != Thunder._current_player_state.name &&
			to.type == Thunder._current_player_state.type
		)
	):
		if Thunder._current_player_state.type < to.type - 1:
			player.change_suit(to.gets_hurt_to)
		else:
			player.change_suit(to)
		powerup_sfx = CharacterManager.get_sound_replace(pickup_powerup_sound, pickup_powerup_sound, "powerup", true)
		Audio.play_sound(powerup_sfx, self, false, {pitch = sound_pitch, ignore_pause = true})
		collected_changed_suit.emit()
	else:
		Audio.play_sound(neutral_sfx, self, false, {pitch = sound_pitch})
	collected.emit()
