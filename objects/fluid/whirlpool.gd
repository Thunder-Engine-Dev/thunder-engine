@tool
extends "res://engine/objects/fluid/swimming/control_resize_logic.gd"

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
	bubbles.global_position = sinking_point
	bubbles.visibility_rect.position = get_rect().size / -2
	bubbles.visibility_rect.size = get_rect().size

func _physics_process(delta):
	if Engine.is_editor_hint(): return
	#if !Thunder.view.is_getting_closer(self, -256):
	#	timer.paused = true
		
	var player: Player = Thunder._current_player
	if !player: return
	var camera: Camera2D = Thunder._current_camera
	
	if area_2d.overlaps_body(player) && player.is_underwater:
		if player.suit.name == "frog": return
		var pos = sinking_point
		var p_pos = player.global_position
		
		if !player.test_move(player.global_transform, Vector2.ZERO):
			player.global_position += delta * Vector2(
				sucking_motion.x * signf(pos.x - p_pos.x),
				sucking_motion.y * signf(pos.y - p_pos.y)
			)
		if !camera: return
		camera.teleport()
		
