extends AnimatedSprite2D

@export var speed: float = 40
@export var faster_ex: int = 15
@export var dots: PackedScene
@export var x: PackedScene = preload("res://engine/scenes/map/prefabs/x.tscn")

var movement_dir: Vector2 = Vector2.RIGHT
var reached: bool = false

var current_marker: MapPlayerMarker

var has_put_dot: bool = false
var ex: int = 1

func _ready() -> void:
	# Sets powerup state to sprite
	if Thunder._current_player_state != null:
		sprite_frames = Thunder._current_player_state.animation_sprites
	else:
		printerr("[Map] Thunder._current_player_state is null")
	
	play("walk")


func _physics_process(delta: float) -> void:
	if !reached:
		for i in range(ex):
			move(delta)
	
	animate()
	
	if Input.is_action_just_pressed("m_jump") && !reached:
		ex = faster_ex


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
			put_dot()
		
		if reached:
			var marker = x.instantiate()
			marker.position = position - Vector2(0, 8)
			owner.add_child(marker)
	else:
		position = position.move_toward(position + movement_dir * 10, speed * delta)
		# Puts Dots every 16 px on x or y 
		# (x % 16 == 0) == !(x % 16) cuz (0 = false, 1 = true)
		if abs(movement_dir.y) > 0.5:
			if !(int(position.y) % 16) && !has_put_dot:
				has_put_dot = true
				put_dot()
			if int(position.y) % 16:
				has_put_dot = false
		elif abs(movement_dir.x) > 0.5:
			if !(int(position.x) % 16) && !has_put_dot:
				has_put_dot = true
				put_dot()
			if int(position.x) % 16:
				has_put_dot = false


func animate() -> void:
	if !reached:
		speed_scale = 3
	else:
		speed_scale = 1


func put_dot(pos: Vector2 = position) -> void:
	var dot = dots.instantiate() as Node2D
	dot.position = pos + Vector2.UP * 8
	owner.add_child.call_deferred(dot)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("map_marker"):
		#current_marker = area as MapPlayerMarker
		movement_dir = Vector2.RIGHT.rotated(area.rotation).round()
