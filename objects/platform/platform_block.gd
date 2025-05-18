extends StaticBody2D

@export var includes_path_follow: bool = true
@export var correction_on_player_falling: bool = true

@onready var _path_follow = $".."
@onready var init_collision_margin = get_shape_owner_one_way_collision_margin(0)

func _ready() -> void:
	#physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF
	if !is_shape_owner_one_way_collision_enabled(0):
		correction_on_player_falling = false


# Forward the method call to the main platform script.
func _player_landed(player: Player) -> void:
	if !includes_path_follow: return
	if _path_follow.has_method(&"_player_landed"):
		_path_follow._player_landed(player)


var _is_player_falling: bool
func _draw() -> void:
	if !Console.cv.platform_collision_shown: return
	
	var _the_rect: Rect2 = shape_owner_get_shape(0, 0).get_rect()
	if !_is_player_falling:
		_the_rect.size.y = init_collision_margin
	draw_rect(_the_rect, Color(Color.ORANGE, 0.6), true)

func _physics_process(_delta: float) -> void:
	if includes_path_follow:
		global_position = _path_follow.global_position
	
	if correction_on_player_falling:
		var player = Thunder._current_player
		if player:
			_is_player_falling = player.speed.y >= -5
			if _is_player_falling:
				shape_owner_set_one_way_collision_margin(0, shape_owner_get_shape(0, 0).get_rect().size.y)
			else:
				shape_owner_set_one_way_collision_margin(0, init_collision_margin)
			if Console.cv.platform_collision_shown:
				queue_redraw()
	
	if !includes_path_follow: return
	
	if "warp_objects_on_end" in _path_follow && !_path_follow.warp_objects_on_end:
		var _edge = _path_follow.warping_edge_ignore_px
		if _path_follow.max_progress < _edge:
			return
		if _path_follow.progress < _edge || _path_follow.progress + _edge > _path_follow.max_progress:
			reset_physics_interpolation()
