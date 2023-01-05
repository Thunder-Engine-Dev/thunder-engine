extends Camera2D
class_name PlayerCamera2D


func _ready(): teleport()
func _process(_delta): teleport()
func _physics_process(_delta): teleport()

func teleport() -> void:
	if !Thunder._current_player: return
	global_position = Thunder._current_player.global_position
