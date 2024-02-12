extends Sprite2D

var speed: float
@onready var bounce_marker: Marker2D = $BounceMarker
@onready var marker_pos: Vector2 = bounce_marker.global_position

@onready var map = Scenes.current_scene


func _ready() -> void:
	if map is Map2D:
		map.player_entered_level.connect(
			func():
				var tw: Tween = create_tween().set_trans(Tween.TRANS_SINE)
				tw.tween_property(self, ^"modulate:a", 0, 1.5)
		)


func _physics_process(delta: float) -> void:
	delta = Thunder.get_delta(delta)
	position.y += speed * delta
	speed += 0.4 * delta
	
	if global_position.y >= marker_pos.y - texture.get_height() / 2.0 && speed > 0:
		#position.y -= speed * delta
		speed *= -1
		if speed < -3:
			speed /= 2
			speed -= 1
