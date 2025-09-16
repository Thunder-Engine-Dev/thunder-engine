extends Area2D

const coin_effect: PackedScene = preload("res://engine/objects/effects/coin_effect/coin_effect.tscn")

const DEFAULT_SOUND = preload("res://engine/objects/items/coin/coin.wav")

@onready var enemy_attacked: Node = $Body/EnemyAttacked
@export var sound: AudioStream = DEFAULT_SOUND

func _ready() -> void:
	var _custom_sound = CharacterManager.get_sound_replace(enemy_attacked.killing_sound_succeeded, DEFAULT_SOUND, "coin", false)
	enemy_attacked.killing_sound_succeeded = _custom_sound


func _play_sound() -> void:
	var _custom_sound = CharacterManager.get_sound_replace(sound, DEFAULT_SOUND, "coin", false)
	Audio.play_sound(_custom_sound, self, false)


func _from_bumping_block() -> void:
	_play_sound()
	NodeCreator.prepare_2d(coin_effect, self).create_2d().bind_global_transform()
	Data.add_coin()
	queue_free()


func _physics_process(delta):
	if !Thunder._current_player: return
	if overlaps_body(Thunder._current_player):
		collect()


func collect() -> void:
	Data.add_coin()
	Data.add_score(100)
	
	if SettingsManager.get_quality() != SettingsManager.QUALITY.MIN:
		NodeCreator.prepare_2d(coin_effect, self).call_method( func(eff: Node2D) -> void:
			eff.explode()
		).create_2d().bind_global_transform()
	
	_play_sound()
	queue_free()
