@tool
extends "res://engine/objects/fluid/swimming/control_resize_logic.gd"

@export var correct_particles_position: bool = true
@export_group("Physics")
@export var sucking_motion: Vector2 = Vector2(100, 50)

@onready var sinking_point: Vector2 = get_rect().position + Vector2(get_rect().size.x / 2, get_rect().size.y)

@onready var area_2d = $Area2D
@onready var bubbles: GPUParticles2D = $Bubbles

func _ready():
	super()
	if Engine.is_editor_hint(): return
	bubbles.process_material.duplicate()
	bubbles.process_material.emission_box_extents = Vector3(get_rect().size.x / 2, 1, 1)
	if correct_particles_position:
		bubbles.global_position = sinking_point
	bubbles.visibility_rect.position = get_rect().size / -2
	bubbles.visibility_rect.size = get_rect().size

func _physics_process(delta):
	if Engine.is_editor_hint(): return
		
	var player: Player = Thunder._current_player
	if !player: return
	if !area_2d.overlaps_body(player): return
	if !player.is_underwater: return
	var camera: Camera2D = Thunder._current_camera
	
	var _is_frog = player.suit.name == "frog"
	var pos := sinking_point
	var p_pos := player.global_position
	
	if !player.test_move(player.global_transform, Vector2.ZERO):
		if !(_is_frog && player.left_right != 0):
			player.global_position.x += delta * sucking_motion.x * signf(pos.x - p_pos.x)
			player.sync_position()
		if !(_is_frog && player.up_down != 0):
			player.global_position.y += delta * sucking_motion.y * signf(pos.y - p_pos.y)
			player.sync_position()
	if !camera: return
	camera.teleport()
		
