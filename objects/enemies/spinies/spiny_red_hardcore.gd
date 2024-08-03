extends GeneralMovementBody2D

@export var free_offscreen: bool = false

@onready var vision: VisibleOnScreenEnabler2D = $Vision

func _ready():
	super()
	if free_offscreen:
		vision.screen_exited.connect(queue_free)
