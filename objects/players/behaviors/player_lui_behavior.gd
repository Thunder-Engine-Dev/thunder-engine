extends ByNodeScript

var player: Player

var trail_timer: float
var _trail_position: Vector2
var _trail_end_position: Vector2
var _trail_frame: int = -1
var _trail_settings := Effect.TrailSettings.new()


func _ready() -> void:
	player = node as Player
	_trail_settings.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player.before_motion.connect(_capture_trail_position)
	player.after_motion.connect(_capture_trail_end)


func _capture_trail_position(_delta: float) -> void:
	_trail_position = player.sprite.global_position
	_trail_frame = Engine.get_physics_frames()


func _capture_trail_end(_delta: float) -> void:
	_trail_end_position = player.sprite.global_position


func _physics_process(delta: float) -> void:
	if player.get_tree().paused: return
	# Trail effect
	if trail_timer > 0.0: trail_timer -= 1 * Thunder.get_delta(delta)
	if !player.is_on_floor() && trail_timer <= 0.0:
		trail_timer = 1.5
		var previous_position: Vector2 = player.sprite.global_position
		if _trail_frame == Engine.get_physics_frames() && previous_position.is_equal_approx(_trail_end_position):
			previous_position = _trail_position
		_trail_settings.z_index = player.sprite_container.z_index + 1
		Effect.emit_trail(player.sprite, previous_position, _trail_settings)
