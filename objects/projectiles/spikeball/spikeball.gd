extends Projectile

var _trail_position: Vector2
var _trail_end_position: Vector2
var _trail_frame: int = -1
var _trail_settings := Effect.TrailSettings.new()

func _ready() -> void:
	super()
	if speed.x < 0 && sprite_node:
		sprite_node.rotation_speed = -sprite_node.rotation_speed


func _physics_process(delta: float) -> void:
	if is_instance_valid(sprite_node):
		_trail_position = sprite_node.global_position
		_trail_frame = Engine.get_physics_frames()
	super(delta)
	if is_instance_valid(sprite_node):
		_trail_end_position = sprite_node.global_position


func _on_trail() -> void:
	if !sprite_node:
		return
	var previous_position: Vector2 = sprite_node.global_position
	if _trail_frame == Engine.get_physics_frames() && previous_position.is_equal_approx(_trail_end_position):
		previous_position = _trail_position
	_trail_settings.z_index = z_index
	var trail := Effect.emit_trail(sprite_node, previous_position, _trail_settings)
	trail.rotation = sprite_node.rotation
	Thunder.reorder_on_top_of(trail, self)


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 2048):
			queue_free()
		return
	Data.add_score(200)
	ScoreText.new(str(200), self)
	queue_free()
