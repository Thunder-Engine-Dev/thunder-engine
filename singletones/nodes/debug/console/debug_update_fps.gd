extends Label

@onready
var timer: Timer = Timer.new()

func _ready() -> void:
	add_child(timer)
	timer.wait_time = 0.5
	timer.timeout.connect(update_fps)
	timer.start()

func update_fps() -> void:
	text = "%d FPS" % int(Engine.get_frames_per_second())
