extends "res://engine/objects/effects/trail/trail.gd"
## Trail that shrinks to nothing while it lives, around the origin of its image
## (the middle of it when the source sprite is centered).
## [member shrink_strength] is the share of the starting scale lost per 50 FPS frame,
## so 0.1 empties the trail in 10 frames. Combine with [member fade_out_strength] to fade as well.

@export var shrink_strength: float = 0.05

var _start_scale: Vector2
var _shrink_progress: float
var _started: bool


func _physics_process(delta: float) -> void:
	# The scale is assigned after the node enters the tree, so it is read on the first tick.
	if !_started:
		_started = true
		_start_scale = scale
	_shrink_progress += shrink_strength * Thunder.get_delta(delta)
	if _shrink_progress >= 1.0:
		queue_free()
		return
	scale = _start_scale * (1.0 - _shrink_progress)
	super(delta)
