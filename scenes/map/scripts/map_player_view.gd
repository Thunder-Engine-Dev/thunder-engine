extends Node2D

@export var speed: float = 40
@export var faster_ex: int = 15
@export var dots: PackedScene
@export var x: PackedScene = preload("res://engine/scenes/map/prefabs/x.tscn")

var direction: Vector2
var reached: bool = false

var current_marker: MapPlayerMarker

var ex: int = 1
var is_faster: bool = false
var fast_forwarding: bool = false

@onready var map = Scenes.current_scene
@onready var player: AnimatedSprite2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var bubbles = $Player/bubbles

func _ready() -> void:
	# Sets powerup state to sprite
	if Thunder._current_player_state != null:
		apply_player_skin(Thunder._current_player_state)
	else:
		printerr(&"[Map] Thunder._current_player_state is null")
	
	player.play(&"walk")
	
	await get_tree().physics_frame
	if !current_marker:
		initial_pos.call_deferred()


func initial_pos() -> void:
	var first_space = Scenes.current_scene.get_first_marker_space()
	var first_marker = first_space.get_first_marker()
	current_marker = first_marker


func _physics_process(delta: float) -> void:
	if !reached:
		for i in range(ex):
			move(delta)
	
	animate()
	
	if is_faster:
		ex = faster_ex
	
	if reached: return
	if Input.is_action_just_pressed(&"m_jump") || Input.is_action_just_pressed(&"m_attack"):
		is_faster = true
		map.player_fast_forwarded.emit()


func move(delta: float) -> void:
	if current_marker != null:
		# If it level player doll stops at marker
		if global_position.is_equal_approx(current_marker.global_position):
			global_position = current_marker.global_position
			reached = true # When done movement we can show start label and etc.
			
		if !reached:
			var old_pos: Vector2 = position
			position = position.move_toward(current_marker.position, speed * delta)
			direction = old_pos.direction_to(position)
			if !is_zero_approx(direction.x):
				player.flip_h = direction.x < 0.0
		
		if current_marker.is_level() && reached:
			map.to_level = current_marker.level
			
		
		if !current_marker.is_level() && reached:
			current_marker = current_marker.get_next_marker()
			reached = false


func animate() -> void:
	if player.animation == "swim":
		player.speed_scale = 1
		bubbles.emitting = true
		return
	if !reached:
		player.speed_scale = 3
		bubbles.emitting = false
	else:
		player.speed_scale = 1


func apply_player_skin(_suit) -> bool:
	#sprite.sprite_frames = _suit.animation_sprites
	#return true
	if SkinsManager.custom_sprite_frames.has(SkinsManager.current_skin.to_lower()):
		player.sprite_frames = SkinsManager.get_custom_sprite_frames(_suit.animation_sprites, SkinsManager.current_skin.to_lower(), _suit.name)
		return true
	player.sprite_frames = _suit.animation_sprites
	return false


func _on_hitbox_area_entered(area: Area2D) -> void:
	var par = area.get_parent()
	if par.is_in_group(&"map_dot"):
		par.set_meta(&"is_appearing", true)
		if fast_forwarding:
			par.visible = true
		else:
			await get_tree().create_timer(0.3 / ex, false).timeout
			if !is_instance_valid(par): return
			par.visible = true
			par.set_meta(&"is_appearing", false)
		return
