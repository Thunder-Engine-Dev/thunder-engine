extends AnimatableBody2D

@onready var springboard: CharacterBody2D = $"../.."

func _player_landed(player) -> void:
	springboard.trigger(player)
