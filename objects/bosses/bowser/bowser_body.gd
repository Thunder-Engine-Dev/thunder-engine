extends Area2D

@onready var bowser: CharacterBody2D = $".."

var _is_dead: bool
func got_in_lava() -> void:
	if !bowser.instakill_from_lava: return
	if _is_dead: return
	bowser.die.call_deferred(false)
	_is_dead = true
