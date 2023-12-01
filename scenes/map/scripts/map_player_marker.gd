@tool
class_name MapPlayerMarker extends Area2D

@export
var level: StringName

@export
var marker: Texture2D

var angle: float

var shape: CollisionShape2D

func _ready() -> void:
	add_to_group("map_marker")
	
	if shape == null:
		var collision = RectangleShape2D.new()
		collision.size = Vector2(10, 10)
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = collision
		shape = collision_shape
		add_child(collision_shape)
	
	if !Engine.is_editor_hint():
		angle = rotation
		rotation = 0


func is_level() -> bool:
	return !level.is_empty()

func is_level_completed() -> bool:
	return false


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_char(ThemeDB.fallback_font,Vector2(-3,6),'>')
	elif is_level():
		draw_texture(marker,Vector2(-marker.get_width()/2,-marker.get_height()))
