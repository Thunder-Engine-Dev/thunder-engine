extends AnimatedSprite2D

@export var speed: float = 40
@export var faster_ex: int = 15
@export var dots: PackedScene
@export var x: PackedScene = preload("res://engine/scenes/map/prefabs/x.tscn")

var direction: float
var reached: bool = false

var current_marker: MapPlayerMarker

var ex: int = 1

@onready var map = Scenes.current_scene

func _ready() -> void:
	# Sets powerup state to sprite
	if Thunder._current_player_state != null:
		sprite_frames = Thunder._current_player_state.animation_sprites
	else:
		printerr("[Map] Thunder._current_player_state is null")
	
	play("walk")
	
	initial_pos()


func initial_pos() -> void:
	var first_space = Scenes.current_scene.get_first_marker_space()
	var first_marker = first_space.get_first_marker()
	current_marker = first_marker


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
		if global_position.is_equal_approx(current_marker.global_position):
			reached = true # When done movement we can show start label and etc.
			
		if !reached:
			position = position.move_toward(current_marker.position, speed * delta)
		
		if current_marker.is_level() && reached:
			current_marker = null
			reached = false

			map.to_level = current_marker.level
		
		if !current_marker.is_level() && reached:
			current_marker = current_marker.get_next_marker()
			reached = false


func animate() -> void:
	if !reached:
		speed_scale = 3
	else:
		speed_scale = 1


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("map_marker"):
		pass
		#current_marker = area as MapPlayerMarker
		
		#movement_dir = Vector2.RIGHT.rotated(area.rotation).round()
