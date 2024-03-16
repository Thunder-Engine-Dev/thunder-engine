extends StaticBody2D

@onready var p_switch: CharacterBody2D = $".."

func _player_landed(pl: Player) -> void:
	p_switch._on_activation(pl)
	
