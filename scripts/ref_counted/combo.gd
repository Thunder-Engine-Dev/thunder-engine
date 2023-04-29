class_name Combo
extends RefCounted

const LIFE_UP_SOUND: AudioStream = preload("res://engine/objects/players/prefabs/sounds/1up.wav")
const DEFAULT_COMBO_ARRAY: Array[int] = [100, 200, 500, 1000, 2000, 5000]
const STOMP_COMBO_ARRAY: Array[int] = [100, 200, 400, 500, 800, 1000, 2000, 5000, 8000]

var _on: Node2D
var _combo: int:
	get = get_combo
var _bonus_combo: int
var _reset_combo: bool

var _bonuses: Array[int]


func _init(on: Node2D, bonus_combo_times: int = 7, reset: bool = true, combo_array: Array[int] = DEFAULT_COMBO_ARRAY) -> void:
	_on = on
	_bonus_combo = bonus_combo_times
	_reset_combo = reset
	_bonuses = combo_array


func combo() -> void:
	var __combo: int = _combo if _combo < _bonuses.size() - 1 else _bonuses.size() - 1
	
	_combo += 1
	
	if _combo < _bonus_combo:
		ScoreText.new(str(_bonuses[__combo]), _on)
		Data.add_score(_bonuses[__combo])
	else:
		ScoreTextLife.new("%sUP" % 1, _on)
		Data.add_lives(1)
		Audio.play_sound(LIFE_UP_SOUND, _on, false)
		
		if _reset_combo:
			reset_combo()
		elif _combo > _bonus_combo:
			_combo = _bonus_combo


func reset_combo() -> void:
	_combo = 0


func get_combo() -> int:
	return _combo
