extends Camera2D
class_name PlayerCamera2D


func _ready():
	Thunder._current_camera = self
	make_current()
	teleport()

func _physics_process(_delta): teleport()

func teleport() -> void:
	if !Thunder._current_player: return
	elif Thunder._current_player.states.current_state == "dead": return
	global_position = Vector2i(Thunder._current_player.global_position)
	Thunder.view.cam_border()
