extends GeneralMovementBody2D

@onready var spikeball: GravityBody2D = $Spikeball

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
