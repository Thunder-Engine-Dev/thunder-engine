class_name Combo
extends RefCounted

var _on: Node2D
var _combo: int:
	get = get_combo
var _bonus_combo: int = 8
var _reset_combo: bool = true

var _bonuses: Array[int] = [100, 200, 500, 1000, 2000, 5000]


func _init(on: Node2D, bonus_combo_times: int = 8, reset: bool = false) -> void:
	_on = on
	_bonus_combo = bonus_combo_times
	_reset_combo = reset


func combo() -> void:
	var combo: int = _combo if _combo < _bonuses.size() - 1 else _bonuses.size() - 1
	
	_combo += 1
	
	if _combo < _bonus_combo:
		ScoreText.new(str(_bonuses[combo]), _on)
		Data.add_score(_bonuses[combo])
	else:
		ScoreTextLife.new("%sUP" % 1, _on)
		Data.add_lives(1)
		
		if _reset_combo:
			reset_combo()
		elif _combo > _bonus_combo:
			_combo = _bonus_combo


func reset_combo() -> void:
	_combo = 0


func get_combo() -> int:
	return _combo
