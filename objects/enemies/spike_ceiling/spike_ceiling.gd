extends VBoxContainer

const FALL = preload("res://engine/objects/enemies/spike_ceiling/sfx/fall.wav")

@export var activated_area: Rect2
@export var draw_area_rect: bool
@export_group("Spike Ceiling Behaviour")
@export var activation_time: float = 4.0
@export var bottom_line_position: float = 408.0
@export var falling_speed: float = 1.0
@export var reabilitation_delay: float = 2.0
@export var reabilitation_speed: float = 100.0

var _state: int = 0
var _sine: float
var _falling_vel: float

@onready var init_pos: Vector2 = global_position
@onready var timer: Timer = $Activation
@onready var spike: TextureRect = $Spike
@onready var area: Area2D = $Spike/Area2D

func _ready() -> void:
	resized.connect(_set_scale)
	_set_scale()
	reset_physics_interpolation.call_deferred()


func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	if player && activated_area && activated_area.has_point(player.global_position):
		if timer.is_stopped():
			timer.start(activation_time)
	elif !timer.is_stopped():
		_sine = 0
		timer.stop()
	
	var pos_size: float = global_position.y + size.y
	if _state == 1 && !timer.is_stopped():
		_sine += 50 * delta
		global_position.y = init_pos.y + sin(_sine) * (_sine / 70.0)
	elif _state == 2:
		_falling_vel += falling_speed * 50 * delta
		global_position.y = move_toward(global_position.y, bottom_line_position - size.y, _falling_vel * 50 * delta)
		if pos_size == bottom_line_position:
			_state = 3
			_falling_vel = 0
			Thunder._current_camera.shock_smooth(10, 5)
			Audio.play_1d_sound(FALL)
			await get_tree().create_timer(2.0, false).timeout
			_state = 4
	elif _state == 4:
		global_position.y = move_toward(global_position.y, init_pos.y, reabilitation_speed * delta)
		if global_position.y == init_pos.y:
			timer.start(activation_time)
			_state = 0


func _on_activation_timeout() -> void:
	match _state:
		0:
			_sine = 0
		1:
			_sine = 0
			global_position.y = init_pos.y
		_:
			return
	_state += 1


func _set_scale() -> void:
	var _size := Vector2(get_rect().size.x, spike.get_rect().size.y - 6)
	area.scale = _size
	area.position = _size / 2
