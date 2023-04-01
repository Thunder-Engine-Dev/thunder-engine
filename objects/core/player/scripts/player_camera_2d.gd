extends Camera2D
class_name PlayerCamera2D


func _ready():
	make_current()
	teleport()

func _process(_delta): teleport()
func _physics_process(_delta): teleport()

func teleport() -> void:
	if !Thunder._current_player: return
	global_position = Vector2i(Thunder._current_player.global_position)
	Thunder.view.cam_border()
