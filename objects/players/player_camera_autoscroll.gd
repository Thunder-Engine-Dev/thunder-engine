extends PathFollow2D

@export var speed: float = 50
@export var tank_autoscroll: bool = false
@export var stop_on_death: bool = false
@export var stop_speed: float = 4

var _stopped: bool

@onready var player = Thunder._current_player

signal scroll_stopped

func _physics_process(delta: float) -> void:
	var prev_pos = global_position + Vector2.ZERO
	progress += speed * delta
	var next_pos = global_position + Vector2.ZERO
	var delta_pos = next_pos - prev_pos
	
	if tank_autoscroll && is_instance_valid(player) && !player.is_on_floor():
		player.global_position += delta_pos
	
	if stop_on_death && !is_instance_valid(player):
		speed = lerpf(speed, 0, stop_speed * delta)
	
	if progress_ratio == 1.0 && !_stopped:
		_stopped = true
		scroll_stopped.emit()


func set_speed(new_speed: float) -> void:
	speed = new_speed
