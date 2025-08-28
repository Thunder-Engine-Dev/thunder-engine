extends Label

@onready var template := "%.2f\n%.2f\n%d"

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
	text = template % [pl.speed.x, pl.speed.y, Thunder.autosplitter.il_frame]
	
