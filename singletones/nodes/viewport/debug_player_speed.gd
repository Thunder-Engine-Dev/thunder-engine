extends Label

@onready var template := "%.2f\n%.2f\n%d\n%.2f\n%.2f\n%.2f\n%.2f\n%.1f"

func _ready() -> void:
	hide()
	if !OS.get_cmdline_user_args().has("--speedrun-stats"):
		queue_free()
		return
	show()

func _physics_process(delta: float) -> void:
	var pl := Thunder._current_player
	if !pl:
		text = "--"
		return
	var real_vel = pl.get_real_velocity()
	text = template % [
		pl.speed.x, pl.speed.y, Thunder.autosplitter.il_frame,
		real_vel.x, real_vel.y,
		pl.global_position.x, pl.global_position.y,
		pl.get("ghost_speed_y")
	]
	
