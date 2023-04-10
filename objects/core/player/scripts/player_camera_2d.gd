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


func shock(duration: float, amplitude: Vector2, interval: float = 0.01) -> void:
	var ofs: Vector2 = offset
	var tw: Tween = create_tween().set_loops(ceili(duration / interval)).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_callback(
		func() -> void:
			offset = Vector2(randf_range(-amplitude.x, amplitude.x), randf_range(-amplitude.y, amplitude.y))
	).set_delay(interval)
	tw.finished.connect(
		func() -> void:
			offset = ofs
	)
