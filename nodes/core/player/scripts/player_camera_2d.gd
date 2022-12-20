extends Camera2D
class_name PlayerCamera2D


func _ready() -> void:
	teleport()

func _process(_delta: float) -> void:
	teleport()

func teleport() -> void:
	if !Thunder._current_player: return
	
	global_position = Thunder._current_player.sprites.global_position
