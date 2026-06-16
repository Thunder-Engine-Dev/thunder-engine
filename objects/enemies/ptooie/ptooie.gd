extends GeneralMovementBody2D

#var moving_back: bool

@onready var spikeball: GravityBody2D = $Spikeball
#@onready var timer: Timer = $Timer # Timer

func _ready() -> void:
	super()
	spikeball.going_up.connect(func():
		sprite_node.play(&"close")
	)
	spikeball.going_down.connect(func():
		sprite_node.play(&"open")
	)
	spikeball.got_killed.connect(func():
		speed.x *= 2
	, CONNECT_ONE_SHOT)


#func _on_timer_timeout() -> void:
	#if randi_range(0, 4) == 1:
	#	turn_x()
	#	
	#	await get_tree().create_timer(0.8, false, false).timeout
	#	turn_x()
	#	await get_tree().create_timer(0.8, false, false).timeout
	#	timer.start()
	#else:
	#timer.start()
