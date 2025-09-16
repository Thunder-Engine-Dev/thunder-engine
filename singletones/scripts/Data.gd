extends Node

## Singleton that stores general data in the game

## Defines enemies' type of receiving attack
const ATTACKERS: Dictionary = {
	head = &"head",
	starman = &"starman",
	shell = &"shell",
	fireball = &"fireball",
	beetroot = &"beetroot",
	iceball = &"iceball",
	iceblock = &"iceblock",
	hammer = &"hammer",
	boomerang = &"boomerang",
	lava = &"lava",
}

var LIFE_SOUND = preload("res://engine/objects/players/prefabs/sounds/1up.wav")

## Defines player's basic power-up status
enum PLAYER_POWER {
	SMALL, ## Self-explanable, e.g. small Mario
	SUPER, ## e.g. big Mario
	FULL   ## e.g. fire Mario
}

## Defines which type a projectile belongs.[br]
## Projectiles can be items thrown, or items with damage
enum PROJECTILE_BELONGS {
	PLAYER, ## Player thrown and attacks enemies
	ENEMY ## Enemy thrown and attacks players
}

## Defines basic information of a player
var values: Dictionary = {
	lives = -1,
	score = 0,
	prev_score = 0,
	coins = 0,
	time = -1,
	checkpoint = -1,
	checked_cps = [],
	onetime_blocks = true,
	stopwatch = 0.0,
}

## Internal values that require preservation between scenes, but don't have to be saved.
## If inside "custom_saved_values", then they are saved in the suspended profile.
var technical_values: Dictionary = {
	impulse_progress_continue = false,
	remaining_continues = ProjectSettings.get_setting(
		"application/thunder_settings/player/gameover_continues", -1
	),
	custom_saved_values = {}
}

@warning_ignore("unused_private_class_variable")
@onready var _default_values: Dictionary = values.duplicate(true)

signal coin_added
signal coin_added_arg(amount: int)
signal score_added
signal score_added_arg(amount: int)
signal life_added
signal life_added_arg(amount: int)
signal checkpoint_set
signal checkpoint_set_arg(to_id: int)
signal stopwatch_activated
signal stopwatch_cancelled
signal values_reset


func add_coin(amount: int = 1) -> void:
	coin_added.emit()
	values.coins += 1
	if values.coins > 99:
		values.coins = 0
		Thunder.add_lives(1)
		var _sfx = CharacterManager.get_sound_replace(LIFE_SOUND, LIFE_SOUND, "1up", false)
		Audio.play_1d_sound(_sfx, false)
		if is_instance_valid(Thunder._current_hud):
			Thunder._current_hud.pulse_label(Thunder._current_hud.coins)
	coin_added_arg.emit(amount)


func add_score(amount: int) -> void:
	score_added.emit()
	values.score += amount
	score_added_arg.emit(amount)
	#if SettingsManager.get_tweak("life_every_2_mil_score", false):
		#var two_mil: int = floor(values.score / 1_000_000)
		#if two_mil > values.prev_score:
			#values.prev_score = two_mil
#
			#await get_tree().create_timer(0.3, false).timeout
			#Thunder.add_lives(1)
			#Audio.play_1d_sound(preload("res://engine/objects/players/prefabs/sounds/1up.wav"), false)
#
			#if is_instance_valid(Thunder._current_hud):
				#Thunder._current_hud.pulse_label(Thunder._current_hud.mario_score)


func add_lives(amount: int = 1) -> void:
	life_added.emit()
	values.lives += amount
	life_added_arg.emit(amount)


func reset_all_values() -> void:
	values_reset.emit()
	Thunder._current_player_state = null
	Thunder._current_player_state_path = ""
	values = _default_values.duplicate(true)
