extends AnimatedSprite2D

@export
var speed: float = 20
@export
var dots: PackedScene

var movement_dir: Vector2 = Vector2.RIGHT
var reached: bool = false

var current_marker: MapPlayerMarker


func _ready() -> void:
	# Sets powerup state to sprite
	if Thunder._current_player_state != null:
		sprite_frames = Thunder._current_player_state.animation_sprites
	else:
		printerr("[Map] Thunder._current_player_state is null")
	
	play("walk")


func _physics_process(delta: float) -> void:
	if !reached:
		move(delta)


func move(delta: float) -> void:
	if current_marker != null:
		# If it level player doll stops at marker
		if position == current_marker.position:
			reached = true # When done movement we can show start label and etc.
			
		if !reached:
			position = position.move_toward(current_marker.position, speed * delta)
		
		if !current_marker.is_level() && reached:
			current_marker = null
			reached = false
	else:
		position = position.move_toward(position + movement_dir * 2, speed * delta)
		# Puts Dots every 16 px on x or y 
		# (x % 16 == 0) == !(x % 16) cuz (0 = false, 1 = true)
		if abs(movement_dir.y) > 0.5:
			if !(int(position.y) % 16):
				put_dot()
		elif abs(movement_dir.x) > 0.5:
			if !(int(position.x) % 16):
				put_dot()


func put_dot() -> void:
	var dot = dots.instantiate() as Node2D
	dot.position = position + Vector2.UP * 8
	owner.add_child.call_deferred(dot)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("map_marker"):
		current_marker = area as MapPlayerMarker
		movement_dir = Vector2.RIGHT.rotated(area.angle).round()
		print(movement_dir)
