extends AnimationPlayer

@onready var _timer_rand: Timer = $TimerRand


func _ready() -> void:
	_timer_rand.timeout.connect(func():
		play(&"swinging")
		
		await animation_finished
		
		play(&"RESET")
		_rand_timer()
	)


func _rand_timer() -> void:
	_timer_rand.start(randf_range(2, 4))
