extends Camera2D
class_name PlayerCamera2D

@onready var par: Node2D = get_parent()


func _ready():
	Thunder._current_camera = self
	make_current()
	teleport()


func _physics_process(_delta):
	teleport()


func teleport() -> void:
	var player: Player = Thunder._current_player
	if !par is PathFollow2D && player:
		global_position = Vector2i(Thunder._current_player.global_position)
	Thunder.view.cam_border()
	
	if par is PathFollow2D:
		if !player: return
		while !Thunder.view.screen_left(player.global_position, -16):
			player.global_position += Vector2.RIGHT.rotated(global_rotation)
			player.vel_set_x(0)
		while !Thunder.view.screen_right(player.global_position, -16):
			player.global_position += Vector2.LEFT.rotated(global_rotation)
			player.vel_set_x(0)


func shock(duration: float, amplitude: Vector2, interval: float = 0.01) -> void:
	var ofs: Vector2 = offset
	var tw: Tween = create_tween().set_loops(ceili(duration / interval)).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_callback(
		func() -> void:
			offset = Vector2(
				randf_range(-amplitude.x, amplitude.x),
				randf_range(-amplitude.y, amplitude.y)
			)
	).set_delay(interval)
	tw.finished.connect(
		func() -> void:
			offset = ofs
	)
